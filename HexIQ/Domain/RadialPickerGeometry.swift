import CoreGraphics
import Foundation

nonisolated enum BoardHexEditGestureTiming {
    static func holdDuration(for zoom: BoardZoomLevel) -> TimeInterval {
        zoom == .overview ? 0 : 0.3
    }
}

nonisolated enum RadialPickerGeometry {
    static let innerRadiusScale: CGFloat = 1.05
    static let outerRadiusScale: CGFloat = 1.78

    static func optionIndex(
        at location: CGPoint,
        around center: CGPoint,
        hexSize: CGFloat,
        optionCount: Int
    ) -> Int? {
        guard optionCount > 0 else { return nil }

        let dx = location.x - center.x
        let dy = location.y - center.y
        let distance = hypot(dx, dy)
        guard distance >= hexSize * innerRadiusScale else { return nil }

        let step = (2 * Double.pi) / Double(optionCount)
        var relativeAngle = atan2(dy, dx) + (Double.pi / 2)
        if relativeAngle < 0 { relativeAngle += 2 * Double.pi }
        return Int((relativeAngle / step).rounded()) % optionCount
    }
}
