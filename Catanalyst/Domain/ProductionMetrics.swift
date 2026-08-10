import Foundation

nonisolated enum ProductionResource: String, CaseIterable, Identifiable, Sendable {
    case all = "All"
    case brick = "Brick"
    case ore = "Ore"
    case wheat = "Wheat"
    case sheep = "Sheep"
    case wood = "Wood"

    var id: Self { self }

    var systemImage: String {
        switch self {
        case .all: "shippingbox.fill"
        case .brick: Terrain.brick.systemImage
        case .ore: Terrain.ore.systemImage
        case .wheat: Terrain.wheat.systemImage
        case .sheep: Terrain.wool.systemImage
        case .wood: Terrain.lumber.systemImage
        }
    }
}

nonisolated enum ProductionMetrics {
    static func meanPerRound(
        resource: ProductionResource,
        player: PlayerColor,
        snapshot: BoardSnapshot
    ) -> Double {
        if resource == .all {
            return ProductionResource.allCases.dropFirst().reduce(0) {
                $0 + meanPerRound(resource: $1, player: player, snapshot: snapshot)
            }
        }
        let rollsPerRound = Double(snapshot.activePlayers.count)
        return snapshot.buildings.reduce(0) { total, entry in
            let (vertex, building) = entry
            guard snapshot.buildingOwners[vertex] == player else { return total }
            let multiplier = building == .city ? 2.0 : 1.0
            let adjacent = snapshot.tiles.filter { tile in
                BoardGeometry.vertices(for: tile.coordinate).contains(vertex)
            }
            return total + adjacent.reduce(0) { subtotal, tile in
                guard productionResource(for: tile.terrain) == resource, let number = tile.number else {
                    return subtotal
                }
                return subtotal + Double(number.pipCount) / 36.0 * multiplier * rollsPerRound
            }
        }
    }

    static func roundsUntilOne(meanPerRound: Double) -> Double? {
        meanPerRound > 0 ? 1 / meanPerRound : nil
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
}
