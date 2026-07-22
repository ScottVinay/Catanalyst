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

nonisolated struct BoardSnapshot: Codable, Equatable, Sendable {
    var tiles: [HexTile]
    var roads: Set<BoardEdge>
    var buildings: [BoardVertex: Building]
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

    func toggleRoad(on edge: BoardEdge) {
        if snapshot.roads.remove(edge) == nil {
            snapshot.roads.insert(edge)
        }
    }

    func cycleBuilding(at vertex: BoardVertex) {
        switch snapshot.buildings[vertex] {
        case nil:
            snapshot.buildings[vertex] = .settlement
        case .settlement:
            snapshot.buildings[vertex] = .city
        case .city:
            snapshot.buildings.removeValue(forKey: vertex)
        }
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
        buildings: [:]
    )
}
