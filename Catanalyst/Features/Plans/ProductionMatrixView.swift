import SwiftUI

struct ProductionMatrixView: View {
    let board: BoardState
    @State private var showsRoundsUntilOne = false

    private let resourceColumnWidth: CGFloat = 118
    private let metaHeaderHeight: CGFloat = 30
    private let columnHeaderHeight: CGFloat = 34
    private let rowHeight: CGFloat = 36

    var body: some View {
        GeometryReader { proxy in
            let valuesViewportWidth = max(0, proxy.size.width - resourceColumnWidth - 1)
            let playerColumnWidth = max(
                64,
                valuesViewportWidth / CGFloat(max(board.activePlayers.count, 1))
            )

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Color.clear
                        .frame(width: resourceColumnWidth, height: metaHeaderHeight)
                        .background(Color(uiColor: .systemBackground))
                    verticalDivider
                    metricHeader
                        .frame(width: valuesViewportWidth, height: metaHeaderHeight)
                }

                horizontalDivider

                HStack(spacing: 0) {
                    resourceColumn
                    verticalDivider
                    playerValues(
                        columnWidth: playerColumnWidth,
                        viewportWidth: valuesViewportWidth
                    )
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .background(Color(uiColor: .systemBackground))
            .animation(.easeInOut(duration: 0.2), value: showsRoundsUntilOne)
        }
        .contentShape(Rectangle())
        .simultaneousGesture(sectionSwipe)
        .padding(.horizontal)
        .accessibilityIdentifier("productionMatrix")
    }

    private var metricHeader: some View {
        ZStack {
            Text(
                showsRoundsUntilOne
                    ? "Avg rounds until one produced"
                    : "Avg production per round"
            )
            .lineLimit(1)
            .minimumScaleFactor(0.75)

            HStack {
                if showsRoundsUntilOne { sectionArrow }
                Spacer()
                if !showsRoundsUntilOne { sectionArrow }
            }
            .padding(.horizontal, 4)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
        .background(Color(uiColor: .systemBackground))
        .accessibilityIdentifier("productionMetaHeader")
    }

    private var sectionArrow: some View {
        Button {
            showsRoundsUntilOne.toggle()
        } label: {
            Image(systemName: showsRoundsUntilOne ? "chevron.left" : "chevron.right")
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(showsRoundsUntilOne ? "Show average production" : "Show average rounds")
        .accessibilityIdentifier("productionSectionArrow")
    }

    private var resourceColumn: some View {
        VStack(spacing: 0) {
            Text("Resource")
                .frame(width: resourceColumnWidth, height: columnHeaderHeight, alignment: .leading)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(ProductionResource.allCases) { resource in
                horizontalDivider
                Label(resource.rawValue, systemImage: resource.systemImage)
                    .font(.caption)
                    .lineLimit(1)
                    .frame(width: resourceColumnWidth, height: rowHeight, alignment: .leading)
                    .accessibilityIdentifier("productionRow-\(resource.rawValue)")
            }

            Spacer(minLength: 0)
        }
        .frame(width: resourceColumnWidth)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(uiColor: .systemBackground))
        .accessibilityIdentifier("productionResourceColumn")
    }

    private func playerValues(columnWidth: CGFloat, viewportWidth: CGFloat) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(board.activePlayers) { player in
                    VStack(spacing: 0) {
                        Text(player.displayName)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(player == .white ? Color.gray : player.color)
                            .frame(width: columnWidth, height: columnHeaderHeight)

                        ForEach(ProductionResource.allCases) { resource in
                            horizontalDivider
                            value(resource: resource, player: player)
                                .font(.subheadline.monospacedDigit())
                                .frame(width: columnWidth, height: rowHeight)
                        }

                        Spacer(minLength: 0)
                    }
                    .frame(width: columnWidth)
                    .frame(maxHeight: .infinity, alignment: .top)
                }
            }
        }
        .scrollIndicators(.hidden)
        .frame(width: viewportWidth)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(Color(uiColor: .systemBackground))
        .accessibilityIdentifier("productionValuesViewport")
    }

    private var sectionSwipe: some Gesture {
        DragGesture(minimumDistance: 30).onEnded { value in
            if value.translation.width < -30 { showsRoundsUntilOne = true }
            if value.translation.width > 30 { showsRoundsUntilOne = false }
        }
    }

    @ViewBuilder
    private func value(resource: ProductionResource, player: PlayerColor) -> some View {
        let mean = ProductionMetrics.meanPerRound(
            resource: resource,
            player: player,
            snapshot: board.snapshot
        )
        if showsRoundsUntilOne {
            if let rounds = ProductionMetrics.roundsUntilOne(meanPerRound: mean) {
                Text(rounds.formatted(.number.precision(.fractionLength(2))))
            } else {
                Text("—").foregroundStyle(.secondary)
            }
        } else {
            Text(mean.formatted(.number.precision(.fractionLength(2))))
        }
    }

    private var horizontalDivider: some View {
        Rectangle()
            .fill(tableLineColor)
            .frame(height: 1)
            .accessibilityHidden(true)
    }

    private var verticalDivider: some View {
        Rectangle()
            .fill(tableLineColor)
            .frame(width: 1)
            .accessibilityHidden(true)
    }

    private var tableLineColor: Color { Color.secondary.opacity(0.28) }
}
