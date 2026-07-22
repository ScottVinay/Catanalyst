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

    @Test("Roads toggle on and off")
    func togglesRoad() throws {
        let board = BoardState()
        let edge = try #require(BoardGeometry.standardEdges.first)

        board.toggleRoad(on: edge)
        #expect(board.roads == [edge])

        board.toggleRoad(on: edge)
        #expect(board.roads.isEmpty)
    }

    @Test("Buildings cycle from settlement to city to empty")
    func cyclesBuilding() throws {
        let board = BoardState()
        let vertex = try #require(BoardGeometry.standardVertices.first)

        board.cycleBuilding(at: vertex)
        #expect(board.buildings[vertex] == .settlement)

        board.cycleBuilding(at: vertex)
        #expect(board.buildings[vertex] == .city)

        board.cycleBuilding(at: vertex)
        #expect(board.buildings[vertex] == nil)
    }

    @Test("Board snapshots round-trip through JSON")
    func codableRoundTrip() throws {
        let board = BoardState()
        let coordinate = try #require(board.tiles.first?.coordinate)
        let edge = try #require(BoardGeometry.standardEdges.first)
        let vertex = try #require(BoardGeometry.standardVertices.first)
        board.setTerrain(.brick, at: coordinate)
        board.setNumber(.five, at: coordinate)
        board.toggleRoad(on: edge)
        board.cycleBuilding(at: vertex)

        let decoded = try BoardState.decode(board.encoded())

        #expect(decoded.snapshot == board.snapshot)
    }
}
