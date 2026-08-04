import Foundation
import Testing
@testable import Catanalyst

@Suite("Board state")
struct BoardStateTests {
    @Test("A standard board has nineteen unique hexes")
    func standardBoardShape() {
        let board = BoardState()

        #expect(board.tiles.count == 19)
        #expect(Set(board.tiles.map(\.coordinate)).count == 19)
        #expect(board.tiles.map(\.coordinate).filter { $0.r == -2 }.count == 3)
        #expect(board.tiles.map(\.coordinate).filter { $0.r == -1 }.count == 4)
        #expect(board.tiles.map(\.coordinate).filter { $0.r == 0 }.count == 5)
        #expect(board.tiles.map(\.coordinate).filter { $0.r == 1 }.count == 4)
        #expect(board.tiles.map(\.coordinate).filter { $0.r == 2 }.count == 3)
    }

    @Test("Standard geometry shares vertices and edges between hexes")
    func standardBoardGeometry() {
        #expect(BoardGeometry.standardVertices.count == 54)
        #expect(BoardGeometry.standardEdges.count == 72)

        let firstEdges = Set(BoardGeometry.edges(for: HexCoordinate(q: 0, r: 0)))
        let neighbourEdges = Set(BoardGeometry.edges(for: HexCoordinate(q: 1, r: 0)))
        #expect(firstEdges.intersection(neighbourEdges).count == 1)
    }

    @Test("Terrain and number tokens can be changed")
    func editsHex() throws {
        let board = BoardState()
        let coordinate = try #require(board.tiles.first?.coordinate)

        board.setTerrain(.wheat, at: coordinate)
        board.setNumber(.eight, at: coordinate)

        let tile = try #require(board.tiles.first { $0.coordinate == coordinate })
        #expect(tile.terrain == .wheat)
        #expect(tile.number == .eight)
        #expect(tile.number?.pipCount == 5)
        #expect(tile.number?.isHighProbability == true)
        #expect(NumberToken(rawValue: 7) == nil)
    }

    @Test("Desert and ocean terrain remove an existing number")
    func nonProducingTerrainClearsNumber() throws {
        let board = BoardState()
        let coordinate = try #require(board.tiles.first?.coordinate)
        board.setNumber(.six, at: coordinate)

        board.setTerrain(.desert, at: coordinate)

        let tile = try #require(board.tiles.first { $0.coordinate == coordinate })
        #expect(tile.number == nil)
    }

    @Test("A number can be removed without changing terrain")
    func clearsNumber() throws {
        let board = BoardState()
        let coordinate = try #require(board.tiles.first?.coordinate)
        board.setTerrain(.wheat, at: coordinate)
        board.setNumber(.nine, at: coordinate)

        board.clearNumber(at: coordinate)

        let tile = try #require(board.tiles.first { $0.coordinate == coordinate })
        #expect(tile.terrain == .wheat)
        #expect(tile.number == nil)
    }

    @Test("Roads toggle on and off")
    func togglesRoad() throws {
        let board = BoardState()
        let edge = try #require(BoardGeometry.standardEdges.first)

        board.cycleBuilding(at: edge.start, for: .red)
        board.toggleRoad(on: edge, for: .red)
        #expect(board.roads == [edge])
        #expect(board.owner(of: edge) == .red)

        board.toggleRoad(on: edge, for: .red)
        #expect(board.roads.isEmpty)
    }

    @Test("Buildings cycle from settlement to city to empty")
    func cyclesBuilding() throws {
        let board = BoardState()
        let edge = try #require(BoardGeometry.standardEdges.first)
        let vertex = edge.start

        board.cycleBuilding(at: vertex, for: .blue)
        #expect(board.buildings[vertex] == .settlement)
        #expect(board.owner(of: vertex) == .blue)

        board.cycleBuilding(at: vertex, for: .blue)
        #expect(board.buildings[vertex] == .city)

        board.cycleBuilding(at: vertex, for: .blue)
        #expect(board.buildings[vertex] == nil)
    }

    @Test("Board snapshots round-trip through JSON")
    func codableRoundTrip() throws {
        let board = BoardState()
        let coordinate = try #require(board.tiles.first?.coordinate)
        let edge = try #require(BoardGeometry.standardEdges.first)
        let vertex = edge.start
        board.setTerrain(.brick, at: coordinate)
        board.setNumber(.five, at: coordinate)
        board.cycleBuilding(at: vertex, for: .orange)
        board.toggleRoad(on: edge, for: .orange)

        let decoded = try BoardState.decode(board.encoded())

        #expect(decoded.snapshot == board.snapshot)
    }

    @Test("Players cannot change pieces owned by another player")
    func ownershipIsIsolated() throws {
        let board = BoardState()
        let edge = try #require(BoardGeometry.standardEdges.first)
        let vertex = edge.start

        board.cycleBuilding(at: vertex, for: .red)
        board.toggleRoad(on: edge, for: .red)
        board.toggleRoad(on: edge, for: .blue)
        board.cycleBuilding(at: vertex, for: .blue)

        #expect(board.roads.contains(edge))
        #expect(board.owner(of: edge) == .red)
        #expect(board.buildings[vertex] == .settlement)
        #expect(board.owner(of: vertex) == .red)
    }

    @Test("Road placement accepts a same-colour building or road connection")
    func validatesRoadPlacement() throws {
        let board = BoardState()
        let edge = try #require(BoardGeometry.standardEdges.first)
        let continuation = try #require(BoardGeometry.standardEdges.first {
            $0 != edge && [$0.start, $0.end].contains(edge.end)
        })

        #expect(board.placeRoad(on: edge, for: .red) == .roadNeedsConnection)
        board.cycleBuilding(at: edge.start, for: .blue)
        #expect(board.placeRoad(on: edge, for: .red) == .roadNeedsConnection)
        #expect(board.placeRoad(on: edge, for: .blue) == nil)
        #expect(board.placeRoad(on: continuation, for: .red) == .roadNeedsConnection)
        #expect(board.placeRoad(on: continuation, for: .blue) == nil)
        #expect(board.roads.contains(edge))
        #expect(board.roads.contains(continuation))
    }

    @Test("A road chain does not make a disconnected road valid")
    func rejectsDisconnectedRoad() throws {
        let board = BoardState()
        let first = try #require(BoardGeometry.standardEdges.first)
        let disconnected = try #require(BoardGeometry.standardEdges.first { candidate in
            ![candidate.start, candidate.end].contains(first.start) &&
                ![candidate.start, candidate.end].contains(first.end)
        })

        #expect(board.placeBuilding(.settlement, at: first.start, for: .red) == nil)
        #expect(board.placeRoad(on: first, for: .red) == nil)
        #expect(board.placeRoad(on: disconnected, for: .red) == .roadNeedsConnection)
    }

    @Test("Buildings cannot be placed at adjacent vertices")
    func validatesBuildingDistance() throws {
        let board = BoardState()
        let edge = try #require(BoardGeometry.standardEdges.first)

        #expect(board.placeBuilding(.settlement, at: edge.start, for: .red) == nil)
        #expect(board.placeBuilding(.settlement, at: edge.end, for: .blue) == .buildingTooClose)
        #expect(board.buildings[edge.end] == nil)
        #expect(board.placeBuilding(.city, at: edge.start, for: .red) == nil)
        #expect(board.buildings[edge.start] == .city)
    }

    @Test("Placement errors use the required messages")
    func placementMessages() {
        #expect(PlacementError.roadNeedsConnection.message ==
            "Road must be adjacent to a road, settlement or city of the same colour.")
        #expect(PlacementError.buildingTooClose.message ==
            "Cannot place adjacent to a settlement or a city.")
    }

    @Test("Six serializable player colours are available")
    func playerColours() throws {
        #expect(PlayerColor.allCases.count == 6)
        let encoded = try JSONEncoder().encode(PlayerColor.allCases)
        #expect(try JSONDecoder().decode([PlayerColor].self, from: encoded) == PlayerColor.allCases)
    }
}
