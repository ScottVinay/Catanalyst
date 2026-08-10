import CoreGraphics

nonisolated enum BoardZoomLevel: Equatable {
    case overview
    case detail
}

nonisolated struct BoardViewport: Equatable {
    private(set) var zoom: BoardZoomLevel = .overview
    private(set) var offset: CGSize = .zero

    var scale: CGFloat {
        zoom == .detail ? 1.85 : 1
    }

    func displayOffset(in containerSize: CGSize) -> CGSize {
        switch zoom {
        case .overview:
            CGSize(width: 0, height: -(containerSize.height * 0.035))
        case .detail:
            offset
        }
    }

    mutating func finishMagnification(_ magnification: CGFloat) {
        if magnification >= 1.08 {
            zoom = .detail
        } else if magnification <= 0.92 {
            zoom = .overview
            offset = .zero
        }
    }

    mutating func finishPan(_ translation: CGSize, in containerSize: CGSize) {
        guard zoom == .detail else { return }
        offset = clamped(
            CGSize(
                width: offset.width + translation.width,
                height: offset.height + translation.height
            ),
            in: containerSize
        )
    }

    mutating func center(on boardPoint: CGPoint, in containerSize: CGSize) {
        guard zoom == .detail else { return }
        offset = clamped(
            CGSize(width: -boardPoint.x, height: -boardPoint.y),
            in: containerSize
        )
    }

    private func clamped(_ proposedOffset: CGSize, in containerSize: CGSize) -> CGSize {
        let horizontalLimit = containerSize.width * 0.55
        let verticalLimit = containerSize.height * 0.55
        return CGSize(
            width: min(max(proposedOffset.width, -horizontalLimit), horizontalLimit),
            height: min(max(proposedOffset.height, -verticalLimit), verticalLimit)
        )
    }
}
