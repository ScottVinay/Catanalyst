import CoreGraphics
import Foundation

nonisolated enum RadialPickerGeometry {
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
        let wheelRadius = hexSize * 1.55
        guard distance >= hexSize * 0.65,
              distance <= wheelRadius + (hexSize * 0.65) else { return nil }

        let step = (2 * Double.pi) / Double(optionCount)
        var relativeAngle = atan2(dy, dx) + (Double.pi / 2)
        if relativeAngle < 0 { relativeAngle += 2 * Double.pi }
        return Int((relativeAngle / step).rounded()) % optionCount
    }
}
