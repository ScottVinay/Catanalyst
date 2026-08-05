import Foundation
import Testing
@testable import Catanalyst

@Suite("Custom plans")
struct CustomPlanTests {
    @Test("Placed construction feedback uses the shortened delay")
    func constructionPlacementDelay() {
        #expect(ConstructionPlacementTiming.confirmationMilliseconds == 650)
    }

    @Test("Plans retain their kind, player, and selected cards")
    func planContents() {
        let plan = CustomPlan(
            name: "City hand",
            kind: .cards,
            player: .blue,
            cardCounts: [.ore: 3, .hay: 2]
        )

        #expect(plan.name == "City hand")
        #expect(plan.kind == .cards)
        #expect(plan.player == .blue)
        #expect(plan.cardCounts[.ore] == 3)
        #expect(plan.cardCounts[.hay] == 2)
        #expect(plan.icon == "rectangle.stack.fill")
    }

    @Test("Custom plans serialize without losing card counts")
    func roundTrip() throws {
        let original = CustomPlan(
            name: "Road cards",
            kind: .cards,
            player: .orange,
            cardCounts: [.brick: 1, .wood: 1]
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CustomPlan.self, from: data)

        #expect(decoded == original)
    }

    @Test("Empty and negative card counts are discarded")
    func removesInvalidCounts() {
        let plan = CustomPlan(
            name: "Clean",
            kind: .cards,
            player: .red,
            cardCounts: [.brick: 0, .ore: -1, .wood: 2]
        )

        #expect(plan.cardCounts == [.wood: 2])
    }

    @Test("Each player sees only plans belonging to that colour")
    func plansAreIsolatedByPlayer() {
        let red = CustomPlan(name: "Red plan", kind: .cards, player: .red)
        let blue = CustomPlan(name: "Blue plan", kind: .constructions, player: .blue)
        let plans = [red, blue]

        #expect(CustomPlan.belonging(to: .red, in: plans) == [red])
        #expect(CustomPlan.belonging(to: .blue, in: plans) == [blue])
        #expect(CustomPlan.belonging(to: .green, in: plans).isEmpty)
    }

    @Test("All-player visibility preserves every owner and individual visibility filters")
    func allPlayerVisibility() {
        let plans = PlayerColor.allCases.enumerated().map { index, player in
            CustomPlan(name: "Plan \(index)", kind: .cards, player: player)
        }

        #expect(CustomPlan.visible(to: .red, includesAllPlayers: true, in: plans) == plans)
        for player in PlayerColor.allCases {
            let visible = CustomPlan.visible(to: player, includesAllPlayers: false, in: plans)
            #expect(visible.count == 1)
            #expect(visible.first?.player == player)
        }
    }

    @Test("Default names are numbered independently by kind and player")
    func defaultNames() {
        let plans = [
            CustomPlan(name: "Card plan 1", kind: .cards, player: .red),
            CustomPlan(name: "Card plan 3", kind: .cards, player: .red),
            CustomPlan(name: "Card plan 2 extra", kind: .cards, player: .red),
            CustomPlan(name: "Con plan 1", kind: .constructions, player: .red),
            CustomPlan(name: "Card plan 1", kind: .cards, player: .blue)
        ]

        #expect(CustomPlan.nextDefaultName(for: .cards, player: .red, in: plans) == "Card plan 2")
        #expect(CustomPlan.nextDefaultName(for: .constructions, player: .red, in: plans) == "Con plan 2")
        #expect(CustomPlan.nextDefaultName(for: .cards, player: .blue, in: plans) == "Card plan 2")
        #expect(CustomPlan.nextDefaultName(for: .constructions, player: .blue, in: plans) == "Con plan 1")
        #expect(CustomPlan.nextDefaultName(for: .cards, player: .green, in: plans) == "Card plan 1")
    }

    @Test("Ordered construction steps serialize with their locations")
    func constructionStepsRoundTrip() throws {
        let edge = try #require(BoardGeometry.standardEdges.first)
        let steps = [
            PlannedConstructionStep(kind: .settlement, location: .vertex(edge.start)),
            PlannedConstructionStep(kind: .road, location: .edge(edge))
        ]
        let plan = CustomPlan(
            name: "Opening",
            kind: .constructions,
            player: .red,
            constructionSteps: steps
        )

        let decoded = try JSONDecoder().decode(
            CustomPlan.self,
            from: JSONEncoder().encode(plan)
        )
        #expect(decoded == plan)
    }

    @Test("Earlier construction steps affect later placement")
    func projectsOrderedSteps() throws {
        let board = BoardState()
        let edge = try #require(BoardGeometry.standardEdges.first)
        let continuation = try #require(BoardGeometry.standardEdges.first {
            $0 != edge && [$0.start, $0.end].contains(edge.end)
        })
        let settlement = PlannedConstructionStep(
            kind: .settlement,
            location: .vertex(edge.start)
        )
        let firstRoad = PlannedConstructionStep(kind: .road, location: .edge(edge))

        let projected = board.projected(adding: [settlement, firstRoad], for: .red)

        #expect(projected.placeRoad(on: continuation, for: .red) == nil)
        #expect(projected.roads.contains(edge))
        #expect(projected.roads.contains(continuation))
        #expect(board.roads.isEmpty)
        #expect(board.buildings.isEmpty)
    }

    @Test("A later planned city upgrades an earlier planned settlement")
    func projectsCityUpgrade() throws {
        let board = BoardState()
        let vertex = try #require(BoardGeometry.standardVertices.first)
        let settlement = PlannedConstructionStep(kind: .settlement, location: .vertex(vertex))
        let city = PlannedConstructionStep(kind: .city, location: .vertex(vertex))

        let projected = board.projected(adding: [settlement, city], for: .red)

        #expect(projected.buildings[vertex] == .city)
        #expect(projected.owner(of: vertex) == .red)
        #expect(projected.buildings.count == 1)
        #expect(board.buildings.isEmpty)
    }

    @Test("Clear resets only the active plan content")
    func clearContents() throws {
        let edge = try #require(BoardGeometry.standardEdges.first)
        var cards = CustomPlan(
            name: "Cards",
            kind: .cards,
            player: .red,
            cardCounts: [.ore: 2]
        )
        var constructions = CustomPlan(
            name: "Build",
            kind: .constructions,
            player: .red,
            constructionSteps: [
                PlannedConstructionStep(kind: .road, location: .edge(edge))
            ]
        )

        cards.clearContents()
        constructions.clearContents()

        #expect(cards.cardCounts.isEmpty)
        #expect(cards.constructionSteps.isEmpty)
        #expect(constructions.constructionSteps.isEmpty)
        #expect(constructions.cardCounts.isEmpty)
    }

    @Test("Only the final construction step is removed")
    func removesLastStep() throws {
        let edge = try #require(BoardGeometry.standardEdges.first)
        let first = PlannedConstructionStep(kind: .settlement, location: .vertex(edge.start))
        let last = PlannedConstructionStep(kind: .road, location: .edge(edge))
        var plan = CustomPlan(
            name: "Build",
            kind: .constructions,
            player: .red,
            constructionSteps: [first, last]
        )

        plan.removeLastConstructionStep()

        #expect(plan.constructionSteps == [first])
    }

    @Test("Card mutations add and remove one copy without affecting construction plans")
    func cardMutations() {
        var cards = CustomPlan(name: "Cards", kind: .cards, player: .red)
        var construction = CustomPlan(name: "Build", kind: .constructions, player: .red)

        cards.addCard(.wood)
        cards.addCard(.wood)
        cards.removeCard(.wood)
        construction.addCard(.ore)
        construction.removeCard(.ore)

        #expect(cards.cardCounts == [.wood: 1])
        #expect(construction.cardCounts.isEmpty)
        cards.removeCard(.wood)
        #expect(cards.cardCounts.isEmpty)
    }

    @Test("Construction plans retain an overflowing ordered row fixture")
    func overflowingConstructionRows() throws {
        let edges = Array(BoardGeometry.standardEdges.prefix(12))
        #expect(edges.count == 12)
        let steps = edges.enumerated().map { index, edge in
            PlannedConstructionStep(
                kind: index.isMultiple(of: 3) ? .settlement : .road,
                location: index.isMultiple(of: 3) ? .vertex(edge.start) : .edge(edge)
            )
        }
        let plan = CustomPlan(
            name: "Long route",
            kind: .constructions,
            player: .red,
            constructionSteps: steps
        )

        #expect(plan.constructionSteps.count == 12)
        #expect(plan.constructionSteps.map(\.id).count == Set(plan.constructionSteps.map(\.id)).count)
    }
}
