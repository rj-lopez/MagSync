import Foundation
import SMCKit

// MARK: - LED Controller

/// Pure state machine that determines the correct ACLC value
/// based on current power state and charge limit.
final class LEDController {
    /// Temperature threshold for heat protection detection (°C)
    private static let heatThreshold: Double = 40.0

    /// Determine the correct LED state given current conditions.
    ///
    /// Logic:
    /// 1. Not plugged in → off
    /// 2. Heat protection (AC connected, not charging, below limit, hot) → blink orange
    /// 3. Battery level >= charge limit → green
    /// 4. Otherwise → solid orange (charging toward limit)
    static func determineLEDState(power: PowerState, chargeLimit: Int) -> ACLCValue {
        // Not plugged in: LED should be off
        guard power.isPluggedIn else {
            return .off
        }

        // Heat protection detection:
        // AC is connected but not charging, battery is below limit.
        // This means the system has inhibited charging.
        if !power.isCharging && power.batteryLevel < chargeLimit {
            // If well below limit (>2% gap), charging is inhibited
            if power.batteryLevel < chargeLimit - 2 {
                if power.batteryTemp > heatThreshold {
                    return .blinkOrange
                }
                // Not hot but charging inhibited — still flag it
                return .blinkOrange
            }
            // Within 2% of limit and not charging → effectively reached limit
            return .green
        }

        // At or above the charge limit → green (full relative to limit)
        if power.batteryLevel >= chargeLimit {
            return .green
        }

        // Charging toward the limit → solid orange
        return .solidOrange
    }
}
