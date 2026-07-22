import CoreGraphics

nonisolated enum BoardGeometry {
    private static let cornerOffsets = [
        BoardVertex(x: 0, y: -2),
        BoardVertex(x: 1, y: -1),
        BoardVertex(x: 1, y: 1),
        BoardVertex(x: 0, y: 2),
        BoardVertex(x: -1, y: 1),
        BoardVertex(x: -1, y: -1),
    ]

    static func centerLattice(for coordinate: HexCoordinate) -> BoardVertex {
        BoardVertex(x: (2 * coordinate.q) + coordinate.r, y: 3 * coordinate.r)
    }

    static func vertices(for coordinate: HexCoordinate) -> [BoardVertex] {
        let center = centerLattice(for: coordinate)
        return cornerOffsets.map {
            BoardVertex(x: center.x + $0.x, y: center.y + $0.y)
        }
    }

    static func edges(for coordinate: HexCoordinate) -> [BoardEdge] {
        let corners = vertices(for: coordinate)
        return corners.indices.map {
            BoardEdge(corners[$0], corners[($0 + 1) % corners.count])
        }
    }

    static var standardVertices: [BoardVertex] {
        Array(Set(HexCoordinate.standardBoard.flatMap(vertices))).sorted()
    }

    static var standardEdges: [BoardEdge] {
        Array(Set(HexCoordinate.standardBoard.flatMap(edges))).sorted { $0.id < $1.id }
    }

    static func point(for vertex: BoardVertex, hexSize: CGFloat, origin: CGPoint) -> CGPoint {
        CGPoint(
            x: origin.x + CGFloat(vertex.x) * sqrt(3) * hexSize / 2,
            y: origin.y + CGFloat(vertex.y) * hexSize / 2
        )
    }

    static func center(for coordinate: HexCoordinate, hexSize: CGFloat, origin: CGPoint) -> CGPoint {
        point(for: centerLattice(for: coordinate), hexSize: hexSize, origin: origin)
    }
}
