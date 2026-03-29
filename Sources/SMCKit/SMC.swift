import Foundation
import IOKit

// MARK: - SMC Data Structures

/// Matches Apple's SMCKeyInfoData from PowerManagement open source
private struct SMCKeyInfoData {
    var dataSize: UInt32 = 0
    var dataType: UInt32 = 0
    var dataAttributes: UInt8 = 0
}

/// Matches Apple's SMCParamStruct from PowerManagement open source
private struct SMCParamStruct {
    var key: UInt32 = 0
    var vers: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0, 0, 0, 0, 0, 0)
    var plimitData: (UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16) = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    var keyInfo: SMCKeyInfoData = SMCKeyInfoData()
    var padding: UInt16 = 0
    var result: UInt8 = 0
    var status: UInt8 = 0
    var data8: UInt8 = 0
    var data32: UInt32 = 0
    var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) =
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
         0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
}

// MARK: - SMC Selectors

private enum SMCSelector: UInt8 {
    case kSMCHandleYPCEvent = 2
    case kSMCReadKey = 5
    case kSMCWriteKey = 6
    case kSMCGetKeyFromIndex = 8
    case kSMCGetKeyInfo = 9
}

// MARK: - SMC Errors

public enum SMCError: Error, CustomStringConvertible {
    case driverNotFound
    case failedToOpen
    case keyNotFound(String)
    case readFailed(String, kern_return_t)
    case writeFailed(String, kern_return_t)
    case keyInfoFailed(String)

    public var description: String {
        switch self {
        case .driverNotFound:
            return "AppleSMC driver not found"
        case .failedToOpen:
            return "Failed to open connection to AppleSMC"
        case .keyNotFound(let key):
            return "SMC key not found: \(key)"
        case .readFailed(let key, let code):
            return "Failed to read SMC key \(key): kern_return \(code)"
        case .writeFailed(let key, let code):
            return "Failed to write SMC key \(key): kern_return \(code)"
        case .keyInfoFailed(let key):
            return "Failed to get key info for: \(key)"
        }
    }
}

// MARK: - FourCharCode Helper

public func fourCharCode(_ value: String) -> UInt32 {
    var result: UInt32 = 0
    for char in value.utf8.prefix(4) {
        result = (result << 8) | UInt32(char)
    }
    return result
}

// MARK: - SMC Public API

public final class SMC: @unchecked Sendable {
    private var connection: io_connect_t = 0
    private var isOpen = false

    public init() {}

    public func open() throws {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("AppleSMC")
        )
        guard service != 0 else {
            throw SMCError.driverNotFound
        }
        defer { IOObjectRelease(service) }

        let result = IOServiceOpen(service, mach_task_self_, 0, &connection)
        guard result == kIOReturnSuccess else {
            throw SMCError.failedToOpen
        }
        isOpen = true
    }

    public func close() {
        if isOpen {
            IOServiceClose(connection)
            isOpen = false
        }
    }

    deinit {
        close()
    }

    public func readKey(_ key: String) throws -> [UInt8] {
        let keyCode = fourCharCode(key)
        let info = try getKeyInfo(keyCode, keyName: key)

        var input = SMCParamStruct()
        input.key = keyCode
        input.keyInfo.dataSize = info.dataSize
        input.data8 = SMCSelector.kSMCReadKey.rawValue

        let output = try callDriver(input, keyName: key, isWrite: false)

        var bytes: [UInt8] = []
        let count = Int(info.dataSize)
        withUnsafeBytes(of: output.bytes) { buffer in
            for i in 0..<min(count, buffer.count) {
                bytes.append(buffer[i])
            }
        }
        return bytes
    }

    public func writeKey(_ key: String, data: [UInt8]) throws {
        let keyCode = fourCharCode(key)
        let info = try getKeyInfo(keyCode, keyName: key)

        var input = SMCParamStruct()
        input.key = keyCode
        input.keyInfo.dataSize = info.dataSize
        input.data8 = SMCSelector.kSMCWriteKey.rawValue

        withUnsafeMutableBytes(of: &input.bytes) { buffer in
            for i in 0..<min(data.count, buffer.count) {
                buffer[i] = data[i]
            }
        }

        _ = try callDriver(input, keyName: key, isWrite: true)
    }

    // MARK: - Private

    private func getKeyInfo(_ keyCode: UInt32, keyName: String) throws -> SMCKeyInfoData {
        var input = SMCParamStruct()
        input.key = keyCode
        input.data8 = SMCSelector.kSMCGetKeyInfo.rawValue

        let output = try callDriver(input, keyName: keyName, isWrite: false)
        guard output.keyInfo.dataSize > 0 else {
            throw SMCError.keyNotFound(keyName)
        }
        return output.keyInfo
    }

    private func callDriver(_ input: SMCParamStruct, keyName: String, isWrite: Bool) throws -> SMCParamStruct {
        var inputStruct = input
        var outputStruct = SMCParamStruct()
        let inputSize = MemoryLayout<SMCParamStruct>.stride
        var outputSize = MemoryLayout<SMCParamStruct>.stride

        let result = IOConnectCallStructMethod(
            connection,
            UInt32(SMCSelector.kSMCHandleYPCEvent.rawValue),
            &inputStruct,
            inputSize,
            &outputStruct,
            &outputSize
        )

        guard result == kIOReturnSuccess else {
            if isWrite {
                throw SMCError.writeFailed(keyName, result)
            } else {
                throw SMCError.readFailed(keyName, result)
            }
        }
        return outputStruct
    }
}
