import SwiftUI
import AppKit

@main
struct QuickAccessEngineApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var popoverManager: PopoverManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory) // Hide from dock
        popoverManager = PopoverManager()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        popoverManager.engineManager.stopProcess(isAppExiting: true)
    }
}
