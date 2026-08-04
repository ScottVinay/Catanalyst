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
}
