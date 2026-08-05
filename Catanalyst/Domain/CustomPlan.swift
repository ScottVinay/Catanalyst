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

nonisolated enum PlannedConstructionKind: String, CaseIterable, Codable, Identifiable, Sendable {
    case road
    case settlement
    case city

    var id: Self { self }
    var displayName: String { rawValue.capitalized }

    var systemImage: String {
        switch self {
        case .road: "road.lanes"
        case .settlement: "house.fill"
        case .city: "building.2.fill"
        }
    }
}

nonisolated enum ConstructionLocation: Codable, Equatable, Sendable {
    case edge(BoardEdge)
    case vertex(BoardVertex)
}

nonisolated struct PlannedConstructionStep: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let kind: PlannedConstructionKind
    let location: ConstructionLocation

    init(
        id: UUID = UUID(),
        kind: PlannedConstructionKind,
        location: ConstructionLocation
    ) {
        self.id = id
        self.kind = kind
        self.location = location
    }
}

nonisolated struct CustomPlan: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var name: String
    var kind: CustomPlanKind
    var player: PlayerColor
    var cardCounts: [ResourceCard: Int]
    var constructionSteps: [PlannedConstructionStep]

    init(
        id: UUID = UUID(),
        name: String,
        kind: CustomPlanKind,
        player: PlayerColor,
        cardCounts: [ResourceCard: Int] = [:],
        constructionSteps: [PlannedConstructionStep] = []
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.player = player
        self.cardCounts = ResourceCardCounts.sanitized(cardCounts)
        self.constructionSteps = constructionSteps
    }

    var icon: String {
        kind == .cards ? "rectangle.stack.fill" : "hammer.fill"
    }

    static func belonging(to player: PlayerColor, in plans: [CustomPlan]) -> [CustomPlan] {
        plans.filter { $0.player == player }
    }

    static func visible(
        to player: PlayerColor,
        includesAllPlayers: Bool,
        in plans: [CustomPlan]
    ) -> [CustomPlan] {
        includesAllPlayers ? plans : belonging(to: player, in: plans)
    }

    static func nextDefaultName(
        for kind: CustomPlanKind,
        player: PlayerColor,
        in plans: [CustomPlan]
    ) -> String {
        let prefix = kind == .cards ? "Card plan" : "Con plan"
        let usedNames = Set(plans.lazy
            .filter { $0.player == player && $0.kind == kind }
            .map(\.name))
        var number = 1
        while usedNames.contains("\(prefix) \(number)") {
            number += 1
        }
        return "\(prefix) \(number)"
    }

    mutating func clearContents() {
        switch kind {
        case .cards: cardCounts.removeAll()
        case .constructions: constructionSteps.removeAll()
        }
    }

    mutating func addCard(_ resource: ResourceCard) {
        guard kind == .cards else { return }
        ResourceCardCounts.add(resource, to: &cardCounts)
    }

    mutating func removeCard(_ resource: ResourceCard) {
        guard kind == .cards else { return }
        ResourceCardCounts.remove(resource, from: &cardCounts)
    }

    mutating func removeLastConstructionStep() {
        guard kind == .constructions, !constructionSteps.isEmpty else { return }
        constructionSteps.removeLast()
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, kind, player, cardCounts, constructionSteps
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        kind = try container.decode(CustomPlanKind.self, forKey: .kind)
        player = try container.decode(PlayerColor.self, forKey: .player)
        cardCounts = try container.decodeIfPresent(
            [ResourceCard: Int].self,
            forKey: .cardCounts
        ) ?? [:]
        constructionSteps = try container.decodeIfPresent(
            [PlannedConstructionStep].self,
            forKey: .constructionSteps
        ) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(kind, forKey: .kind)
        try container.encode(player, forKey: .player)
        try container.encode(cardCounts, forKey: .cardCounts)
        try container.encode(constructionSteps, forKey: .constructionSteps)
    }
}

extension BoardState {
    func projected(
        adding steps: [PlannedConstructionStep],
        for player: PlayerColor
    ) -> BoardState {
        let projection = BoardState(snapshot: snapshot)
        for step in steps {
            switch step.location {
            case let .edge(edge):
                _ = projection.placeRoad(on: edge, for: player)
            case let .vertex(vertex):
                let building: Building = step.kind == .city ? .city : .settlement
                _ = projection.placeBuilding(building, at: vertex, for: player)
            }
        }
        return projection
    }
}
