import Foundation

nonisolated enum ProductionResource: String, CaseIterable, Identifiable, Sendable {
    case all = "All"
    case brick = "Brick"
    case wood = "Lumber"
    case ore = "Ore"
    case wheat = "Grain"
    case sheep = "Wool"
    case paper = "Paper"
    case cloth = "Cloth"
    case coin = "Coin"

    var id: Self { self }

    static let individual: [ProductionResource] = [.brick, .wood, .ore, .wheat, .sheep]
    static let commodities: [ProductionResource] = [.paper, .cloth, .coin]
    static let citiesAndKnights: [ProductionResource] = individual + commodities

    var isCommodity: Bool { Self.commodities.contains(self) }

    var systemImage: String {
        switch self {
        case .all: "shippingbox.fill"
        case .brick: Terrain.brick.systemImage
        case .ore: Terrain.ore.systemImage
        case .wheat: Terrain.wheat.systemImage
        case .sheep: Terrain.wool.systemImage
        case .wood: Terrain.lumber.systemImage
        case .paper: "doc.fill"
        case .cloth: "square.grid.3x3.fill"
        case .coin: "circle.fill"
        }
    }

    var relatedResource: ProductionResource {
        switch self {
        case .paper: .wood
        case .cloth: .sheep
        case .coin: .ore
        default: self
        }
    }
}

nonisolated struct ProductionContribution: Equatable, Sendable {
    let player: PlayerColor
    let buildingID: BoardVertex
    let buildingType: Building
    let hexID: HexCoordinate
    let resource: ProductionResource
    let diceResult: Int
    let cardsProduced: Int
}

nonisolated struct ProductionDistribution: Equatable, Sendable {
    private(set) var probabilities: [Int: Double]

    init(probabilities: [Int: Double]) {
        self.probabilities = probabilities.filter { $0.value > 0 }
    }

    var mean: Double {
        probabilities.reduce(0) { $0 + Double($1.key) * $1.value }
    }

    func probability(of count: Int) -> Double { probabilities[count, default: 0] }

    func probability(atLeast count: Int) -> Double {
        probabilities.reduce(0) { $0 + ($1.key >= count ? $1.value : 0) }
    }
}

nonisolated enum ProductionMetrics {
    static let displayedDiceResults = [2, 3, 4, 5, 6, 8, 9, 10, 11, 12]

    static func contributions(snapshot: BoardSnapshot) -> [ProductionContribution] {
        snapshot.buildings.flatMap { vertex, building -> [ProductionContribution] in
            guard let player = snapshot.buildingOwners[vertex] else { return [] }
            return snapshot.tiles.flatMap { tile -> [ProductionContribution] in
                guard BoardGeometry.vertices(for: tile.coordinate).contains(vertex),
                      let resource = productionResource(for: tile.terrain),
                      let number = tile.number else { return [] }
                return productionOutputs(
                    resource: resource,
                    building: building,
                    citiesAndKnightsMode: snapshot.citiesAndKnightsMode
                ).map { outputResource, cardsProduced in
                    ProductionContribution(
                        player: player,
                        buildingID: vertex,
                        buildingType: building,
                        hexID: tile.coordinate,
                        resource: outputResource,
                        diceResult: number.rawValue,
                        cardsProduced: cardsProduced
                    )
                }
            }
        }
    }

    static func cardsProducedByDiceResultByResource(
        player: PlayerColor,
        snapshot: BoardSnapshot
    ) -> [ProductionResource: [Int: Int]] {
        let contributions = contributions(snapshot: snapshot)
        let resources = snapshot.citiesAndKnightsMode
            ? ProductionResource.citiesAndKnights
            : ProductionResource.individual
        return Dictionary(uniqueKeysWithValues: resources.map { resource in
            (resource, cardsProducedByDiceResult(
                resource: resource,
                player: player,
                contributions: contributions
            ))
        })
    }

    static func cardsProducedByDiceResult(
        resource: ProductionResource = .all,
        player: PlayerColor,
        snapshot: BoardSnapshot
    ) -> [Int: Int] {
        cardsProducedByDiceResult(
            resource: resource,
            player: player,
            contributions: contributions(snapshot: snapshot)
        )
    }

    static func expectedCardsByDiceResult(
        resource: ProductionResource = .all,
        player: PlayerColor,
        snapshot: BoardSnapshot
    ) -> [Int: Double] {
        let produced = cardsProducedByDiceResult(resource: resource, player: player, snapshot: snapshot)
        return Dictionary(uniqueKeysWithValues: displayedDiceResults.map { result in
            (result, Double(produced[result, default: 0]) * diceProbability(result))
        })
    }

    static func perRollDistribution(
        resource: ProductionResource,
        player: PlayerColor,
        snapshot: BoardSnapshot
    ) -> ProductionDistribution {
        let production = cardsProducedByDiceResult(resource: resource, player: player, snapshot: snapshot)
        var probabilities: [Int: Double] = [:]
        for result in 2...12 {
            let count = result == 7 ? 0 : production[result, default: 0]
            probabilities[count, default: 0] += diceProbability(result)
        }
        return ProductionDistribution(probabilities: probabilities)
    }

    static func roundDistributions(
        resource: ProductionResource,
        player: PlayerColor,
        snapshot: BoardSnapshot
    ) -> [ProductionDistribution] {
        let perRoll = perRollDistribution(resource: resource, player: player, snapshot: snapshot)
        var result: [ProductionDistribution] = []
        var current = ProductionDistribution(probabilities: [0: 1])
        for _ in 1...6 {
            current = convolve(current, perRoll)
            result.append(current)
        }
        return result
    }

    static func perRoundDistribution(
        resource: ProductionResource,
        player: PlayerColor,
        snapshot: BoardSnapshot
    ) -> ProductionDistribution {
        let rollCount = min(max(snapshot.activePlayers.count, 1), 6)
        return roundDistributions(resource: resource, player: player, snapshot: snapshot)[rollCount - 1]
    }

    static func meanPerRound(
        resource: ProductionResource,
        player: PlayerColor,
        snapshot: BoardSnapshot
    ) -> Double {
        perRoundDistribution(resource: resource, player: player, snapshot: snapshot).mean
    }

    static func roundsUntilOne(
        resource: ProductionResource,
        player: PlayerColor,
        snapshot: BoardSnapshot
    ) -> Double? {
        let successProbability = 1 - perRoundDistribution(
            resource: resource,
            player: player,
            snapshot: snapshot
        ).probability(of: 0)
        return successProbability > 0 ? 1 / successProbability : nil
    }

    static func cardsPerRoundBuckets(
        resource: ProductionResource,
        player: PlayerColor,
        snapshot: BoardSnapshot
    ) -> [Double] {
        let distribution = perRoundDistribution(resource: resource, player: player, snapshot: snapshot)
        return [
            distribution.probability(of: 0),
            distribution.probability(atLeast: 1),
            distribution.probability(atLeast: 2),
            distribution.probability(atLeast: 3),
            distribution.probability(atLeast: 4)
        ]
    }

    static func roundsPerCardBuckets(
        resource: ProductionResource,
        player: PlayerColor,
        snapshot: BoardSnapshot
    ) -> [Double] {
        let p0 = perRoundDistribution(resource: resource, player: player, snapshot: snapshot)
            .probability(of: 0)
        return [p0, pow(p0, 2), pow(p0, 3), pow(p0, 4)]
    }

    static func diceProbability(_ result: Int) -> Double {
        guard (2...12).contains(result) else { return 0 }
        return Double(6 - abs(7 - result)) / 36
    }

    private static func cardsProducedByDiceResult(
        resource: ProductionResource,
        player: PlayerColor,
        contributions: [ProductionContribution]
    ) -> [Int: Int] {
        contributions.reduce(into: [:]) { totals, contribution in
            guard contribution.player == player,
                  resource == .all || contribution.resource == resource else { return }
            totals[contribution.diceResult, default: 0] += contribution.cardsProduced
        }
    }

    private static func convolve(
        _ lhs: ProductionDistribution,
        _ rhs: ProductionDistribution
    ) -> ProductionDistribution {
        var probabilities: [Int: Double] = [:]
        for (leftCount, leftProbability) in lhs.probabilities {
            for (rightCount, rightProbability) in rhs.probabilities {
                probabilities[leftCount + rightCount, default: 0] += leftProbability * rightProbability
            }
        }
        return ProductionDistribution(probabilities: probabilities)
    }

    private static func productionResource(for terrain: Terrain) -> ProductionResource? {
        switch terrain {
        case .brick: .brick
        case .ore: .ore
        case .wheat: .wheat
        case .lumber: .wood
        case .wool: .sheep
        case .desert, .ocean: nil
        }
    }

    private static func productionOutputs(
        resource: ProductionResource,
        building: Building,
        citiesAndKnightsMode: Bool
    ) -> [(ProductionResource, Int)] {
        guard building == .city else { return [(resource, 1)] }
        guard citiesAndKnightsMode else { return [(resource, 2)] }
        switch resource {
        case .wood: return [(.wood, 1), (.paper, 1)]
        case .sheep: return [(.sheep, 1), (.cloth, 1)]
        case .ore: return [(.ore, 1), (.coin, 1)]
        default: return [(resource, 2)]
        }
    }
}
