import AppKit
import SMCKit

// MARK: - Status Bar Controller

@MainActor
final class StatusBarController {
    private let statusItem: NSStatusItem
    private let menu = NSMenu()

    // Menu items that get updated dynamically
    private let batteryItem = NSMenuItem(title: "Battery: ---%", action: nil, keyEquivalent: "")
    private let chargeLimitItem = NSMenuItem(title: "Charge Limit: ---", action: nil, keyEquivalent: "")
    private let ledStateItem = NSMenuItem(title: "LED: ---", action: nil, keyEquivalent: "")
    private let toggleItem = NSMenuItem(title: "LED Sync Enabled", action: nil, keyEquivalent: "")

    var onToggle: ((Bool) -> Void)?
    var onQuit: (() -> Void)?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "bolt.batteryblock", accessibilityDescription: "MagSafe LED Sync") {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "LED"
            }
        }

        // Info items (non-interactive)
        batteryItem.isEnabled = false
        chargeLimitItem.isEnabled = false
        ledStateItem.isEnabled = false

        menu.addItem(batteryItem)
        menu.addItem(chargeLimitItem)
        menu.addItem(ledStateItem)
        menu.addItem(.separator())

        // Toggle
        toggleItem.target = self
        toggleItem.action = #selector(toggleClicked)
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit MagSafe LED Sync", action: #selector(quitClicked), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    func update(power: PowerState, chargeLimit: Int, ledState: ACLCValue, isEnabled: Bool) {
        batteryItem.title = "Battery: \(power.batteryLevel)%"
        if chargeLimit < 100 {
            chargeLimitItem.title = "Charge Limit: \(chargeLimit)%"
        } else {
            chargeLimitItem.title = "Charge Limit: None"
        }
        ledStateItem.title = "LED: \(ledState.description)"
        toggleItem.state = isEnabled ? .on : .off
    }

    @objc private func toggleClicked() {
        let newState = toggleItem.state != .on
        onToggle?(newState)
    }

    @objc private func quitClicked() {
        onQuit?()
    }
}
