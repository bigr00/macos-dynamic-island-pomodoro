import Foundation

enum IslandState: Equatable {
    case collapsed
    case expanded

    var isExpanded: Bool {
        self == .expanded
    }
}