import CoreGraphics
import Testing
@testable import HexIQ

@Suite("Radial picker geometry")
struct RadialPickerGeometryTests {
    @Test("Terrain picker stacks ocean beyond desert and retains outer ocean selection")
    func stackedOceanSelection() {
        let center = CGPoint(x: 100, y: 100)
        let hexSize: CGFloat = 40
        let desertAngle = -Double.pi / 2 + 5 * 2 * Double.pi / 6
        func point(radiusScale: CGFloat) -> CGPoint {
            CGPoint(
                x: center.x + cos(desertAngle) * hexSize * radiusScale,
                y: center.y + sin(desertAngle) * hexSize * radiusScale
            )
        }

        #expect(RadialPickerGeometry.terrainOptionIndex(
            at: point(radiusScale: 1.4), around: center, hexSize: hexSize
        ) == 5)
        #expect(RadialPickerGeometry.terrainOptionIndex(
            at: point(radiusScale: 2.0), around: center, hexSize: hexSize
        ) == 6)
        #expect(RadialPickerGeometry.terrainOptionIndex(
            at: point(radiusScale: 4.0), around: center, hexSize: hexSize
        ) == 6)
    }

    private let center = CGPoint(x: 100, y: 100)
    private let hexSize: CGFloat = 40

    @Test("The first option is directly above the hex")
    func topOption() {
        let location = CGPoint(x: center.x, y: center.y - (hexSize * 1.4))
        #expect(RadialPickerGeometry.optionIndex(
            at: location,
            around: center,
            hexSize: hexSize,
            optionCount: 7
        ) == 0)
    }

    @Test("Overview opens immediately while Detail preserves pan arbitration")
    func zoomDependentTiming() {
        #expect(BoardHexEditGestureTiming.holdDuration(for: .overview) == 0)
        #expect(BoardHexEditGestureTiming.holdDuration(for: .detail) == 0.3)
    }

    @Test("All seven terrain ring segment centres map to their exact index")
    func sevenEqualSegments() {
        for index in 0..<7 {
            let angle = (-Double.pi / 2) + (2 * Double.pi * Double(index) / 7)
            let location = CGPoint(
                x: center.x + CGFloat(cos(angle)) * hexSize * 1.4,
                y: center.y + CGFloat(sin(angle)) * hexSize * 1.4
            )
            #expect(RadialPickerGeometry.optionIndex(
                at: location,
                around: center,
                hexSize: hexSize,
                optionCount: 7
            ) == index)
        }
    }

    @Test("Number ring supports every existing number and remove segment")
    func numberSegments() {
        for index in 0..<11 {
            let angle = (-Double.pi / 2) + (2 * Double.pi * Double(index) / 11)
            let location = CGPoint(
                x: center.x + CGFloat(cos(angle)) * hexSize * 1.4,
                y: center.y + CGFloat(sin(angle)) * hexSize * 1.4
            )
            #expect(RadialPickerGeometry.optionIndex(
                at: location,
                around: center,
                hexSize: hexSize,
                optionCount: 11
            ) == index)
        }
    }

    @Test("Releasing between the hex and ring cancels selection")
    func innerGapCancels() {
        let location = CGPoint(x: center.x, y: center.y - hexSize)
        #expect(RadialPickerGeometry.optionIndex(
            at: location,
            around: center,
            hexSize: hexSize,
            optionCount: 7
        ) == nil)
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

    @Test("Dragging beyond the wheel preserves angular selection")
    func outsidePreservesSelection() {
        let location = CGPoint(x: center.x, y: center.y - (hexSize * 3))
        #expect(RadialPickerGeometry.optionIndex(
            at: location,
            around: center,
            hexSize: hexSize,
            optionCount: 7
        ) == 0)
    }
}
