import Foundation

// MARK: - ACLC (MagSafe LED Control)

public enum ACLCValue: UInt8, Sendable, CustomStringConvertible {
    case off = 0x00
    case blinkOrange = 0x01
    case green = 0x03
    case solidOrange = 0x04

    public var description: String {
        switch self {
        case .off: return "Off"
        case .blinkOrange: return "Blinking Orange (heat protection)"
        case .green: return "Green (limit reached)"
        case .solidOrange: return "Orange (charging)"
        }
    }
}

// MARK: - SMC Key Names

public enum SMCKeyName {
    /// MagSafe LED color control — write 1 byte
    public static let aclc = "ACLC"

    /// Battery temperature sensor 0 — returns flt/sp78 value
    public static let batteryTemp = "TB0T"

    /// Platform controller temperature — fallback temp sensor
    public static let platformTemp = "Ts0P"
}
