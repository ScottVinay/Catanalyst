import CoreGraphics
import Testing
@testable import Catanalyst

@Suite("Radial picker geometry")
struct RadialPickerGeometryTests {
    private let center = CGPoint(x: 100, y: 100)
    private let hexSize: CGFloat = 40

    @Test("The first option is directly above the hex")
    func topOption() {
        let location = CGPoint(x: center.x, y: center.y - (hexSize * 1.55))
        #expect(RadialPickerGeometry.optionIndex(
            at: location,
            around: center,
            hexSize: hexSize,
            optionCount: 7
        ) == 0)
    }

    @Test("Releasing in the centre cancels selection")
    func centerCancels() {
        #expect(RadialPickerGeometry.optionIndex(
            at: center,
            around: center,
            hexSize: hexSize,
            optionCount: 7
        ) == nil)
    }

    @Test("Releasing beyond the wheel cancels selection")
    func outsideCancels() {
        let location = CGPoint(x: center.x, y: center.y - (hexSize * 3))
        #expect(RadialPickerGeometry.optionIndex(
            at: location,
            around: center,
            hexSize: hexSize,
            optionCount: 7
        ) == nil)
    }
}
