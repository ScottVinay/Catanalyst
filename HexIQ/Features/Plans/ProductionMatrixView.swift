import SwiftUI

private enum ProductionDisplayMode: String, CaseIterable, Identifiable {
    case cards = "Cards per round"
    case rounds = "Rounds per card"

    var id: Self { self }
}

struct ProductionMatrixView: View {
    let board: BoardState

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 16) {
                DetailedProductionView(board: board)
                ProductionBalanceView(board: board)
                DiceRelianceView(board: board)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
        .accessibilityIdentifier("productionMatrix")
    }
}

private struct DetailedProductionView: View {
    let board: BoardState
    @State private var mode = ProductionDisplayMode.cards
    @State private var expandedResources: Set<ProductionResource> = []
    @State private var showsHelp = false

    private let resourceColumnWidth: CGFloat = 118
    private let metricHeaderHeight: CGFloat = 30
    private let columnHeaderHeight: CGFloat = 34
    private let rowHeight: CGFloat = 38
    private let subrowHeight: CGFloat = 32

    var body: some View {
        VStack(spacing: 0) {
            elementHeader
            controls
            Divider()
            GeometryReader { proxy in
                let viewportWidth = max(0, proxy.size.width - resourceColumnWidth - 1)
                let playerWidth = max(72, viewportWidth / CGFloat(max(board.activePlayers.count, 1)))
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Color.clear.frame(width: resourceColumnWidth, height: metricHeaderHeight)
                        verticalDivider
                        Text(mode.rawValue)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: viewportWidth, height: metricHeaderHeight)
                            .accessibilityIdentifier("productionMetaHeader")
                    }
                    horizontalDivider
                    HStack(spacing: 0) {
                        resourceColumn
                        verticalDivider
                        playerValues(columnWidth: playerWidth, viewportWidth: viewportWidth)
                    }
                }
            }
            .frame(height: tableHeight)
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(tableLineColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .alert("Detailed production analysis", isPresented: $showsHelp) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Cards per round shows the mean average of how many of each card you typically get in one round (from your turn back round to your turn again).\n\nRounds per card shows how many rounds you typically need to wait until you get at least one of the given card. This does not account for trades, robber, or held cards.\n\nTap any resource to see a detailed breakdown of this average.")
        }
        .accessibilityIdentifier("detailedProductionAnalysis")
    }

    private var elementHeader: some View {
        HStack {
            Text("Detailed production analysis")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(height: 38)
    }

    private var controls: some View {
        HStack(spacing: 8) {
            Picker("Production metric", selection: $mode) {
                ForEach(ProductionDisplayMode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("productionMetricPicker")

            Button { showsHelp = true } label: {
                Image(systemName: "questionmark.circle.fill")
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Detailed production help")
            .accessibilityIdentifier("detailedProductionHelp")
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 10)
    }

    private var resourceColumn: some View {
        VStack(spacing: 0) {
            Text("Resource")
                .frame(width: resourceColumnWidth, height: columnHeaderHeight, alignment: .leading)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 10)

            ForEach(ProductionResource.allCases) { resource in
                horizontalDivider
                resourceButton(resource)
                if expandedResources.contains(resource) {
                    ForEach(Array(subrowLabels.enumerated()), id: \.offset) { _, label in
                        horizontalDivider
                        Text(label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: resourceColumnWidth, height: subrowHeight, alignment: .leading)
                            .padding(.leading, 28)
                    }
                }
            }
        }
        .frame(width: resourceColumnWidth)
        .accessibilityIdentifier("productionResourceColumn")
    }

    private func resourceButton(_ resource: ProductionResource) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                if expandedResources.contains(resource) {
                    expandedResources.remove(resource)
                } else {
                    expandedResources.insert(resource)
                }
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: resource.systemImage)
                    .symbolRenderingMode(resource == .wood ? .palette : .monochrome)
                    .foregroundStyle(resourceColor(resource), resource == .wood ? .brown : resourceColor(resource))
                    .frame(width: 18)
                Text(resource.rawValue)
                    .font(.caption)
                    .foregroundStyle(.primary)
                Spacer(minLength: 2)
                Image(systemName: expandedResources.contains(resource) ? "chevron.up" : "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .frame(width: resourceColumnWidth, height: rowHeight)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("productionRow-\(resource.rawValue)")
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
                            mainValue(resource: resource, player: player)
                                .frame(width: columnWidth, height: rowHeight)
                            if expandedResources.contains(resource) {
                                ForEach(Array(bucketValues(resource: resource, player: player).enumerated()), id: \.offset) { _, value in
                                    horizontalDivider
                                    Text(value, format: .percent.precision(.fractionLength(1)))
                                        .font(.caption2.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                        .frame(width: columnWidth, height: subrowHeight)
                                }
                            }
                        }
                    }
                    .frame(width: columnWidth)
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .frame(width: viewportWidth, alignment: .leading)
        .accessibilityIdentifier("productionValuesViewport")
    }

    @ViewBuilder
    private func mainValue(resource: ProductionResource, player: PlayerColor) -> some View {
        if mode == .cards {
            Text(
                ProductionMetrics.meanPerRound(resource: resource, player: player, snapshot: board.snapshot),
                format: .number.precision(.fractionLength(2))
            )
            .font(.subheadline.monospacedDigit())
        } else if let rounds = ProductionMetrics.roundsUntilOne(
            resource: resource, player: player, snapshot: board.snapshot
        ) {
            Text(rounds, format: .number.precision(.fractionLength(2)))
                .font(.subheadline.monospacedDigit())
        } else {
            Text("—").font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private func bucketValues(resource: ProductionResource, player: PlayerColor) -> [Double] {
        switch mode {
        case .cards:
            ProductionMetrics.cardsPerRoundBuckets(resource: resource, player: player, snapshot: board.snapshot)
        case .rounds:
            ProductionMetrics.roundsPerCardBuckets(resource: resource, player: player, snapshot: board.snapshot)
        }
    }

    private var subrowLabels: [String] {
        mode == .cards
            ? ["0 cards", "1 card", "2 cards", "3 cards", "4+ cards"]
            : ["1 round", "2 rounds", "3 rounds", "4+ rounds"]
    }

    private var tableHeight: CGFloat {
        metricHeaderHeight + 1 + columnHeaderHeight
            + CGFloat(ProductionResource.allCases.count) * (rowHeight + 1)
            + CGFloat(expandedResources.count * subrowLabels.count) * (subrowHeight + 1)
    }

    private var horizontalDivider: some View {
        Rectangle().fill(tableLineColor).frame(height: 1).accessibilityHidden(true)
    }

    private var verticalDivider: some View {
        Rectangle().fill(tableLineColor).frame(width: 1).accessibilityHidden(true)
    }

    private var tableLineColor: Color { Color.secondary.opacity(0.25) }
}

private struct ProductionBalanceView: View {
    let board: BoardState
    @State private var selectedPlayers: Set<PlayerColor> = []

    private let resources = ProductionResource.individual

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Production balance")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            playerPicker

            ProductionRadarChart(
                players: visiblePlayers,
                resources: resources,
                values: productionValues,
                maximum: maximumProduction
            )
            .frame(height: 300)
            .accessibilityIdentifier("productionBalanceChart")
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.25)))
        .onAppear {
            if selectedPlayers.isEmpty { selectedPlayers = Set(board.activePlayers) }
        }
        .onChange(of: board.activePlayers) { _, players in
            selectedPlayers.formIntersection(players)
        }
        .accessibilityIdentifier("productionBalance")
    }

    private var playerPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(board.activePlayers) { player in
                    Button {
                        if selectedPlayers.contains(player) {
                            selectedPlayers.remove(player)
                        } else {
                            selectedPlayers.insert(player)
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: selectedPlayers.contains(player) ? "checkmark.circle.fill" : "circle")
                            Text(player.displayName)
                        }
                        .font(.caption)
                        .foregroundStyle(player == .white ? Color.gray : player.color)
                        .padding(.horizontal, 8)
                        .frame(height: 30)
                        .background(Color.secondary.opacity(0.1), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("productionBalancePlayer-\(player.rawValue)")
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private var visiblePlayers: [PlayerColor] {
        board.activePlayers.filter(selectedPlayers.contains)
    }

    private var productionValues: [PlayerColor: [Double]] {
        Dictionary(uniqueKeysWithValues: board.activePlayers.map { player in
            (player, resources.map {
                ProductionMetrics.meanPerRound(resource: $0, player: player, snapshot: board.snapshot)
            })
        })
    }

    private var maximumProduction: Double {
        max(productionValues.values.flatMap { $0 }.max() ?? 0, 0.000_001)
    }
}

private struct ProductionRadarChart: View {
    let players: [PlayerColor]
    let resources: [ProductionResource]
    let values: [PlayerColor: [Double]]
    let maximum: Double

    var body: some View {
        GeometryReader { proxy in
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let radius = min(proxy.size.width, proxy.size.height) * 0.34
            ZStack {
                Canvas { context, _ in
                    for ring in 1...4 {
                        context.stroke(polygon(center: center, radius: radius * CGFloat(ring) / 4), with: .color(.secondary.opacity(0.2)))
                    }
                    for index in resources.indices {
                        var spoke = Path()
                        spoke.move(to: center)
                        spoke.addLine(to: point(index: index, value: 1, center: center, radius: radius))
                        context.stroke(spoke, with: .color(.secondary.opacity(0.2)))
                    }
                    for player in players {
                        let path = valuePolygon(values[player] ?? [], center: center, radius: radius)
                        context.fill(path, with: .color(player.color.opacity(0.12)))
                        context.stroke(path, with: .color(player.color), lineWidth: 2)
                    }
                }

                ForEach(Array(resources.enumerated()), id: \.element) { index, resource in
                    let labelPoint = point(index: index, value: 1.28, center: center, radius: radius)
                    Label(resource.rawValue, systemImage: resource.systemImage)
                        .font(.caption2)
                        .foregroundStyle(resourceColor(resource))
                        .position(labelPoint)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Production balance radial plot")
        .accessibilityValue(players.map(\.displayName).joined(separator: ", "))
    }

    private func polygon(center: CGPoint, radius: CGFloat) -> Path {
        valuePolygon(Array(repeating: maximum, count: resources.count), center: center, radius: radius)
    }

    private func valuePolygon(_ values: [Double], center: CGPoint, radius: CGFloat) -> Path {
        var path = Path()
        for index in resources.indices {
            let ratio = values.indices.contains(index) ? values[index] / maximum : 0
            let point = point(index: index, value: ratio, center: center, radius: radius)
            index == resources.startIndex ? path.move(to: point) : path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }

    private func point(index: Int, value: Double, center: CGPoint, radius: CGFloat) -> CGPoint {
        let angle = -Double.pi / 2 + Double(index) * 2 * Double.pi / Double(resources.count)
        return CGPoint(
            x: center.x + cos(angle) * radius * value,
            y: center.y + sin(angle) * radius * value
        )
    }
}

private enum DiceRelianceMode: String, CaseIterable, Identifiable {
    case produced = "Cards produced on dice result"
    case expected = "Expected card production"
    var id: Self { self }
}

private struct DiceRelianceView: View {
    let board: BoardState
    @State private var player = PlayerColor.red
    @State private var mode = DiceRelianceMode.produced
    @State private var showsHelp = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dice reliance")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Picker("Player", selection: $player) {
                ForEach(board.activePlayers) { candidate in
                    Text(candidate.displayName).tag(candidate)
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("diceReliancePlayerPicker")

            HStack(spacing: 8) {
                Picker("Dice production metric", selection: $mode) {
                    ForEach(DiceRelianceMode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("diceRelianceMetricPicker")

                Button { showsHelp = true } label: {
                    Image(systemName: "questionmark.circle.fill").frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dice reliance help")
                .accessibilityIdentifier("diceRelianceHelp")
            }

            DiceBarChart(results: chartValues, color: player.color)
                .frame(height: 230)
                .accessibilityIdentifier("diceRelianceChart")
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.25)))
        .onAppear { selectValidPlayer() }
        .onChange(of: board.activePlayers) { _, _ in selectValidPlayer() }
        .alert("Dice reliance", isPresented: $showsHelp) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Cards produced on dice result shows how many cards you will get upon getting a given dice result.\n\nExpected card production multiplies this by the probability of that number being rolled to show its expected contribution towards your total production.")
        }
        .accessibilityIdentifier("diceReliance")
    }

    private var chartValues: [(Int, Double)] {
        let raw = ProductionMetrics.cardsProducedByDiceResult(player: player, snapshot: board.snapshot)
        let expected = ProductionMetrics.expectedCardsByDiceResult(player: player, snapshot: board.snapshot)
        return ProductionMetrics.displayedDiceResults.map { result in
            (result, mode == .produced ? Double(raw[result, default: 0]) : expected[result, default: 0])
        }
    }

    private func selectValidPlayer() {
        if !board.activePlayers.contains(player), let first = board.activePlayers.first { player = first }
    }
}

private struct DiceBarChart: View {
    let results: [(Int, Double)]
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            let chartTop: CGFloat = 10
            let chartBottom = proxy.size.height - 34
            let chartHeight = max(1, chartBottom - chartTop)
            let maximum = max(results.map(\.1).max() ?? 0, 1)
            let slotWidth = proxy.size.width / CGFloat(max(results.count, 1))

            ZStack(alignment: .topLeading) {
                ForEach(0..<4, id: \.self) { index in
                    let y = chartTop + chartHeight * CGFloat(index) / 3
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                    }
                    .stroke(Color.secondary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4]))
                }

                ForEach(Array(results.enumerated()), id: \.element.0) { index, item in
                    let height = chartHeight * item.1 / maximum
                    VStack(spacing: 4) {
                        Spacer(minLength: 0)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(color)
                            .frame(width: max(8, slotWidth * 0.48), height: max(item.1 > 0 ? 2 : 0, height))
                        Text("\(item.0)")
                            .font(.caption2.monospacedDigit())
                            .frame(height: 18)
                    }
                    .frame(width: slotWidth, height: proxy.size.height, alignment: .bottom)
                    .position(x: slotWidth * (CGFloat(index) + 0.5), y: proxy.size.height / 2)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Dice result \(item.0)")
                    .accessibilityValue(item.1.formatted(.number.precision(.fractionLength(2))))
                }
            }
        }
        .overlay(alignment: .bottom) {
            Text("Dice result").font(.caption2).foregroundStyle(.secondary)
        }
    }
}

private func resourceColor(_ resource: ProductionResource) -> Color {
    switch resource {
    case .all: .purple
    case .brick: .red
    case .wood: .green
    case .ore: Color(red: 0.42, green: 0.55, blue: 0.65)
    case .wheat: .yellow
    case .sheep: .primary
    }
}
