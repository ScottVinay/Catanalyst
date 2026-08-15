import Foundation
import Observation

nonisolated enum Terrain: String, CaseIterable, Codable, Identifiable, Sendable {
    case brick
    case ore
    case wheat
    case lumber
    case wool
    case desert
    case ocean

    var id: Self { self }

    var displayName: String {
        rawValue.capitalized
    }

    var systemImage: String {
        switch self {
        case .brick: "rectangle.split.3x1.fill"
        case .ore: "mountain.2.fill"
        case .wheat: "leaf.fill"
        case .lumber: "tree.fill"
        case .wool: "cloud.fill"
        case .desert: "sun.max.fill"
        case .ocean: "water.waves"
        }
    }

}

nonisolated enum NumberToken: Int, CaseIterable, Codable, Identifiable, Sendable {
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    case six = 6
    case eight = 8
    case nine = 9
    case ten = 10
    case eleven = 11
    case twelve = 12

    var id: Int { rawValue }

    var pipCount: Int {
        6 - abs(7 - rawValue)
    }

    var isHighProbability: Bool {
        self == .six || self == .eight
    }
}

nonisolated struct HexCoordinate: Hashable, Codable, Identifiable, Sendable {
    let q: Int
    let r: Int

    var id: String { "\(q),\(r)" }

    static let standardBoard: [HexCoordinate] = {
        (-2...2).flatMap { r in
            (-2...2).compactMap { q in
                let s = -q - r
                return abs(s) <= 2 ? HexCoordinate(q: q, r: r) : nil
            }
        }
    }()
}

nonisolated struct HexTile: Codable, Equatable, Identifiable, Sendable {
    let coordinate: HexCoordinate
    var terrain: Terrain
    var number: NumberToken?

    var id: HexCoordinate { coordinate }
}

nonisolated struct BoardVertex: Hashable, Codable, Comparable, Identifiable, Sendable {
    let x: Int
    let y: Int

    var id: String { "\(x),\(y)" }

    static func < (lhs: BoardVertex, rhs: BoardVertex) -> Bool {
        (lhs.y, lhs.x) < (rhs.y, rhs.x)
    }
}

nonisolated struct BoardEdge: Hashable, Codable, Identifiable, Sendable {
    let start: BoardVertex
    let end: BoardVertex

    init(_ first: BoardVertex, _ second: BoardVertex) {
        if first < second {
            start = first
            end = second
        } else {
            start = second
            end = first
        }
    }

    var id: String { "\(start.id)-\(end.id)" }
}

nonisolated enum Building: String, Codable, Sendable {
    case settlement
    case city
}

nonisolated enum BoardOrientation: Int, Codable, CaseIterable, Sendable {
    case north = 0
    case east = 1
    case south = 2
    case west = 3

    var degrees: Double { Double(rawValue * 90) }

    func rotatedRight() -> Self {
        Self(rawValue: (rawValue + 1) % Self.allCases.count) ?? .north
    }

    func rotatedLeft() -> Self {
        Self(rawValue: (rawValue - 1 + Self.allCases.count) % Self.allCases.count) ?? .north
    }
}

nonisolated struct BoardRotationPresentation: Equatable, Sendable {
    private(set) var quarterTurns: Int

    init(orientation: BoardOrientation) {
        quarterTurns = orientation.rawValue
    }

    var degrees: Double { Double(quarterTurns * 90) }

    mutating func rotateLeft() {
        quarterTurns -= 1
    }

    mutating func rotateRight() {
        quarterTurns += 1
    }
}

nonisolated enum PlacementError: Error, Equatable, Sendable {
    case roadNeedsConnection
    case buildingTooClose
    case cityNeedsSettlement

    var message: String {
        switch self {
        case .roadNeedsConnection:
            "Road must be adjacent to a road, settlement or city of the same colour."
        case .buildingTooClose:
            "Cannot place adjacent to a settlement or a city."
        case .cityNeedsSettlement:
            "City must upgrade a settlement of the same colour."
        }
    }
}

nonisolated struct BoardSnapshot: Equatable, Sendable {
    var tiles: [HexTile]
    var roads: Set<BoardEdge>
    var buildings: [BoardVertex: Building]
    var roadOwners: [BoardEdge: PlayerColor]
    var buildingOwners: [BoardVertex: PlayerColor]
    var hands: [PlayerColor: ResourceHand]
    var customPlans: [CustomPlan]
    var orientation: BoardOrientation
    var activePlayers: [PlayerColor]
    var victoryPointCards: [PlayerColor: Int]
    var largestArmyHolder: PlayerColor?
    var longestRoadHolder: PlayerColor?

    init(
        tiles: [HexTile],
        roads: Set<BoardEdge>,
        buildings: [BoardVertex: Building],
        roadOwners: [BoardEdge: PlayerColor] = [:],
        buildingOwners: [BoardVertex: PlayerColor] = [:],
        hands: [PlayerColor: ResourceHand] = [:],
        customPlans: [CustomPlan] = [],
        orientation: BoardOrientation = .north,
        activePlayers: [PlayerColor] = PlayerColor.defaultActive,
        victoryPointCards: [PlayerColor: Int] = [:],
        largestArmyHolder: PlayerColor? = nil,
        longestRoadHolder: PlayerColor? = nil
    ) {
        self.tiles = tiles
        self.roads = roads
        self.buildings = buildings
        self.roadOwners = roadOwners
        self.buildingOwners = buildingOwners
        self.hands = hands
        self.customPlans = customPlans
        self.orientation = orientation
        self.activePlayers = Self.orderedPlayers(activePlayers)
        self.victoryPointCards = victoryPointCards.filter { $0.value > 0 }
        self.largestArmyHolder = largestArmyHolder
        self.longestRoadHolder = longestRoadHolder
    }
}

extension BoardSnapshot: Codable {
    private enum CodingKeys: String, CodingKey {
        case tiles, roads, buildings, roadOwners, buildingOwners, hands, customPlans, orientation, activePlayers
        case victoryPointCards, largestArmyHolder, longestRoadHolder
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tiles = try container.decode([HexTile].self, forKey: .tiles)
        roads = try container.decode(Set<BoardEdge>.self, forKey: .roads)
        buildings = try container.decode([BoardVertex: Building].self, forKey: .buildings)
        roadOwners = try container.decodeIfPresent(
            [BoardEdge: PlayerColor].self,
            forKey: .roadOwners
        ) ?? Dictionary(uniqueKeysWithValues: roads.map { ($0, .red) })
        buildingOwners = try container.decodeIfPresent(
            [BoardVertex: PlayerColor].self,
            forKey: .buildingOwners
        ) ?? Dictionary(uniqueKeysWithValues: buildings.keys.map { ($0, .red) })
        hands = try container.decodeIfPresent(
            [PlayerColor: ResourceHand].self,
            forKey: .hands
        ) ?? [:]
        customPlans = try container.decodeIfPresent(
            [CustomPlan].self,
            forKey: .customPlans
        ) ?? []
        orientation = try container.decodeIfPresent(
            BoardOrientation.self,
            forKey: .orientation
        ) ?? .north
        activePlayers = Self.orderedPlayers(
            try container.decodeIfPresent([PlayerColor].self, forKey: .activePlayers)
                ?? PlayerColor.allCases
        )
        victoryPointCards = try container.decodeIfPresent(
            [PlayerColor: Int].self,
            forKey: .victoryPointCards
        )?.filter { $0.value > 0 } ?? [:]
        largestArmyHolder = try container.decodeIfPresent(PlayerColor.self, forKey: .largestArmyHolder)
        longestRoadHolder = try container.decodeIfPresent(PlayerColor.self, forKey: .longestRoadHolder)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tiles, forKey: .tiles)
        try container.encode(roads, forKey: .roads)
        try container.encode(buildings, forKey: .buildings)
        try container.encode(roadOwners, forKey: .roadOwners)
        try container.encode(buildingOwners, forKey: .buildingOwners)
        try container.encode(hands, forKey: .hands)
        try container.encode(customPlans, forKey: .customPlans)
        try container.encode(orientation, forKey: .orientation)
        try container.encode(activePlayers, forKey: .activePlayers)
        try container.encode(victoryPointCards, forKey: .victoryPointCards)
        try container.encodeIfPresent(largestArmyHolder, forKey: .largestArmyHolder)
        try container.encodeIfPresent(longestRoadHolder, forKey: .longestRoadHolder)
    }

    nonisolated static func orderedPlayers(_ players: some Sequence<PlayerColor>) -> [PlayerColor] {
        let selected = Set(players)
        let ordered = PlayerColor.allCases.filter(selected.contains)
        return ordered.isEmpty ? PlayerColor.defaultActive : ordered
    }
}

@Observable
final class BoardState {
    private(set) var snapshot: BoardSnapshot

    init(snapshot: BoardSnapshot = .standard) {
        self.snapshot = snapshot
    }

    var tiles: [HexTile] { snapshot.tiles }
    var roads: Set<BoardEdge> { snapshot.roads }
    var buildings: [BoardVertex: Building] { snapshot.buildings }
    var customPlans: [CustomPlan] { snapshot.customPlans }
    var orientation: BoardOrientation { snapshot.orientation }
    var activePlayers: [PlayerColor] { snapshot.activePlayers }
    var largestArmyHolder: PlayerColor? { snapshot.largestArmyHolder }
    var longestRoadHolder: PlayerColor? { snapshot.longestRoadHolder }

    func hasStoredState(for player: PlayerColor) -> Bool {
        !(snapshot.hands[player] ?? ResourceHand()).isEmpty ||
            snapshot.customPlans.contains { $0.player == player } ||
            snapshot.roadOwners.values.contains(player) ||
            snapshot.buildingOwners.values.contains(player)
            || victoryPointCardCount(for: player) > 0
            || snapshot.largestArmyHolder == player
            || snapshot.longestRoadHolder == player
    }

    func addPlayer(_ player: PlayerColor) {
        snapshot.activePlayers = BoardSnapshot.orderedPlayers(snapshot.activePlayers + [player])
    }

    func removePlayer(_ player: PlayerColor) {
        guard snapshot.activePlayers.count > 1,
              snapshot.activePlayers.contains(player) else { return }
        let removedRoads = Set(snapshot.roadOwners.compactMap { $0.value == player ? $0.key : nil })
        let removedBuildings = Set(snapshot.buildingOwners.compactMap { $0.value == player ? $0.key : nil })
        snapshot.roads.subtract(removedRoads)
        snapshot.buildings = snapshot.buildings.filter { !removedBuildings.contains($0.key) }
        snapshot.roadOwners = snapshot.roadOwners.filter { $0.value != player }
        snapshot.buildingOwners = snapshot.buildingOwners.filter { $0.value != player }
        snapshot.hands.removeValue(forKey: player)
        snapshot.customPlans.removeAll { $0.player == player }
        snapshot.victoryPointCards.removeValue(forKey: player)
        if snapshot.largestArmyHolder == player { snapshot.largestArmyHolder = nil }
        if snapshot.longestRoadHolder == player { snapshot.longestRoadHolder = nil }
        snapshot.activePlayers.removeAll { $0 == player }
        refreshLongestRoad()
    }

    func rotateLeft() {
        snapshot.orientation = snapshot.orientation.rotatedLeft()
    }

    func rotateRight() {
        snapshot.orientation = snapshot.orientation.rotatedRight()
    }

    func savePlan(_ plan: CustomPlan) {
        if let index = snapshot.customPlans.firstIndex(where: { $0.id == plan.id }) {
            snapshot.customPlans[index] = plan
        } else {
            snapshot.customPlans.append(plan)
        }
    }

    func hand(for player: PlayerColor) -> ResourceHand {
        snapshot.hands[player] ?? ResourceHand()
    }

    func addCard(_ resource: ResourceCard, to player: PlayerColor) {
        var hand = hand(for: player)
        hand.add(resource)
        snapshot.hands[player] = hand
    }

    func removeCard(_ resource: ResourceCard, from player: PlayerColor) {
        var hand = hand(for: player)
        hand.remove(resource)
        snapshot.hands[player] = hand
    }

    func clearHand(for player: PlayerColor) {
        snapshot.hands[player] = ResourceHand()
    }

    func victoryPointCardCount(for player: PlayerColor) -> Int {
        snapshot.victoryPointCards[player, default: 0]
    }

    func addVictoryPointCard(to player: PlayerColor) {
        snapshot.victoryPointCards[player, default: 0] += 1
    }

    func removeVictoryPointCard(from player: PlayerColor) {
        let count = victoryPointCardCount(for: player)
        if count > 1 {
            snapshot.victoryPointCards[player] = count - 1
        } else {
            snapshot.victoryPointCards.removeValue(forKey: player)
        }
    }

    func assignLargestArmy(to player: PlayerColor) {
        snapshot.largestArmyHolder = snapshot.largestArmyHolder == player ? nil : player
    }

    func roadLength(for player: PlayerColor) -> Int {
        let ownedRoads = snapshot.roads.filter { owner(of: $0) == player }
        guard !ownedRoads.isEmpty else { return 0 }

        func walk(from vertex: BoardVertex, used: Set<BoardEdge>) -> Int {
            if !used.isEmpty,
               snapshot.buildings[vertex] != nil,
               owner(of: vertex) != player {
                return 0
            }
            return ownedRoads
                .filter { !used.contains($0) && ($0.start == vertex || $0.end == vertex) }
                .map { edge in
                    let next = edge.start == vertex ? edge.end : edge.start
                    return 1 + walk(from: next, used: used.union([edge]))
                }
                .max() ?? 0
        }

        return ownedRoads.flatMap { [walk(from: $0.start, used: []), walk(from: $0.end, used: [])] }.max() ?? 0
    }

    func victoryPoints(for player: PlayerColor) -> Int {
        let buildingPoints = snapshot.buildings.reduce(into: 0) { total, entry in
            guard owner(of: entry.key) == player else { return }
            total += entry.value == .city ? 2 : 1
        }
        return buildingPoints
            + victoryPointCardCount(for: player)
            + (snapshot.largestArmyHolder == player ? 2 : 0)
            + (snapshot.longestRoadHolder == player ? 2 : 0)
    }

    @discardableResult
    func reassignLongestRoad(to player: PlayerColor) -> Bool {
        guard let holder = snapshot.longestRoadHolder,
              holder != player,
              roadLength(for: holder) >= 5,
              roadLength(for: player) == roadLength(for: holder) else { return false }
        snapshot.longestRoadHolder = player
        return true
    }

    func owner(of edge: BoardEdge) -> PlayerColor {
        snapshot.roadOwners[edge] ?? .red
    }

    func owner(of vertex: BoardVertex) -> PlayerColor {
        snapshot.buildingOwners[vertex] ?? .red
    }

    func setTerrain(_ terrain: Terrain, at coordinate: HexCoordinate) {
        guard let index = tileIndex(at: coordinate) else { return }
        snapshot.tiles[index].terrain = terrain
        if terrain == .desert || terrain == .ocean {
            snapshot.tiles[index].number = nil
        }
    }

    func setNumber(_ number: NumberToken, at coordinate: HexCoordinate) {
        guard let index = tileIndex(at: coordinate) else { return }
        snapshot.tiles[index].number = number
    }

    func clearNumber(at coordinate: HexCoordinate) {
        guard let index = tileIndex(at: coordinate) else { return }
        snapshot.tiles[index].number = nil
    }

    @discardableResult
    func toggleRoad(on edge: BoardEdge, for player: PlayerColor) -> PlacementError? {
        if snapshot.roads.contains(edge) {
            guard owner(of: edge) == player else { return nil }
            snapshot.roads.remove(edge)
            snapshot.roadOwners.removeValue(forKey: edge)
            refreshLongestRoad()
            return nil
        } else {
            return placeRoad(on: edge, for: player)
        }
    }

    @discardableResult
    func placeRoad(on edge: BoardEdge, for player: PlayerColor) -> PlacementError? {
        guard !snapshot.roads.contains(edge) else { return .roadNeedsConnection }
        let hasAdjacentBuilding = [edge.start, edge.end].contains { vertex in
            snapshot.buildings[vertex] != nil && owner(of: vertex) == player
        }
        let hasAdjacentRoad = snapshot.roads.contains { road in
            owner(of: road) == player && roadsShareVertex(road, edge)
        }
        guard hasAdjacentBuilding || hasAdjacentRoad else { return .roadNeedsConnection }
        snapshot.roads.insert(edge)
        snapshot.roadOwners[edge] = player
        refreshLongestRoad(contender: player)
        return nil
    }

    private func roadsShareVertex(_ first: BoardEdge, _ second: BoardEdge) -> Bool {
        first.start == second.start || first.start == second.end ||
            first.end == second.start || first.end == second.end
    }

    @discardableResult
    func cycleBuilding(at vertex: BoardVertex, for player: PlayerColor) -> PlacementError? {
        if snapshot.buildings[vertex] != nil, owner(of: vertex) != player { return nil }

        switch snapshot.buildings[vertex] {
        case nil:
            return placeBuilding(.settlement, at: vertex, for: player)
        case .settlement:
            snapshot.buildings[vertex] = .city
            return nil
        case .city:
            snapshot.buildings.removeValue(forKey: vertex)
            snapshot.buildingOwners.removeValue(forKey: vertex)
            refreshLongestRoad()
            return nil
        }
    }

    @discardableResult
    func placeBuilding(
        _ building: Building,
        at vertex: BoardVertex,
        for player: PlayerColor
    ) -> PlacementError? {
        if let existing = snapshot.buildings[vertex] {
            if existing == .settlement, building == .city {
                guard owner(of: vertex) == player else { return .cityNeedsSettlement }
                snapshot.buildings[vertex] = .city
                refreshLongestRoad()
                return nil
            }
            if building == .city { return .cityNeedsSettlement }
            return .buildingTooClose
        }

        if building == .city { return .cityNeedsSettlement }

        let hasAdjacentBuilding = BoardGeometry.adjacentVertices(to: vertex).contains {
            snapshot.buildings[$0] != nil
        }
        guard !hasAdjacentBuilding else { return .buildingTooClose }
        snapshot.buildings[vertex] = building
        snapshot.buildingOwners[vertex] = player
        refreshLongestRoad()
        return nil
    }

    func encoded() throws -> Data {
        try JSONEncoder().encode(snapshot)
    }

    static func decode(_ data: Data) throws -> BoardState {
        BoardState(snapshot: try JSONDecoder().decode(BoardSnapshot.self, from: data))
    }

    private func tileIndex(at coordinate: HexCoordinate) -> Int? {
        snapshot.tiles.firstIndex { $0.coordinate == coordinate }
    }

    private func refreshLongestRoad(contender: PlayerColor? = nil) {
        if let holder = snapshot.longestRoadHolder {
            let holderLength = roadLength(for: holder)
            guard holderLength >= 5 else {
                snapshot.longestRoadHolder = nil
                refreshLongestRoad(contender: contender)
                return
            }
            if let contender,
               contender != holder,
               roadLength(for: contender) > holderLength {
                snapshot.longestRoadHolder = contender
            }
            return
        }

        if let contender, roadLength(for: contender) >= 5 {
            snapshot.longestRoadHolder = contender
            return
        }
        snapshot.longestRoadHolder = snapshot.activePlayers.first { roadLength(for: $0) >= 5 }
    }
}

extension BoardSnapshot {
    static let standard = BoardSnapshot(
        tiles: HexCoordinate.standardBoard.map {
            HexTile(coordinate: $0, terrain: .ocean, number: nil)
        },
        roads: [],
        buildings: [:],
        roadOwners: [:],
        buildingOwners: [:],
        hands: [:],
        customPlans: [],
        orientation: .north,
        activePlayers: PlayerColor.defaultActive
    )

    static func standard(activePlayers: [PlayerColor]) -> BoardSnapshot {
        var snapshot = standard
        snapshot.activePlayers = orderedPlayers(activePlayers)
        return snapshot
    }
}
