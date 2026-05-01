import SwiftUI
import AppKit
import Combine

@MainActor
class PopoverManager: NSObject {
    var popover: NSPopover!
    var statusItem: NSStatusItem!
    let engineManager = QuickAccessEngineManager()
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        setupPopover()
        setupStatusItem()
        setupObservers()
    }
    
    func setupPopover() {
        let chatView = ChatView(processManager: engineManager)
        popover = NSPopover()
        popover.contentSize = NSSize(width: 650, height: 480)
        popover.behavior = .transient // Dismiss on click away
        popover.contentViewController = NSHostingController(rootView: chatView)
    }
    
    func setupObservers() {
        engineManager.$hasUnreadMessages
            .sink { [weak self] hasUnread in
                Task { @MainActor in
                    self?.updateIcon(hasUnread: hasUnread)
                }
            }
            .store(in: &cancellables)
    }
    
    func updateIcon(hasUnread: Bool) {
        if hasUnread && !popover.isShown {
            statusItem.button?.image = NSImage(systemSymbolName: "engine.combustion.badge.exclamationmark", accessibilityDescription: "Quick Access Engine")
        } else {
            statusItem.button?.image = menuBarIcon
        }
    }
    
    private var menuBarIcon: NSImage? {
        guard let image = Bundle.module.image(forResource: "MenuBarIcon") else {
            return NSImage(systemSymbolName: "engine.combustion", accessibilityDescription: "Quick Access Engine")
        }
        image.isTemplate = true
        image.size = NSSize(width: 18, height: 18)
        return image
    }
    
    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = menuBarIcon
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    @objc func statusItemClicked(_ sender: Any?) {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp || (event.type == .leftMouseUp && event.modifierFlags.contains(.control)) {
            showContextMenu()
        } else {
            togglePopover()
        }
    }
    
    func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit Quick Access Engine", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }
    
    @objc func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }
    
    func showPopover() {
        if let button = statusItem.button {
            engineManager.hasUnreadMessages = false
            updateIcon(hasUnread: false)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func closePopover() {
        popover.performClose(nil)
    }
}
