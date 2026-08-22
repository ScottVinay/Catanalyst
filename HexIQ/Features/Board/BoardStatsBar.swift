import SwiftUI

struct BoardStatsBar: View {
    private let tableHeight: CGFloat = 120
    private let tabHeight: CGFloat = 24

    let board: BoardState
    @Binding var isExpanded: Bool

    @State private var draggedCrownHolder: PlayerColor?
    @State private var crownTranslation = CGSize.zero
    @State private var roadCellFrames: [PlayerColor: CGRect] = [:]
    @State private var crownIsArmed = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                isExpanded.toggle()
            } label: {
                Image(systemName: "chevron.up")
                    .font(.caption.bold())
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .frame(width: 54, height: tabHeight)
                    .background(.bar, in: UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isExpanded ? "Hide player stats" : "Show player stats")
            .accessibilityIdentifier("statsBarToggle")

            statsTable
                .frame(height: tableHeight)
                .accessibilityHidden(!isExpanded)
        }
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
        ZStack {
            Text("\(board.roadLength(for: player))")
                .frame(maxWidth: .infinity)
            if board.longestRoadHolder == player {
                HStack {
                    Spacer()
                    Image(systemName: "road.lanes")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 24, height: 24)
                        .background(Color.yellow, in: Circle())
                        .overlay(Circle().stroke(.black.opacity(0.35), lineWidth: 1))
                        .symbolEffect(.wiggle, isActive: crownIsArmed)
                        .scaleEffect(draggedCrownHolder == player ? 1.22 : 1)
                        .offset(draggedCrownHolder == player ? crownTranslation : .zero)
                        .shadow(radius: draggedCrownHolder == player ? 4 : 0)
                        .zIndex(10)
                        .gesture(crownGesture(for: player))
                        .simultaneousGesture(crownPressFeedback)
                        .accessibilityLabel("Longest Road badge")
                        .accessibilityHint("Hold, then drag to a tied player's Road Length cell.")
                        .accessibilityIdentifier("longestRoadCrown-\(player.rawValue)")
                }
                .padding(.trailing, 4)
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
