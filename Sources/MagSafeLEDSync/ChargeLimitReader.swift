import Foundation

// MARK: - Charge Limit Reader

final class ChargeLimitReader {
    /// Reads the native macOS charge limit (80–100).
    /// Returns 100 if no limit is set.
    func readChargeLimit() -> Int {
        // Strategy 1: pmset -g battlimit (macOS 26.4+)
        if let limit = readFromPmset() {
            return limit
        }

        // Strategy 2: IORegistry AppleSmartBattery MaxCapacity
        if let limit = readFromIORegistry() {
            return limit
        }

        // Fallback: no limit detected
        return 100
    }

    /// Parse `pmset -g battlimit` output.
    /// Expected output when set: "Battery charge level limit: 80%"
    /// Expected output when not set: "No battery level limits set"
    private func readFromPmset() -> Int? {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g", "battlimit"]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return nil }

        // If no limit is set, pmset says so explicitly
        if output.contains("No battery level limits set") {
            return nil
        }

        // Parse "Battery charge level limit: 80%" or similar
        // Look for a number followed by %
        let pattern = /(\d+)%/
        if let match = output.firstMatch(of: pattern),
           let value = Int(match.1) {
            return value
        }

        // Also try just extracting a bare number on a "limit" line
        for line in output.split(separator: "\n") {
            if line.lowercased().contains("limit") {
                let digits = line.filter(\.isNumber)
                if let value = Int(digits), value >= 50, value <= 100 {
                    return value
                }
            }
        }

        return nil
    }

    /// Check if IORegistry AppleSmartBattery MaxCapacity is < 100,
    /// which would indicate a charge limit is active.
    private func readFromIORegistry() -> Int? {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("AppleSmartBattery")
        )
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }

        if let maxCap = IORegistryEntryCreateCFProperty(service, "MaxCapacity" as CFString, nil, 0)?.takeRetainedValue() as? Int {
            if maxCap < 100 && maxCap >= 50 {
                return maxCap
            }
        }
        return nil
    }
}
