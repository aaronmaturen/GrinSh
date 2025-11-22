import Foundation
import IOKit.ps

class SystemTool: Tool {
    let name = "system"
    let description = "System operations: volume, brightness, battery, wifi, disk space"

    func execute(action: String) -> ToolResult {
        let parts = action.components(separatedBy: ":")
        guard let command = parts.first else {
            return .failure("Invalid action format")
        }

        switch command {
        case "get_volume":
            return getVolume()
        case "set_volume":
            guard parts.count > 1, let level = Double(parts[1]) else {
                return .failure("Missing or invalid volume level (0.0-1.0)")
            }
            return setVolume(level: level)
        case "get_brightness":
            return getBrightness()
        case "set_brightness":
            guard parts.count > 1, let level = Double(parts[1]) else {
                return .failure("Missing or invalid brightness level (0.0-1.0)")
            }
            return setBrightness(level: level)
        case "battery":
            return getBatteryStatus()
        case "wifi":
            return getWifiStatus()
        case "disk_space":
            return getDiskSpace()
        case "sleep":
            return sleep()
        default:
            return .failure("Unknown command: \(command)")
        }
    }

    private func getVolume() -> ToolResult {
        let result = runCommand("osascript -e 'output volume of (get volume settings)'")
        if result.exitCode == 0 {
            if let volume = Int(result.output.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return .success("Volume: \(volume)%")
            }
        }
        return .failure("Could not get volume")
    }

    private func setVolume(level: Double) -> ToolResult {
        let percentage = Int(max(0, min(100, level * 100)))
        let result = runCommand("osascript -e 'set volume output volume \(percentage)'")

        if result.exitCode == 0 {
            return .success("Volume set to \(percentage)%")
        } else {
            return .failure("Could not set volume: \(result.output)")
        }
    }

    private func getBrightness() -> ToolResult {
        // Note: Getting brightness requires special permissions
        // Using a simple approach with display control
        let result = runCommand("brightness -l 2>/dev/null || echo 'Requires brightness utility'")
        return .success(result.output)
    }

    private func setBrightness(level: Double) -> ToolResult {
        let percentage = max(0.0, min(1.0, level))
        let result = runCommand("brightness \(percentage) 2>/dev/null || osascript -e 'tell application \"System Events\" to key code 144'")

        if result.exitCode == 0 {
            return .success("Brightness set to \(Int(percentage * 100))%")
        } else {
            return .failure("Could not set brightness (may require brightness utility or permissions)")
        }
    }

    private func getBatteryStatus() -> ToolResult {
        let result = runCommand("pmset -g batt")

        if result.exitCode == 0 {
            let lines = result.output.components(separatedBy: .newlines)
            var output = ""

            for line in lines {
                if line.contains("%") {
                    output += line.trimmingCharacters(in: .whitespaces) + "\n"
                }
            }

            return .success(output.isEmpty ? result.output : output)
        } else {
            return .failure("Could not get battery status")
        }
    }

    private func getWifiStatus() -> ToolResult {
        // Get current WiFi info using airport utility or networksetup
        let result = runCommand("/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I 2>/dev/null || networksetup -getairportnetwork en0")

        if result.exitCode == 0 {
            let output = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
            return .success(output.isEmpty ? "WiFi status unavailable" : output)
        } else {
            return .failure("Could not get WiFi status")
        }
    }

    private func getDiskSpace() -> ToolResult {
        let result = runCommand("df -h /")

        if result.exitCode == 0 {
            return .success(result.output)
        } else {
            return .failure("Could not get disk space")
        }
    }

    private func sleep() -> ToolResult {
        let result = runCommand("pmset sleepnow")

        if result.exitCode == 0 {
            return .success("Putting system to sleep")
        } else {
            return .failure("Could not put system to sleep (may require admin privileges)")
        }
    }
}
