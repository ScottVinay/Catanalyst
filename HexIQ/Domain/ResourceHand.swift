import Foundation

nonisolated enum ResourceCardCounts {
    static func sanitized(_ counts: [ResourceCard: Int]) -> [ResourceCard: Int] {
        counts.filter { $0.value > 0 }
    }

    static func add(_ resource: ResourceCard, to counts: inout [ResourceCard: Int]) {
        counts[resource, default: 0] += 1
    }

    static func remove(_ resource: ResourceCard, from counts: inout [ResourceCard: Int]) {
        guard let count = counts[resource] else { return }
        if count > 1 {
            counts[resource] = count - 1
        } else {
            counts.removeValue(forKey: resource)
        }
    }
}

nonisolated struct ResourceHand: Codable, Equatable, Sendable {
    private(set) var counts: [ResourceCard: Int]

    init(counts: [ResourceCard: Int] = [:]) {
        self.counts = ResourceCardCounts.sanitized(counts)
    }

    var isEmpty: Bool { counts.isEmpty }
    var totalCount: Int { counts.values.reduce(0, +) }

    subscript(resource: ResourceCard) -> Int {
        counts[resource, default: 0]
    }

    mutating func add(_ resource: ResourceCard) {
        ResourceCardCounts.add(resource, to: &counts)
    }

    mutating func remove(_ resource: ResourceCard) {
        ResourceCardCounts.remove(resource, from: &counts)
    }

    mutating func clear() {
        counts.removeAll()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        counts = ResourceCardCounts.sanitized(
            try container.decode([ResourceCard: Int].self)
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(counts)
    }
}
