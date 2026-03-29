import Foundation
import IOKit.ps

// MARK: - Power State

struct PowerState: Equatable, Sendable {
    let batteryLevel: Int       // 0–100
    let isPluggedIn: Bool       // AC adapter connected
    let isCharging: Bool        // Actively charging
    let batteryTemp: Double     // °C (from IORegistry)

    static let unknown = PowerState(batteryLevel: 0, isPluggedIn: false, isCharging: false, batteryTemp: 25.0)
}

// MARK: - Battery Monitor

final class BatteryMonitor {
    private var runLoopSource: CFRunLoopSource?
    var onChange: ((PowerState) -> Void)?

    func start() {
        let context = Unmanaged.passUnretained(self).toOpaque()
        runLoopSource = IOPSNotificationCreateRunLoopSource({ context in
            guard let context else { return }
            let monitor = Unmanaged<BatteryMonitor>.fromOpaque(context).takeUnretainedValue()
            let state = monitor.readPowerState()
            monitor.onChange?(state)
        }, context).takeRetainedValue()

        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)

        // Fire initial read
        let state = readPowerState()
        onChange?(state)
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
            runLoopSource = nil
        }
    }

    func readPowerState() -> PowerState {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [Any],
              let first = sources.first
        else {
            return .unknown
        }

        guard let desc = IOPSGetPowerSourceDescription(snapshot, first as CFTypeRef)?.takeUnretainedValue() as? [String: Any] else {
            return .unknown
        }

        let batteryLevel = desc[kIOPSCurrentCapacityKey] as? Int ?? 0
        let isCharging = desc[kIOPSIsChargingKey] as? Bool ?? false
        let powerSourceState = desc[kIOPSPowerSourceStateKey] as? String ?? ""
        let isPluggedIn = powerSourceState == kIOPSACPowerValue

        let batteryTemp = readBatteryTemperature()

        return PowerState(
            batteryLevel: batteryLevel,
            isPluggedIn: isPluggedIn,
            isCharging: isCharging,
            batteryTemp: batteryTemp
        )
    }

    /// Read battery temperature from IORegistry (AppleSmartBattery/Temperature)
    /// Value is in centi-degrees: 3037 = 30.37°C
    private func readBatteryTemperature() -> Double {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("AppleSmartBattery")
        )
        guard service != 0 else { return 25.0 }
        defer { IOObjectRelease(service) }

        if let temp = IORegistryEntryCreateCFProperty(service, "Temperature" as CFString, nil, 0)?.takeRetainedValue() as? Int {
            return Double(temp) / 100.0
        }
        return 25.0
    }
}
