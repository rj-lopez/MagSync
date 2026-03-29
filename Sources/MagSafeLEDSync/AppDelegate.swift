import AppKit
import SMCKit

// MARK: - App Delegate

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let batteryMonitor = BatteryMonitor()
    private let chargeLimitReader = ChargeLimitReader()
    private let smcClient = SMCWriteClient()
    private var statusBar: StatusBarController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        if !SMCWriteClient.isHelperInstalled() {
            let alert = NSAlert()
            alert.messageText = "MagSync Setup Required"
            alert.informativeText = "The smc-write helper is not installed. Please run the MagSync installer package to complete setup."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }

        statusBar = StatusBarController()

        statusBar.onToggle = { [weak self] enabled in
            self?.handleToggle(enabled)
        }

        statusBar.onQuit = { [weak self] in
            self?.handleQuit()
        }

        batteryMonitor.onChange = { [weak self] power in
            self?.handlePowerStateChange(power)
        }

        batteryMonitor.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        batteryMonitor.stop()
        smcClient.resetLED()
    }

    private func handlePowerStateChange(_ power: PowerState) {
        let chargeLimit = chargeLimitReader.readChargeLimit()
        let ledState = LEDController.determineLEDState(power: power, chargeLimit: chargeLimit)

        smcClient.writeLED(ledState)

        statusBar.update(
            power: power,
            chargeLimit: chargeLimit,
            ledState: ledState,
            isEnabled: smcClient.isEnabled
        )
    }

    private func handleToggle(_ enabled: Bool) {
        smcClient.isEnabled = enabled
        if !enabled {
            smcClient.resetLED()
        }
        // Re-evaluate with current state
        let power = batteryMonitor.readPowerState()
        let chargeLimit = chargeLimitReader.readChargeLimit()
        let ledState = LEDController.determineLEDState(power: power, chargeLimit: chargeLimit)

        if enabled {
            smcClient.writeLED(ledState)
        }

        statusBar.update(
            power: power,
            chargeLimit: chargeLimit,
            ledState: ledState,
            isEnabled: enabled
        )
    }

    private func handleQuit() {
        smcClient.resetLED()
        NSApplication.shared.terminate(nil)
    }
}
