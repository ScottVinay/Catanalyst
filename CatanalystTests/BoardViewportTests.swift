import CoreGraphics
import Testing
@testable import Catanalyst

@Suite("Board viewport")
struct BoardViewportTests {
    private let phoneSize = CGSize(width: 400, height: 800)

    @Test("Pinching switches between fixed zoom levels")
    func switchesZoomLevels() {
        var viewport = BoardViewport()

        viewport.finishMagnification(1.2)
        #expect(viewport.zoom == .detail)
        #expect(viewport.scale == 1.5)

        viewport.finishMagnification(0.8)
        #expect(viewport.zoom == .overview)
        #expect(viewport.scale == 1)
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

        #expect(viewport.offset.width == 180)
        #expect(viewport.offset.height == -360)
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
}
