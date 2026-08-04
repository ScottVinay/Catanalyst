import Foundation

nonisolated enum CustomPlanKind: String, CaseIterable, Codable, Identifiable, Sendable {
    case cards
    case constructions

    var id: Self { self }
    var displayName: String { rawValue.capitalized }
}

nonisolated enum ResourceCard: String, CaseIterable, Codable, Identifiable, Sendable {
    case brick
    case wood
    case hay
    case sheep
    case ore

    var id: Self { self }
    var displayName: String { rawValue.capitalized }

    var systemImage: String {
        switch self {
        case .brick: "rectangle.split.3x1.fill"
        case .wood: "tree.fill"
        case .hay: "leaf.fill"
        case .sheep: "cloud.fill"
        case .ore: "mountain.2.fill"
        }
    }
}

nonisolated struct CustomPlan: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var name: String
    var kind: CustomPlanKind
    var player: PlayerColor
    var cardCounts: [ResourceCard: Int]

    init(
        id: UUID = UUID(),
        name: String,
        kind: CustomPlanKind,
        player: PlayerColor,
        cardCounts: [ResourceCard: Int] = [:]
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.player = player
        self.cardCounts = cardCounts.filter { $0.value > 0 }
    }

    var icon: String {
        kind == .cards ? "rectangle.stack.fill" : "hammer.fill"
    }
}
