import Foundation

nonisolated enum PlayerColor: String, CaseIterable, Codable, Identifiable, Sendable {
    case red
    case blue
    case white
    case orange
    case green
    case brown

    var id: Self { self }
    var displayName: String { rawValue.capitalized }

    var placeholderIndex: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}
