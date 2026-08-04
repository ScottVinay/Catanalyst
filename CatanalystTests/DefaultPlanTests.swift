import Testing
@testable import Catanalyst

@Suite("Default plan placeholders")
struct DefaultPlanTests {
    @Test("Default plans match the fixed design order")
    func fixedPlans() {
        #expect(DefaultPlan.placeholders.map(\.name) == [
            "Ore", "Brick", "Wheat", "Sheep", "Wood", "Road",
            "Settlement", "City", "Dev Card"
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

    @Test("Placeholder statistics respond to selected player")
    func selectedPlayerChangesPlaceholders() {
        #expect(DefaultPlan.placeholders(for: .red) != DefaultPlan.placeholders(for: .blue))
        #expect(DefaultPlan.placeholders(for: .red).map(\.name) == DefaultPlan.placeholders(for: .blue).map(\.name))

        let profiles = PlayerColor.allCases.map { player in
            DefaultPlan.placeholders(for: player)[0]
        }
        #expect(Set(profiles.map(\.mean)).count == PlayerColor.allCases.count)
        #expect(profiles.allSatisfy { plan in
            plan.percentile25 <= plan.median
                && plan.median <= plan.percentile75
                && zip(plan.turnProbabilities, plan.turnProbabilities.dropFirst())
                    .allSatisfy { $1 >= $0 }
        })
    }
}
