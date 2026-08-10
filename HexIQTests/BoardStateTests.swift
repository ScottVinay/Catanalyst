import Foundation
import Testing
@testable import HexIQ

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

    @Test("Every terrain has a distinct repeated symbol mapping")
    func terrainSymbols() {
        #expect(Set(Terrain.allCases.map(\.systemImage)).count == Terrain.allCases.count)
        #expect(Terrain.allCases.allSatisfy { !$0.systemImage.isEmpty })
        #expect(Terrain.allCases.allSatisfy { $0.symbolCopies == 6 })
    }

    @Test("Standard geometry shares vertices and edges between hexes")
    func standardBoardGeometry() {
        #expect(BoardGeometry.standardVertices.count == 54)
        #expect(BoardGeometry.standardEdges.count == 72)

        let firstEdges = Set(BoardGeometry.edges(for: HexCoordinate(q: 0, r: 0)))
        let neighbourEdges = Set(BoardGeometry.edges(for: HexCoordinate(q: 1, r: 0)))
        #expect(firstEdges.intersection(neighbourEdges).count == 1)
    }

    @Test("Vertex values sum pips from adjoining producing hexes")
    func vertexPipValues() throws {
        let vertex = try #require(BoardGeometry.vertices(for: HexCoordinate(q: 0, r: 0)).first)
        let adjoining = HexCoordinate.standardBoard.filter {
            BoardGeometry.vertices(for: $0).contains(vertex)
        }
        #expect(adjoining.count == 3)

        let tiles = [
            HexTile(coordinate: adjoining[0], terrain: .brick, number: .six),
            HexTile(coordinate: adjoining[1], terrain: .wheat, number: .nine),
            HexTile(coordinate: adjoining[2], terrain: .ore, number: .three),
        ]

        #expect(BoardGeometry.pipValue(at: vertex, tiles: tiles) == 11)
        #expect(BoardGeometry.pipValue(at: BoardVertex(x: 100, y: 100), tiles: tiles) == 0)
    }

    @Test("Unnumbered and non-producing hexes add no vertex pips")
    func nonProducingVertexPipValues() throws {
        let coordinate = HexCoordinate(q: 0, r: 0)
        let vertex = try #require(BoardGeometry.vertices(for: coordinate).first)
        let tiles = [
            HexTile(coordinate: coordinate, terrain: .desert, number: .six),
            HexTile(coordinate: HexCoordinate(q: 0, r: -1), terrain: .ocean, number: .eight),
            HexTile(coordinate: HexCoordinate(q: 1, r: -1), terrain: .brick, number: nil),
        ]

        #expect(BoardGeometry.pipValue(at: vertex, tiles: tiles) == 0)
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
        board.addCard(.ore, to: .orange)
        board.addCard(.ore, to: .orange)
        board.savePlan(CustomPlan(
            name: "Persisted route",
            kind: .constructions,
            player: .orange,
            systemImage: "flag.fill"
        ))

        let decoded = try BoardState.decode(board.encoded())

        #expect(decoded.snapshot == board.snapshot)
    }

    @Test("Saved Analysis items update by identity and remain isolated")
    func savesAnalysisItems() throws {
        let board = BoardState()
        var red = CustomPlan(name: "Prod 1", kind: .cards, player: .red)
        let blue = CustomPlan(name: "Plan 1", kind: .constructions, player: .blue)
        board.savePlan(red)
        board.savePlan(blue)
        red.name = "Updated"
        red.systemImage = "target"
        board.savePlan(red)

        #expect(board.customPlans.count == 2)
        #expect(board.customPlans.first { $0.id == red.id }?.name == "Updated")
        #expect(board.customPlans.first { $0.id == red.id }?.systemImage == "target")
        #expect(CustomPlan.belonging(to: .blue, in: board.customPlans) == [blue])
        #expect(try BoardState.decode(board.encoded()).customPlans == board.customPlans)
    }

    @Test("Active game persistence restores a full snapshot and can clear it")
    func activeGamePersistence() throws {
        let suiteName = "HexIQTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let persistence = ActiveGamePersistence(defaults: defaults)
        let board = BoardState()
        board.addCard(.ore, to: .green)
        board.savePlan(CustomPlan(name: "Prod 1", kind: .cards, player: .green))

        persistence.save(board.snapshot)
        #expect(persistence.load() == board.snapshot)
        persistence.clear()
        #expect(persistence.load() == nil)
    }

    @Test("Hands add, remove, clear, and remain isolated by player")
    func editsHands() {
        let board = BoardState()

        board.addCard(.brick, to: .red)
        board.addCard(.brick, to: .red)
        board.addCard(.ore, to: .blue)
        #expect(board.hand(for: .red)[.brick] == 2)
        #expect(board.hand(for: .blue)[.ore] == 1)

        board.removeCard(.brick, from: .red)
        #expect(board.hand(for: .red)[.brick] == 1)
        board.removeCard(.brick, from: .red)
        #expect(board.hand(for: .red)[.brick] == 0)
        #expect(board.hand(for: .blue)[.ore] == 1)

        board.clearHand(for: .blue)
        #expect(board.hand(for: .blue).isEmpty)
    }

    @Test("Legacy Board JSON without hands decodes empty hands")
    func decodesLegacyHands() throws {
        let board = BoardState()
        let encoded = try board.encoded()
        var object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object.removeValue(forKey: "hands")
        object.removeValue(forKey: "customPlans")

        let decoded = try BoardState.decode(JSONSerialization.data(withJSONObject: object))

        #expect(PlayerColor.allCases.allSatisfy { decoded.hand(for: $0).isEmpty })
        #expect(decoded.tiles == board.tiles)
        #expect(decoded.roads == board.roads)
        #expect(decoded.buildings == board.buildings)
        #expect(decoded.customPlans.isEmpty)
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
        #expect(PlacementError.cityNeedsSettlement.message ==
            "City must upgrade a settlement of the same colour.")
    }

    @Test("Cities only upgrade a same-colour settlement")
    func validatesCityUpgrade() throws {
        let board = BoardState()
        let edge = try #require(BoardGeometry.standardEdges.first)

        #expect(board.placeBuilding(.city, at: edge.start, for: .red) == .cityNeedsSettlement)
        #expect(board.buildings[edge.start] == nil)

        #expect(board.placeBuilding(.settlement, at: edge.start, for: .blue) == nil)
        #expect(board.placeBuilding(.city, at: edge.start, for: .red) == .cityNeedsSettlement)
        #expect(board.buildings[edge.start] == .settlement)
        #expect(board.owner(of: edge.start) == .blue)

        #expect(board.placeBuilding(.city, at: edge.start, for: .blue) == nil)
        #expect(board.buildings[edge.start] == .city)
        #expect(board.placeBuilding(.city, at: edge.start, for: .blue) == .cityNeedsSettlement)
    }

    @Test("Six serializable player colours are available")
    func playerColours() throws {
        #expect(PlayerColor.allCases.count == 6)
        let encoded = try JSONEncoder().encode(PlayerColor.allCases)
        #expect(try JSONDecoder().decode([PlayerColor].self, from: encoded) == PlayerColor.allCases)
    }

    @Test("Four quarter turns return to the original orientation without changing board geometry")
    func boardRotationCycles() {
        let board = BoardState()
        let originalTiles = board.tiles

        for _ in 0..<4 { board.rotateRight() }
        #expect(board.orientation == .north)
        #expect(board.tiles == originalTiles)

        for _ in 0..<4 { board.rotateLeft() }
        #expect(board.orientation == .north)
        #expect(board.tiles == originalTiles)
    }

    @Test("Board orientation persists in snapshots")
    func boardOrientationRoundTrip() throws {
        let board = BoardState()
        board.rotateRight()
        let decoded = try BoardState.decode(board.encoded())

        #expect(decoded.orientation == .east)
    }

    @Test("Presentation rotation preserves requested direction across normalized wrap points")
    func directionalPresentationRotation() {
        var left = BoardRotationPresentation(orientation: .north)
        left.rotateLeft()
        #expect(left.degrees == -90)

        var right = BoardRotationPresentation(orientation: .west)
        right.rotateRight()
        #expect(right.degrees == 360)

        for _ in 0..<3 { left.rotateLeft() }
        #expect(left.degrees == -360)
    }

    @Test("Standard Board geometry is centred on its rendered origin")
    func renderedBoardGeometricCenter() {
        let origin = CGPoint(x: 137, y: 241)
        let center = BoardGeometry.geometricCenter(
            for: HexCoordinate.standardBoard,
            hexSize: 20,
            origin: origin
        )

        #expect(abs(center.x - origin.x) < 0.0001)
        #expect(abs(center.y - origin.y) < 0.0001)
    }

    @Test("Active players use the four-player default and persist in stable colour order")
    func activePlayersPersist() throws {
        #expect(BoardState().activePlayers == PlayerColor.defaultActive)
        let board = BoardState(snapshot: .standard(activePlayers: [.green, .red]))
        #expect(board.activePlayers == [.red, .green])
        #expect(try BoardState.decode(board.encoded()).activePlayers == [.red, .green])
    }

    @Test("Removing a player clears all state they own")
    func removingPlayerClearsOwnedState() throws {
        let board = BoardState()
        let edge = try #require(BoardGeometry.standardEdges.first)
        board.addCard(.brick, to: .blue)
        board.savePlan(CustomPlan(name: "Blue plan", kind: .cards, player: .blue))
        #expect(board.placeBuilding(.settlement, at: edge.start, for: .blue) == nil)
        #expect(board.placeRoad(on: edge, for: .blue) == nil)
        #expect(board.hasStoredState(for: .blue))

        board.removePlayer(.blue)

        #expect(!board.activePlayers.contains(.blue))
        #expect(board.hand(for: .blue).isEmpty)
        #expect(!board.customPlans.contains { $0.player == .blue })
        #expect(board.roads.isEmpty)
        #expect(board.buildings.isEmpty)
        #expect(!board.hasStoredState(for: .blue))
    }

    @Test("Production uses dice probability, building multiplier, and rolls per round")
    func productionPerRound() throws {
        let board = BoardState()
        let coordinate = HexCoordinate(q: 0, r: 0)
        let vertex = try #require(BoardGeometry.vertices(for: coordinate).first)
        board.setTerrain(.brick, at: coordinate)
        board.setNumber(.six, at: coordinate)
        #expect(board.placeBuilding(.settlement, at: vertex, for: .red) == nil)

        let settlement = ProductionMetrics.meanPerRound(
            resource: .brick, player: .red, snapshot: board.snapshot
        )
        #expect(abs(settlement - 20.0 / 36.0) < 0.0001)
        let rounds = try #require(ProductionMetrics.roundsUntilOne(
            resource: .brick, player: .red, snapshot: board.snapshot
        ))
        let perRoundSuccess = 1 - pow(31.0 / 36.0, 4)
        #expect(abs(rounds - 1 / perRoundSuccess) < 0.0001)

        #expect(board.placeBuilding(.city, at: vertex, for: .red) == nil)
        let city = ProductionMetrics.meanPerRound(
            resource: .all, player: .red, snapshot: board.snapshot
        )
        #expect(abs(city - 40.0 / 36.0) < 0.0001)
        let emptySnapshot = BoardSnapshot.standard(activePlayers: [.red])
        #expect(ProductionMetrics.roundsUntilOne(
            resource: .all, player: .red, snapshot: emptySnapshot
        ) == nil)
    }

    @Test("Production contributions retain building and hex identity")
    func productionContributionIdentity() throws {
        let coordinate = HexCoordinate(q: 0, r: 0)
        let vertex = try #require(BoardGeometry.vertices(for: coordinate).first)
        let snapshot = BoardSnapshot(
            tiles: [HexTile(coordinate: coordinate, terrain: .ore, number: .eight)],
            roads: [],
            buildings: [vertex: .city],
            buildingOwners: [vertex: .blue],
            activePlayers: [.red, .blue]
        )

        let contribution = try #require(ProductionMetrics.contributions(snapshot: snapshot).only)
        #expect(contribution.player == .blue)
        #expect(contribution.buildingID == vertex)
        #expect(contribution.buildingType == .city)
        #expect(contribution.hexID == coordinate)
        #expect(contribution.resource == .ore)
        #expect(contribution.diceResult == 8)
        #expect(contribution.cardsProduced == 2)
    }

    @Test("All production preserves correlated resources and agrees on its mean")
    func allProductionCorrelation() throws {
        let brickHex = HexCoordinate(q: 0, r: 0)
        let lumberHex = HexCoordinate(q: 1, r: 0)
        let sharedVertex = try #require(
            Set(BoardGeometry.vertices(for: brickHex))
                .intersection(BoardGeometry.vertices(for: lumberHex))
                .first
        )
        let snapshot = BoardSnapshot(
            tiles: [
                HexTile(coordinate: brickHex, terrain: .brick, number: .six),
                HexTile(coordinate: lumberHex, terrain: .lumber, number: .six)
            ],
            roads: [],
            buildings: [sharedVertex: .settlement],
            buildingOwners: [sharedVertex: .red],
            activePlayers: [.red]
        )

        let allRoll = ProductionMetrics.perRollDistribution(
            resource: .all, player: .red, snapshot: snapshot
        )
        let directDiceTotals = ProductionMetrics.cardsProducedByDiceResult(
            resource: .all, player: .red, snapshot: snapshot
        )
        let summedDiceTotals = ProductionResource.individual.reduce(into: [Int: Int]()) { totals, resource in
            for (result, count) in ProductionMetrics.cardsProducedByDiceResult(
                resource: resource, player: .red, snapshot: snapshot
            ) {
                totals[result, default: 0] += count
            }
        }
        #expect(directDiceTotals == summedDiceTotals)
        #expect(abs(allRoll.probability(of: 2) - 5.0 / 36.0) < 0.0001)
        #expect(allRoll.probability(of: 1) == 0)

        let allMean = ProductionMetrics.meanPerRound(
            resource: .all, player: .red, snapshot: snapshot
        )
        let summedMean = ProductionResource.individual.reduce(0) {
            $0 + ProductionMetrics.meanPerRound(resource: $1, player: .red, snapshot: snapshot)
        }
        #expect(abs(allMean - summedMean) < 0.0001)
        #expect(abs(allMean - allRoll.mean) < 0.0001)
    }

    @Test("Round distributions are precomputed for one through six rolls")
    func productionRoundDistributions() throws {
        let coordinate = HexCoordinate(q: 0, r: 0)
        let vertex = try #require(BoardGeometry.vertices(for: coordinate).first)
        let snapshot = BoardSnapshot(
            tiles: [HexTile(coordinate: coordinate, terrain: .wheat, number: .six)],
            roads: [],
            buildings: [vertex: .settlement],
            buildingOwners: [vertex: .red],
            activePlayers: [.red]
        )
        let distributions = ProductionMetrics.roundDistributions(
            resource: .wheat, player: .red, snapshot: snapshot
        )

        #expect(distributions.count == 6)
        for (index, distribution) in distributions.enumerated() {
            let rolls = index + 1
            #expect(abs(distribution.probabilities.values.reduce(0, +) - 1) < 0.0001)
            #expect(abs(distribution.mean - Double(rolls) * 5.0 / 36.0) < 0.0001)
            #expect(abs(distribution.probability(of: 0) - pow(31.0 / 36.0, Double(rolls))) < 0.0001)
        }
    }

    @Test("Production buckets include tails and geometric waiting probabilities")
    func productionBuckets() throws {
        let coordinate = HexCoordinate(q: 0, r: 0)
        let vertex = try #require(BoardGeometry.vertices(for: coordinate).first)
        let snapshot = BoardSnapshot(
            tiles: [HexTile(coordinate: coordinate, terrain: .wool, number: .six)],
            roads: [],
            buildings: [vertex: .settlement],
            buildingOwners: [vertex: .red],
            activePlayers: PlayerColor.allCases
        )

        let cards = ProductionMetrics.cardsPerRoundBuckets(
            resource: .sheep, player: .red, snapshot: snapshot
        )
        let waits = ProductionMetrics.roundsPerCardBuckets(
            resource: .sheep, player: .red, snapshot: snapshot
        )
        #expect(cards.count == 5)
        #expect(waits.count == 4)
        #expect(abs(cards.reduce(0, +) - 1) < 0.0001)
        #expect(abs(waits.reduce(0, +) - 1) < 0.0001)
        #expect(cards[4] > 0)
    }

    @Test("Dice reliance excludes seven and weights displayed results")
    func diceReliance() throws {
        let coordinate = HexCoordinate(q: 0, r: 0)
        let vertex = try #require(BoardGeometry.vertices(for: coordinate).first)
        let snapshot = BoardSnapshot(
            tiles: [HexTile(coordinate: coordinate, terrain: .brick, number: .six)],
            roads: [],
            buildings: [vertex: .city],
            buildingOwners: [vertex: .red]
        )
        let raw = ProductionMetrics.cardsProducedByDiceResult(player: .red, snapshot: snapshot)
        let expected = ProductionMetrics.expectedCardsByDiceResult(player: .red, snapshot: snapshot)

        #expect(!ProductionMetrics.displayedDiceResults.contains(7))
        #expect(raw[6] == 2)
        #expect(abs(expected[6, default: 0] - 10.0 / 36.0) < 0.0001)
        #expect(expected[7] == nil)
    }
}

private extension Collection {
    var only: Element? { count == 1 ? first : nil }
}
