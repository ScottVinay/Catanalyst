import SwiftUI

struct BoardStatsBar: View {
    let board: BoardState
    @Binding var isExpanded: Bool

    @State private var draggedCrownHolder: PlayerColor?
    @State private var crownTranslation = CGSize.zero
    @State private var roadCellFrames: [PlayerColor: CGRect] = [:]
    @State private var crownIsArmed = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.snappy) { isExpanded.toggle() }
            } label: {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                    .font(.caption.bold())
                    .frame(width: 54, height: 24)
                    .background(.bar, in: UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isExpanded ? "Hide player stats" : "Show player stats")
            .accessibilityIdentifier("statsBarToggle")

            if isExpanded {
                statsTable
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var statsTable: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            GridRow {
                Color.clear.frame(width: 112, height: 30)
                ForEach(board.activePlayers) { player in
                    Circle()
                        .fill(player.color)
                        .overlay(Circle().stroke(.black.opacity(0.5), lineWidth: 1))
                        .frame(width: 18, height: 18)
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel(player.displayName)
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
        .background(.bar)
        .coordinateSpace(.named("statsTable"))
        .onPreferenceChange(RoadCellFrameKey.self) { roadCellFrames = $0 }
        .accessibilityIdentifier("statsTable")
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
        HStack(spacing: 3) {
            Text("\(board.roadLength(for: player))")
            if board.longestRoadHolder == player {
                Image(systemName: "crown.fill")
                    .foregroundStyle(.yellow)
                    .symbolEffect(.wiggle, isActive: crownIsArmed)
                    .scaleEffect(draggedCrownHolder == player ? 1.22 : 1)
                    .offset(draggedCrownHolder == player ? crownTranslation : .zero)
                    .shadow(radius: draggedCrownHolder == player ? 4 : 0)
                    .zIndex(10)
                    .gesture(crownGesture(for: player))
                    .simultaneousGesture(crownPressFeedback)
                    .accessibilityLabel("Longest Road crown")
                    .accessibilityHint("Hold, then drag to a tied player's Road Length cell.")
                    .accessibilityIdentifier("longestRoadCrown-\(player.rawValue)")
            }
        }
        .font(.subheadline.monospacedDigit())
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

    private func crownGesture(for holder: PlayerColor) -> some Gesture {
        LongPressGesture(minimumDuration: 0.5, maximumDistance: 12)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named("statsTable")))
            .onChanged { value in
                switch value {
                case .first(true):
                    crownIsArmed = true
                case let .second(true, drag):
                    if draggedCrownHolder == nil {
                        draggedCrownHolder = holder
                        crownIsArmed = false
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    crownTranslation = drag?.translation ?? .zero
                default:
                    break
                }
            }
            .onEnded { value in
                defer {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.68)) {
                        draggedCrownHolder = nil
                        crownTranslation = .zero
                        crownIsArmed = false
                    }
                }
                guard case let .second(true, drag) = value, let location = drag?.location,
                      let target = roadCellFrames.first(where: { $0.value.contains(location) })?.key,
                      target != holder else { return }
                _ = board.reassignLongestRoad(to: target)
            }
    }

    private var crownPressFeedback: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if draggedCrownHolder == nil { crownIsArmed = true }
            }
            .onEnded { _ in
                if draggedCrownHolder == nil { crownIsArmed = false }
            }
    }
}

private struct RoadCellFrameKey: PreferenceKey {
    static let defaultValue: [PlayerColor: CGRect] = [:]

    static func reduce(value: inout [PlayerColor: CGRect], nextValue: () -> [PlayerColor: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}
