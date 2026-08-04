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

nonisolated enum PlacementError: Error, Equatable, Sendable {
    case roadNeedsConnection
    case buildingTooClose

    var message: String {
        switch self {
        case .roadNeedsConnection:
            "Road must be adjacent to a road, settlement or city of the same colour."
        case .buildingTooClose:
            "Cannot place adjacent to a settlement or a city."
        }
    }
}

nonisolated struct BoardSnapshot: Equatable, Sendable {
    var tiles: [HexTile]
    var roads: Set<BoardEdge>
    var buildings: [BoardVertex: Building]
    var roadOwners: [BoardEdge: PlayerColor]
    var buildingOwners: [BoardVertex: PlayerColor]

    init(
        tiles: [HexTile],
        roads: Set<BoardEdge>,
        buildings: [BoardVertex: Building],
        roadOwners: [BoardEdge: PlayerColor] = [:],
        buildingOwners: [BoardVertex: PlayerColor] = [:]
    ) {
        self.tiles = tiles
        self.roads = roads
        self.buildings = buildings
        self.roadOwners = roadOwners
        self.buildingOwners = buildingOwners
    }
}

extension BoardSnapshot: Codable {
    private enum CodingKeys: String, CodingKey {
        case tiles, roads, buildings, roadOwners, buildingOwners
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
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tiles, forKey: .tiles)
        try container.encode(roads, forKey: .roads)
        try container.encode(buildings, forKey: .buildings)
        try container.encode(roadOwners, forKey: .roadOwners)
        try container.encode(buildingOwners, forKey: .buildingOwners)
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
            guard owner(of: vertex) == player else { return .buildingTooClose }
            if existing == .settlement, building == .city {
                snapshot.buildings[vertex] = .city
                return nil
            }
            return .buildingTooClose
        }

        let hasAdjacentBuilding = BoardGeometry.adjacentVertices(to: vertex).contains {
            snapshot.buildings[$0] != nil
        }
        guard !hasAdjacentBuilding else { return .buildingTooClose }
        snapshot.buildings[vertex] = building
        snapshot.buildingOwners[vertex] = player
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
}

extension BoardSnapshot {
    static let standard = BoardSnapshot(
        tiles: HexCoordinate.standardBoard.map {
            HexTile(coordinate: $0, terrain: .ocean, number: nil)
        },
        roads: [],
        buildings: [:],
        roadOwners: [:],
        buildingOwners: [:]
    )
}
