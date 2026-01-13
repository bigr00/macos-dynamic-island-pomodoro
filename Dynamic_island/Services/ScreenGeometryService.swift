import AppKit

@MainActor
final class ScreenGeometryService {
    static let shared = ScreenGeometryService()

    let collapsedWidth: CGFloat = 320
    let collapsedHeight: CGFloat = 36
    let expandedWidth: CGFloat = 340
    let expandedHeight: CGFloat = 220
    let expandedHistoryHeight: CGFloat = 470

    private var cachedNotchedScreen: NSScreen?


    private init() {
        self.cachedNotchedScreen = findNotchedScreen()
    }

    private func findNotchedScreen() -> NSScreen? {
        if #available(macOS 12.0, *) {
            for screen in NSScreen.screens {
                if screen.auxiliaryTopLeftArea != nil && screen.auxiliaryTopRightArea != nil {
                    return screen
                }
            }
        }
        for screen in NSScreen.screens {
            if screen.localizedName.contains("Built-in") {
                return screen
            }
        }
        return nil
    }

    var notchedScreen: NSScreen? {
        if let cached = cachedNotchedScreen {
            return cached
        }
        let found = findNotchedScreen()
        cachedNotchedScreen = found
        return found
    }

    var hasNotchedScreen: Bool {
        notchedScreen != nil
    }

    func collapsedFrame() -> NSRect {
        guard let screen = notchedScreen else {
            return NSRect(x: -1000, y: -1000, width: collapsedWidth, height: collapsedHeight)
        }

        let screenFrame = screen.frame

        let x = screenFrame.origin.x + (screenFrame.width - collapsedWidth) / 2

        let y = screenFrame.maxY - collapsedHeight

        return NSRect(x: x, y: y, width: collapsedWidth, height: collapsedHeight)
    }

    func expandedFrame() -> NSRect {
        guard let screen = notchedScreen else {
            return NSRect(x: -1000, y: -1000, width: expandedWidth, height: expandedHeight)
        }

        let screenFrame = screen.frame

        let x = screenFrame.origin.x + (screenFrame.width - expandedWidth) / 2

        let y = screenFrame.maxY - expandedHeight

        return NSRect(x: x, y: y, width: expandedWidth, height: expandedHeight)
    }

    func expandedWithHistoryFrame() -> NSRect {
        guard let screen = notchedScreen else {
            return NSRect(x: -1000, y: -1000, width: expandedWidth, height: expandedHistoryHeight)
        }

        let screenFrame = screen.frame

        let x = screenFrame.origin.x + (screenFrame.width - expandedWidth) / 2

        let y = screenFrame.maxY - expandedHistoryHeight

        return NSRect(x: x, y: y, width: expandedWidth, height: expandedHistoryHeight)
    }
}