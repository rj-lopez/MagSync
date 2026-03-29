import Foundation
import SMCKit

// smc-write: Minimal setuid helper for writing MagSafe LED SMC key
// Usage: smc-write ACLC <hex_value>
// Allowed values: 00 (off), 01 (blink orange), 03 (green), 04 (solid orange)

let allowedKeys: Set<String> = ["ACLC"]
let allowedValues: Set<String> = ["00", "01", "03", "04"]

func usage() -> Never {
    fputs("Usage: smc-write ACLC <00|01|03|04>\n", stderr)
    exit(1)
}

guard CommandLine.arguments.count == 3 else { usage() }

let key = CommandLine.arguments[1]
let hexString = CommandLine.arguments[2]

guard allowedKeys.contains(key) else {
    fputs("Error: only key ACLC is allowed\n", stderr)
    exit(1)
}

guard allowedValues.contains(hexString) else {
    fputs("Error: value must be 00, 01, 03, or 04\n", stderr)
    exit(1)
}

guard let byte = UInt8(hexString, radix: 16) else {
    fputs("Error: invalid hex value\n", stderr)
    exit(1)
}

let smc = SMC()
do {
    try smc.open()
    try smc.writeKey(key, data: [byte])
    smc.close()
} catch {
    fputs("Error: \(error)\n", stderr)
    exit(1)
}
