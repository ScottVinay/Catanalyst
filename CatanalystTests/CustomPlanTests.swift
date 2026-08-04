import Foundation
import Testing
@testable import Catanalyst

@Suite("Custom plans")
struct CustomPlanTests {
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
}
