import CoreGraphics
import Testing
@testable import HexIQ

@Suite("Board viewport")
struct BoardViewportTests {
    private let phoneSize = CGSize(width: 400, height: 800)

    @Test("Pinching switches between fixed zoom levels")
    func switchesZoomLevels() {
        var viewport = BoardViewport()

        viewport.finishMagnification(1.2)
        #expect(viewport.zoom == .detail)
        #expect(viewport.scale == 1.85)

        viewport.finishMagnification(0.8)
        #expect(viewport.zoom == .overview)
        #expect(viewport.scale == 0.9)
    }

    @Test("Small magnification changes do not switch levels")
    func ignoresSmallMagnification() {
        var viewport = BoardViewport()

        viewport.finishMagnification(1.04)

        #expect(viewport.zoom == .overview)
    }

    @Test("Overview ignores single-finger panning")
    func overviewDoesNotPan() {
        var viewport = BoardViewport()

        viewport.finishPan(CGSize(width: 80, height: -120), in: phoneSize)

        #expect(viewport.offset == .zero)
    }

    @Test("Detail panning accumulates and remains bounded")
    func detailPanIsClamped() {
        var viewport = BoardViewport()
        viewport.finishMagnification(1.2)

        viewport.finishPan(CGSize(width: 500, height: -500), in: phoneSize)

        #expect(viewport.offset.width == 220)
        #expect(viewport.offset.height == -440)
    }

    @Test("A detail hex can be centred and overview resets the offset")
    func centersHexAndResets() {
        var viewport = BoardViewport()
        viewport.finishMagnification(1.2)

        viewport.center(on: CGPoint(x: 75, y: -110), in: phoneSize)
        #expect(viewport.offset == CGSize(width: -75, height: 110))

        viewport.finishMagnification(0.8)
        #expect(viewport.offset == .zero)
    }

    @Test("Overview is biased upward while Detail uses its pan offset")
    func displayOffsets() {
        var viewport = BoardViewport()

        #expect(viewport.displayOffset(in: phoneSize) == CGSize(width: 0, height: -28))

        viewport.finishMagnification(1.2)
        viewport.finishPan(CGSize(width: 30, height: 40), in: phoneSize)
        #expect(viewport.displayOffset(in: phoneSize) == CGSize(width: 30, height: 40))
    }

    @Test("Tap-to-centre follows the displayed point after every quarter turn", arguments: [0.0, 90, 180, 270, 450, -90])
    func centersRotatedHex(degrees: Double) {
        var viewport = BoardViewport()
        viewport.finishMagnification(1.2)
        let point = CGPoint(x: 75, y: -110)
        viewport.center(on: point, rotationDegrees: degrees, in: phoneSize)

        let expected: CGSize
        switch Int(degrees).quotientAndRemainder(dividingBy: 360).remainder {
        case 90: expected = CGSize(width: -110, height: -75)
        case 180: expected = CGSize(width: 75, height: -110)
        case 270, -90: expected = CGSize(width: 110, height: 75)
        default: expected = CGSize(width: -75, height: 110)
        }
        #expect(abs(viewport.offset.width - expected.width) < 0.001)
        #expect(abs(viewport.offset.height - expected.height) < 0.001)
    }
}
