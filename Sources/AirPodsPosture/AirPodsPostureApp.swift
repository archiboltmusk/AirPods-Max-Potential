import SwiftUI
import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    static weak var shared: AppDelegate?
    static var isExplicitQuitFromMenuBar: Bool = false
    var openDashboardHandler: (() -> Void)?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        applyPresentationMode()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeKey(_:)),
            name: NSWindow.didBecomeKeyNotification,
            object: nil
        )
        
        if !UserDefaults.standard.bool(forKey: "hasCompletedADAOnboarding") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.openDashboard()
            }
        }
    }
    
    func applyPresentationMode() {
        let mode = UserDefaults.standard.string(forKey: "appPresentationMode") ?? "hideWhenClosed"
        if mode == "menuBarOnly" {
            NSApp.setActivationPolicy(.accessory)
        } else {
            NSApp.setActivationPolicy(.regular)
        }
    }
    
    @objc func windowDidBecomeKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, !(window is NSPanel) else { return }
        if window.delegate !== self {
            window.delegate = self
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        guard let closingWindow = notification.object as? NSWindow, !(closingWindow is NSPanel) else { return }
        let mode = UserDefaults.standard.string(forKey: "appPresentationMode") ?? "hideWhenClosed"
        if mode == "hideWhenClosed" {
            DispatchQueue.main.async {
                let remaining = NSApp.windows.filter { !($0 is NSPanel) && $0.isVisible && $0 != closingWindow }
                if remaining.isEmpty {
                    NSApp.setActivationPolicy(.accessory)
                }
            }
        }
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if AppDelegate.isExplicitQuitFromMenuBar {
            return .terminateNow
        }
        
        let mode = UserDefaults.standard.string(forKey: "appPresentationMode") ?? "hideWhenClosed"
        if mode != "alwaysShowDock" {
            closeAllWindowsAndHideToMenuBar()
            return .terminateCancel
        }
        
        return .terminateNow
    }
    
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu()
        
        let hideItem = NSMenuItem(title: "Hide to Menu Bar (Exit Dock)", action: #selector(dockHideAction), keyEquivalent: "")
        hideItem.target = self
        menu.addItem(hideItem)
        
        let openItem = NSMenuItem(title: "Open Dashboard...", action: #selector(dockOpenAction), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit AirPods Posture Completely", action: #selector(dockQuitAction), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)
        
        return menu
    }
    
    @objc func dockHideAction() {
        closeAllWindowsAndHideToMenuBar()
    }
    
    @objc func dockOpenAction() {
        openDashboard()
    }
    
    @objc func dockQuitAction() {
        AppDelegate.isExplicitQuitFromMenuBar = true
        NSApp.terminate(nil)
    }
    
    func closeAllWindowsAndHideToMenuBar() {
        for window in NSApp.windows where !(window is NSPanel) {
            window.orderOut(nil)
        }
        NSApp.setActivationPolicy(.accessory)
    }
    
    func openDashboard(fallback: (() -> Void)? = nil) {
        let mode = UserDefaults.standard.string(forKey: "appPresentationMode") ?? "hideWhenClosed"
        if mode != "menuBarOnly" {
            NSApp.setActivationPolicy(.regular)
        }
        NSApp.activate(ignoringOtherApps: true)
        
        if let existing = NSApp.windows.first(where: { !($0 is NSPanel) && $0.canBecomeMain }) {
            existing.makeKeyAndOrderFront(nil)
        } else {
            fallback?() ?? openDashboardHandler?()
        }
    }
}

@main
struct AirPodsPostureApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow

    init() {
        // Strictly disable automatic window tabbing
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    var body: some Scene {
        Window("AirPodsIQ", id: "main-dashboard") {
            ContentView()
                .onAppear {
                    appDelegate.openDashboardHandler = {
                        activateMainWindow()
                    }
                }
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1160, height: 780)
        .commands {
            // Disable ⌘N / ⌘T so macOS never spawns extra windows or tabs
            CommandGroup(replacing: .newItem) {}
            
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    activateMainWindow()
                    AppUpdateManager.shared.checkForUpdates()
                }
                
                Button("Hide to Menu Bar (Exit Dock)") {
                    appDelegate.closeAllWindowsAndHideToMenuBar()
                }
                .keyboardShortcut("w", modifiers: [.command])
            }
        }

        MenuBarExtra {
            MenuBarView(motion: MotionManager.shared) {
                activateMainWindow()
            }
            .onAppear {
                appDelegate.openDashboardHandler = {
                    activateMainWindow()
                }
            }
        } label: {
            ThrottledMenuBarLabel()
        }
        .menuBarExtraStyle(.window)
    }
    
    private func activateMainWindow() {
        appDelegate.openDashboard(fallback: {
            openWindow(id: "main-dashboard")
        })
    }
}
