import Testing
@testable import MagSafeLEDSync
@testable import SMCKit

@Suite("LED Controller Logic")
struct LEDControllerTests {

    @Test("Not plugged in → LED off")
    func notPluggedIn() {
        let power = PowerState(batteryLevel: 50, isPluggedIn: false, isCharging: false, batteryTemp: 30.0)
        let result = LEDController.determineLEDState(power: power, chargeLimit: 80)
        #expect(result == .off)
    }

    @Test("Plugged in, charging below limit → solid orange")
    func chargingBelowLimit() {
        let power = PowerState(batteryLevel: 60, isPluggedIn: true, isCharging: true, batteryTemp: 30.0)
        let result = LEDController.determineLEDState(power: power, chargeLimit: 80)
        #expect(result == .solidOrange)
    }

    @Test("Plugged in, at charge limit → green")
    func atChargeLimit() {
        let power = PowerState(batteryLevel: 80, isPluggedIn: true, isCharging: false, batteryTemp: 30.0)
        let result = LEDController.determineLEDState(power: power, chargeLimit: 80)
        #expect(result == .green)
    }

    @Test("Plugged in, above charge limit → green")
    func aboveChargeLimit() {
        let power = PowerState(batteryLevel: 85, isPluggedIn: true, isCharging: false, batteryTemp: 30.0)
        let result = LEDController.determineLEDState(power: power, chargeLimit: 80)
        #expect(result == .green)
    }

    @Test("Plugged in, no limit set, fully charged → green")
    func noLimitFullyCharged() {
        let power = PowerState(batteryLevel: 100, isPluggedIn: true, isCharging: false, batteryTemp: 30.0)
        let result = LEDController.determineLEDState(power: power, chargeLimit: 100)
        #expect(result == .green)
    }

    @Test("Plugged in, no limit set, charging → solid orange")
    func noLimitCharging() {
        let power = PowerState(batteryLevel: 75, isPluggedIn: true, isCharging: true, batteryTemp: 30.0)
        let result = LEDController.determineLEDState(power: power, chargeLimit: 100)
        #expect(result == .solidOrange)
    }

    @Test("Heat protection: not charging, below limit, hot → blink orange")
    func heatProtectionHot() {
        let power = PowerState(batteryLevel: 60, isPluggedIn: true, isCharging: false, batteryTemp: 42.0)
        let result = LEDController.determineLEDState(power: power, chargeLimit: 80)
        #expect(result == .blinkOrange)
    }

    @Test("Heat protection: not charging, well below limit, normal temp → blink orange")
    func heatProtectionInhibited() {
        let power = PowerState(batteryLevel: 70, isPluggedIn: true, isCharging: false, batteryTemp: 30.0)
        let result = LEDController.determineLEDState(power: power, chargeLimit: 80)
        #expect(result == .blinkOrange)
    }

    @Test("Plugged in, not charging, just below limit (within tolerance) → green")
    func justBelowLimitTolerance() {
        let power = PowerState(batteryLevel: 79, isPluggedIn: true, isCharging: false, batteryTemp: 30.0)
        let result = LEDController.determineLEDState(power: power, chargeLimit: 80)
        #expect(result == .green)
    }
}
