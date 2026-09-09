import SwiftUI

struct BoardStatsBar: View {
    private let tableHeight: CGFloat = 120
    private let tabHeight: CGFloat = 24

    let board: BoardState
    @Binding var isExpanded: Bool

    @State private var draggedRingHolder: PlayerColor?
    @State private var ringTranslation = CGSize.zero
    @State private var roadCellFrames: [PlayerColor: CGRect] = [:]
    @State private var ringIsArmed = false

    var body: some View {
        // One continuous background fixes the tab's lower edge to the table's
        // upper edge. The complete surface has just one animated translation.
        StatsDrawerShape(tabWidth: 54, tabHeight: tabHeight)
            .fill(.bar)
            .overlay(alignment: .top) {
                Button {
                    isExpanded.toggle()
                } label: {
                    StatsChevron(pointsDown: isExpanded)
                        .stroke(.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .frame(width: 10, height: 5)
                        .frame(width: 54, height: tabHeight)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isExpanded ? "Hide player stats" : "Show player stats")
                .accessibilityIdentifier("statsBarToggle")
            }
            .overlay(alignment: .bottom) {
                statsTable
                    .frame(height: tableHeight)
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("statsTable")
                    .accessibilityHidden(!isExpanded)
                    .allowsHitTesting(isExpanded)
            }
            .frame(height: tableHeight + tabHeight)
            .offset(y: isExpanded ? 0 : tableHeight)
            .frame(height: tableHeight + tabHeight, alignment: .top)
            .clipped()
            .animation(.smooth(duration: 0.28), value: isExpanded)
    }

    private var statsTable: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            GridRow {
                Color.clear.frame(width: 112, height: 30)
                ForEach(board.activePlayers) { player in
                    Text(player.displayName)
                        .font(.caption.bold())
                        .foregroundStyle(player.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier("statsPlayerHeader-\(player.rawValue)")
                }
            }
            Divider()
            statRow(label: "Victory Points", systemImage: "sunrise.circle.fill") { player in
                Text("\(board.victoryPoints(for: player))")
                    .accessibilityIdentifier("victoryPoints-\(player.rawValue)")
            }
            Divider()
            statRow(label: "Road Length", systemImage: "road.lanes") { player in
                roadLengthCell(for: player)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .coordinateSpace(.named("statsTable"))
        .onPreferenceChange(RoadCellFrameKey.self) { roadCellFrames = $0 }
    }

    private func statRow<Content: View>(
        label: String,
        systemImage: String,
        @ViewBuilder content: @escaping (PlayerColor) -> Content
    ) -> some View {
        GridRow {
            Label(label, systemImage: systemImage)
                .font(.caption.weight(.medium))
                .frame(width: 112, alignment: .leading)
                .frame(minHeight: 38)
            ForEach(board.activePlayers) { player in
                content(player)
                    .frame(maxWidth: .infinity, minHeight: 38)
            }
        }
    }

    private func roadLengthCell(for player: PlayerColor) -> some View {
        ZStack {
            Text("\(board.roadLength(for: player))")
                .frame(maxWidth: .infinity)
            if board.longestRoadHolder == player {
                Circle()
                    .strokeBorder(Color.yellow, lineWidth: 3)
                    .frame(width: 30, height: 30)
                    .contentShape(Circle())
                    .rotationEffect(.degrees(ringIsArmed ? 4 : 0))
                    .offset(x: ringIsArmed ? 1.5 : 0)
                    .animation(
                        ringIsArmed ? .easeInOut(duration: 0.08).repeatForever(autoreverses: true) : .default,
                        value: ringIsArmed
                    )
                    .scaleEffect(draggedRingHolder == player ? 1.22 : 1)
                    .offset(draggedRingHolder == player ? ringTranslation : .zero)
                    .shadow(radius: draggedRingHolder == player ? 4 : 0)
                    .zIndex(10)
                    .gesture(ringGesture(for: player))
                    .simultaneousGesture(ringPressFeedback)
                    .accessibilityLabel("Longest Road ring")
                    .accessibilityValue("\(board.roadLength(for: player))")
                    .accessibilityHint("Hold, then drag to a tied player's Road Length cell.")
                    .accessibilityIdentifier("longestRoadCrown-\(player.rawValue)")
            }
        }
        .font(.subheadline.monospacedDigit())
        .zIndex(draggedRingHolder == player ? 10 : 0)
        .contentShape(Rectangle())
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: RoadCellFrameKey.self,
                    value: [player: proxy.frame(in: .named("statsTable"))]
                )
            }
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("roadLength-\(player.rawValue)")
    }

    private func ringGesture(for holder: PlayerColor) -> some Gesture {
        LongPressGesture(minimumDuration: 0.5, maximumDistance: 12)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named("statsTable")))
            .onChanged { value in
                switch value {
                case .first(true):
                    ringIsArmed = true
                case let .second(true, drag):
                    if draggedRingHolder == nil {
                        draggedRingHolder = holder
                        ringIsArmed = false
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    ringTranslation = drag?.translation ?? .zero
                default:
                    break
                }
            }
            .onEnded { value in
                defer {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.68)) {
                        draggedRingHolder = nil
                        ringTranslation = .zero
                        ringIsArmed = false
                    }
                }
                guard case let .second(true, drag) = value, let location = drag?.location,
                      let target = roadCellFrames.first(where: { $0.value.contains(location) })?.key,
                      target != holder else { return }
                _ = board.reassignLongestRoad(to: target)
            }
    }

    private var ringPressFeedback: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if draggedRingHolder == nil { ringIsArmed = true }
            }
            .onEnded { _ in
                if draggedRingHolder == nil { ringIsArmed = false }
            }
    }
}

private struct StatsDrawerShape: Shape {
    let tabWidth: CGFloat
    let tabHeight: CGFloat

    func path(in rect: CGRect) -> Path {
        let left = rect.midX - tabWidth / 2
        let right = rect.midX + tabWidth / 2
        let radius: CGFloat = 10
        return Path { path in
            path.move(to: CGPoint(x: rect.minX, y: tabHeight))
            path.addLine(to: CGPoint(x: left, y: tabHeight))
            path.addLine(to: CGPoint(x: left, y: radius))
            path.addQuadCurve(to: CGPoint(x: left + radius, y: 0), control: CGPoint(x: left, y: 0))
            path.addLine(to: CGPoint(x: right - radius, y: 0))
            path.addQuadCurve(to: CGPoint(x: right, y: radius), control: CGPoint(x: right, y: 0))
            path.addLine(to: CGPoint(x: right, y: tabHeight))
            path.addLine(to: CGPoint(x: rect.maxX, y: tabHeight))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

private struct StatsChevron: Shape {
    let pointsDown: Bool

    func path(in rect: CGRect) -> Path {
        Path { path in
            let outerY = pointsDown ? rect.minY : rect.maxY
            let centreY = pointsDown ? rect.maxY : rect.minY
            path.move(to: CGPoint(x: rect.minX, y: outerY))
            path.addLine(to: CGPoint(x: rect.midX, y: centreY))
            path.addLine(to: CGPoint(x: rect.maxX, y: outerY))
        }
    }
}

private struct RoadCellFrameKey: PreferenceKey {
    static let defaultValue: [PlayerColor: CGRect] = [:]

    static func reduce(value: inout [PlayerColor: CGRect], nextValue: () -> [PlayerColor: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}
