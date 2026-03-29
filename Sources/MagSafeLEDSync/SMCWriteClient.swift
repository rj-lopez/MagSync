import Foundation
import SMCKit

// MARK: - SMC Write Client

/// Invokes the setuid `smc-write` helper to write ACLC values.
/// The helper must be installed at /usr/local/bin/smc-write with setuid root.
final class SMCWriteClient {
    private static let helperPath = "/usr/local/bin/smc-write"
    private var lastWrittenValue: ACLCValue?

    /// Whether LED sync is enabled. When disabled, no writes are sent.
    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "LEDSyncEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "LEDSyncEnabled") }
    }

    init() {
        // Default to enabled on first launch
        if UserDefaults.standard.object(forKey: "LEDSyncEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "LEDSyncEnabled")
        }
    }

    /// Returns true if smc-write is installed at the expected path with the setuid bit set.
    static func isHelperInstalled() -> Bool {
        guard FileManager.default.fileExists(atPath: helperPath) else { return false }
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: helperPath),
              let perms = attrs[.posixPermissions] as? Int else { return false }
        return (perms & 0o4000) != 0
    }

    /// Write an ACLC value if it differs from the last written value.
    /// Skips the write if disabled or if the value hasn't changed.
    func writeLED(_ value: ACLCValue) {
        guard isEnabled else { return }
        guard value != lastWrittenValue else { return }

        let hexString = String(format: "%02x", value.rawValue)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: Self.helperPath)
        process.arguments = [SMCKeyName.aclc, hexString]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                lastWrittenValue = value
            } else {
                fputs("smc-write exited with status \(process.terminationStatus)\n", stderr)
            }
        } catch {
            fputs("Failed to run smc-write: \(error)\n", stderr)
        }
    }

    /// Reset LED to off (let system control) and clear cached state.
    func resetLED() {
        lastWrittenValue = nil
        let process = Process()
        process.executableURL = URL(fileURLWithPath: Self.helperPath)
        process.arguments = [SMCKeyName.aclc, "00"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
    }
}
