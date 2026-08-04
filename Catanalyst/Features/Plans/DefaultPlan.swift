import Foundation

nonisolated struct DefaultPlan: Equatable, Identifiable, Sendable {
    let name: String
    let systemImage: String
    let mean: Double
    let median: Double
    let percentile25: Double
    let percentile75: Double
    let turnProbabilities: [Int]

    var id: String { name }

    static let placeholders: [DefaultPlan] = [
        placeholder("Ore", systemImage: "mountain.2.fill", baseline: 3),
        placeholder("Brick", systemImage: "rectangle.split.3x1.fill", baseline: 2),
        placeholder("Wheat", systemImage: "leaf.fill", baseline: 2),
        placeholder("Sheep", systemImage: "cloud.fill", baseline: 2),
        placeholder("Wood", systemImage: "tree.fill", baseline: 2),
        placeholder("Road", systemImage: "road.lanes", baseline: 3),
        placeholder("Settlement", systemImage: "house.fill", baseline: 5),
        placeholder("City", systemImage: "building.2.fill", baseline: 7),
        placeholder("Dev Card", systemImage: "rectangle.stack.fill", baseline: 5)
    ]

    static func placeholders(for player: PlayerColor) -> [DefaultPlan] {
        placeholders.map { adjusted($0, for: player) }
    }

    static func placeholder(for customPlan: CustomPlan, player: PlayerColor) -> DefaultPlan {
        let baseline = switch customPlan.kind {
        case .cards: max(1, customPlan.cardCounts.values.reduce(0, +))
        case .constructions: 5
        }
        return adjusted(
            placeholder(customPlan.name, systemImage: customPlan.icon, baseline: baseline),
            for: player
        )
    }

    private static func placeholder(
        _ name: String,
        systemImage: String,
        baseline: Int
    ) -> DefaultPlan {
        DefaultPlan(
            name: name,
            systemImage: systemImage,
            mean: Double(baseline) + 0.4,
            median: Double(baseline),
            percentile25: Double(max(1, baseline - 1)),
            percentile75: Double(baseline + 2),
            turnProbabilities: (1...10).map { turn in
                let exponent = -0.75 * Double(turn - baseline)
                return Int((100 / (1 + exp(exponent))).rounded())
            }
        )
    }

    private static func adjusted(_ plan: DefaultPlan, for player: PlayerColor) -> DefaultPlan {
        let adjustment: Double = switch player {
        case .red: 0
        case .blue: 0.8
        case .white: -0.6
        case .orange: 1.4
        case .green: -1.0
        case .brown: 2.0
        }
        let midpoint = max(1, plan.median + adjustment)
        let median = midpoint.rounded()

        return DefaultPlan(
            name: plan.name,
            systemImage: plan.systemImage,
            mean: max(1, plan.mean + adjustment),
            median: median,
            percentile25: max(1, (median - 1).rounded()),
            percentile75: max(median, (median + 2).rounded()),
            turnProbabilities: (1...10).map { turn in
                let exponent = -0.75 * (Double(turn) - midpoint)
                return Int((100 / (1 + exp(exponent))).rounded())
            }
        )
    }
}
