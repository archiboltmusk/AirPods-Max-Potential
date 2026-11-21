import SwiftUI

/// Elegant Apple HIG Software Update Card View.
/// Supports 1-click update checks, download progress, changelog inspection, and relaunch.
public struct SoftwareUpdateCardView: View {
    @ObservedObject var updater = AppUpdateManager.shared
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header bar
            HStack(spacing: 12) {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 34, height: 34)
                    .background(Color.blue.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Software Update")
                            .font(.system(size: 14, weight: .semibold))
                        Text("v\(updater.currentVersion)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.primary.opacity(0.08))
                            .clipShape(Capsule())
                    }
                    Text(updater.updateStatusMessage)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Check for Updates Button
                Button(action: {
                    updater.checkForUpdates()
                }) {
                    HStack(spacing: 5) {
                        if updater.isChecking {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(updater.isChecking ? "Checking..." : "Check for Updates")
                    }
                    .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(updater.isChecking || updater.isDownloading)
            }
            
            // If an update is ready to install and relaunch
            if updater.isReadyToRelaunch {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Update Ready to Install!")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.green)
                        Text("AirPods Max Potential will restart to apply the latest release.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        updater.relaunchAndInstall()
                    }) {
                        Label("Relaunch & Update", systemImage: "arrow.clockwise.circle.fill")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(12)
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            // If a new update is available
            else if updater.isUpdateAvailable {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(updater.releaseTitle)
                                .font(.system(size: 13, weight: .bold))
                            if updater.downloadSizeMb > 0 {
                                Text("Download Size: \(String(format: "%.1f MB", updater.downloadSizeMb))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Button(action: {
                                updater.openReleasePage()
                            }) {
                                Label("View Notes", systemImage: "safari")
                                    .font(.system(size: 11))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Button(action: {
                                updater.downloadAndInstallUpdate()
                            }) {
                                HStack(spacing: 4) {
                                    if updater.isDownloading {
                                        ProgressView()
                                            .controlSize(.small)
                                    } else {
                                        Image(systemName: "arrow.down.circle.fill")
                                    }
                                    Text(updater.isDownloading ? "Downloading..." : "Update Now")
                                }
                                .font(.system(size: 11, weight: .bold))
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .disabled(updater.isDownloading)
                        }
                    }
                    
                    if updater.isDownloading {
                        ProgressView(value: updater.downloadProgress, total: 1.0)
                            .tint(.blue)
                    }
                    
                    if !updater.releaseNotes.isEmpty {
                        ScrollView {
                            Text(updater.releaseNotes)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                        }
                        .frame(height: 80)
                        .background(Color.primary.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                .padding(12)
                .background(Color.blue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            
            // Error banner if any
            if let error = updater.updateErrorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            
            Divider().opacity(0.4)
            
            // Auto-check preference toggle & last checked timestamp
            HStack {
                Toggle("Check for updates automatically on launch", isOn: $updater.autoCheckOnLaunch)
                    .toggleStyle(.switch)
                    .font(.caption)
                
                Spacer()
                
                if let last = updater.lastCheckedDate {
                    Text("Last checked: \(formattedDate(last))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appleGlass(cornerRadius: 16, opacity: 0.35)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
