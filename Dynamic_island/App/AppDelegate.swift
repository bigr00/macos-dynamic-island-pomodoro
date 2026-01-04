import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var dynamicIslandWindow: DynamicIslandWindow?
    private var viewModel: PomodoroViewModel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupDynamicIslandWindow()
    }

    private func setupDynamicIslandWindow() {
        let viewModel = PomodoroViewModel()
        self.viewModel = viewModel

        let contentView = DynamicIslandView(viewModel: viewModel)

        let geometryService = ScreenGeometryService.shared
        let initialFrame = geometryService.collapsedFrame()

        let window = DynamicIslandWindow(
            contentRect: initialFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.viewModel = viewModel

        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false

        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))

        window.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle,
            .fullScreenAuxiliary
        ]

        window.isMovableByWindowBackground = false
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true

        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden

        let trackingView = HoverTrackingView(viewModel: viewModel)
        let hosting = NSHostingView(rootView: contentView)
        hosting.frame = trackingView.bounds
        hosting.autoresizingMask = [.width, .height]
        trackingView.addSubview(hosting)
        window.contentView = trackingView

        window.orderFrontRegardless()

        self.dynamicIslandWindow = window

        viewModel.onStateChange = { [weak self] isExpanded in
            self?.updateWindowFrame(expanded: isExpanded)
        }
    }

    private func updateWindowFrame(expanded: Bool) {
        guard let window = dynamicIslandWindow else { return }

        let geometryService = ScreenGeometryService.shared
        let newFrame = expanded ? geometryService.expandedFrame() : geometryService.collapsedFrame()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.35
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(newFrame, display: true)
        }
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

class DynamicIslandWindow: NSWindow {
    var viewModel: PomodoroViewModel?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

class HoverTrackingView: NSView {
    private weak var viewModel: PomodoroViewModel?
    private var trackingArea: NSTrackingArea?

    init(viewModel: PomodoroViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        updateTrackingArea()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        updateTrackingArea()
    }

    private func updateTrackingArea() {
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }

        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea!)
    }

    override func mouseEntered(with event: NSEvent) {
        Task { @MainActor in
            viewModel?.onHover(true)
        }
    }

    override func mouseExited(with event: NSEvent) {
        Task { @MainActor in
            viewModel?.onHover(false)
        }
    }
}
