import Testing
@testable import Catanalyst

@Suite("Default plan placeholders")
struct DefaultPlanTests {
    @Test("Default plans match the fixed design order")
    func fixedPlans() {
        #expect(DefaultPlan.placeholders.map(\.name) == [
            "Ore", "Brick", "Wheat", "Sheep", "Wood", "Road",
            "Settlement", "City", "Development Card"
        ])
    }

    @Test("Every plan has probabilities for turns one through ten")
    func probabilityColumns() {
        #expect(DefaultPlan.placeholders.allSatisfy { plan in
            plan.turnProbabilities.count == 10
                && plan.turnProbabilities.allSatisfy { 0...100 ~= $0 }
        })
    }

    @Test("Completion probabilities are cumulative")
    func cumulativeProbabilities() {
        #expect(DefaultPlan.placeholders.allSatisfy { plan in
            zip(plan.turnProbabilities, plan.turnProbabilities.dropFirst())
                .allSatisfy { earlier, later in later >= earlier }
        })
    }
}
