import SwiftUI

nonisolated struct PlanTableScrollState {
    static func synchronizedOffset(from rawOffset: CGPoint) -> CGPoint {
        CGPoint(x: max(0, rawOffset.x), y: max(0, rawOffset.y))
    }
}

private enum PlanTableSection: Equatable {
    case summary
    case probability
}

private enum PlanBrowserTab: String, CaseIterable, Identifiable {
    case production = "Production"
    case plans = "Plans"

    var id: Self { self }

    var kind: CustomPlanKind { self == .production ? .cards : .constructions }
}

private enum PlanBrowserAlert: String, Identifiable {
    case browserHelp
    case defaultPlan

    var id: Self { self }

    var title: String {
        switch self {
        case .browserHelp: "Analysis"
        case .defaultPlan: "Built-in production checks cannot be edited."
        }
    }

    var message: String {
        switch self {
        case .browserHelp:
            "Use Production for built-in and custom resource checks, and Plans for ordered construction analysis. Swipe the table to move between turns and probability columns."
        case .defaultPlan:
            "Create a production check if you want to edit its name, player, icon, or cards."
        }
    }
}

private struct PlanTableRow: Identifiable {
    let id: String
    let name: String
    let systemImage: String
    let statistics: DefaultPlan?
    let customPlan: CustomPlan?
    let owner: PlayerColor?
    let isNewPlan: Bool
    let isGroupLabel: Bool
    let isStep: Bool
    let accessibilityID: String
}

private struct PlanHeaderButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(configuration.isPressed ? Color.secondary.opacity(0.16) : .clear)
            )
            .scaleEffect(configuration.isPressed ? 1.08 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct OwnerCornerTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

private struct OwnerTriangleHypotenuse: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX + 0.5, y: rect.minY + 0.5))
            path.addLine(to: CGPoint(x: rect.maxX - 0.5, y: rect.maxY - 0.5))
        }
    }
}

struct PlanBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    let board: BoardState
    @Binding var selectedPlayer: PlayerColor
    @State private var scrollOffset = CGPoint.zero
    @State private var tableSection = PlanTableSection.summary
    @State private var selectedTab = PlanBrowserTab.production
    @State private var isShowingAllPlayers = false
    @State private var editingPlan: CustomPlan?
    @State private var activeAlert: PlanBrowserAlert?
    @State private var expandedPlanIDs: Set<UUID> = []

    private let summaryColumns = ["Mean", "Median", "25th", "75th"]
    private let planColumnWidth: CGFloat = 118
    private let probabilityColumnWidth: CGFloat = 58
    private let superHeaderHeight: CGFloat = 30
    private let columnHeaderHeight: CGFloat = 34
    private let rowHeight: CGFloat = 36
    private let subrowLeadingInset: CGFloat = 12

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                tabSelector
                    .padding(.horizontal)
                HStack {
                    PlayerSelector(
                        selection: $selectedPlayer,
                        allSelection: $isShowingAllPlayers
                    )
                    Spacer(minLength: 0)
                    Button {
                        activeAlert = .browserHelp
                    } label: {
                        Image(systemName: "questionmark.circle.fill")
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlanHeaderButtonStyle())
                    .accessibilityLabel("Analysis help")
                    .accessibilityIdentifier("analysisHelpButton")
                }
                .padding(.horizontal)
                .frame(height: 44)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("analysisPlayerRow")
                planTable
            }
            .padding(.top, 8)
            .navigationTitle("Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .accessibilityIdentifier("closeAnalysisButton")
                }
            }
            .sheet(item: $editingPlan) { plan in
                let isNewPlan = !board.customPlans.contains { $0.id == plan.id }
                PlanEditorView(
                    board: board,
                    plan: plan,
                    selectedPlayer: $selectedPlayer,
                    generatedDefaultName: isNewPlan ? plan.name : nil,
                    defaultNameProvider: { kind, player in
                        CustomPlan.nextDefaultName(for: kind, player: player, in: board.customPlans)
                    }
                ) { save($0) }
            }
            .alert(item: $activeAlert) { alert in
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .cancel(Text("OK"))
                )
            }
        }
        .accessibilityIdentifier("analysisBrowser")
    }

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(PlanBrowserTab.allCases) { tab in
                Button {
                    selectedTab = tab
                    scrollOffset = .zero
                } label: {
                    Text(tab.rawValue)
                        .font(.subheadline.weight(selectedTab == tab ? .semibold : .regular))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .foregroundStyle(selectedTab == tab ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            selectedTab == tab ? Color.accentColor : Color.clear,
                            in: RoundedRectangle(cornerRadius: 7)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
                .accessibilityIdentifier("\(tab.rawValue.lowercased())AnalysisTab")
            }
        }
        .padding(2)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 9))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("planTabSelector")
    }

    private var planTable: some View {
        GeometryReader { proxy in
            let valuesViewportWidth = max(0, proxy.size.width - planColumnWidth - 1)

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    fixedCornerHeader
                    tableVerticalDivider
                    sectionHeader(viewportWidth: valuesViewportWidth)
                        .frame(width: valuesViewportWidth)
                }
                .frame(height: headerHeight)

                tableHorizontalDivider

                HStack(spacing: 0) {
                    fixedPlanColumn
                    tableVerticalDivider
                    scrollingValues(viewportWidth: valuesViewportWidth)
                        .frame(width: valuesViewportWidth)
                }
                .frame(maxHeight: .infinity)
            }
            .background(Color(uiColor: .systemBackground))
            .animation(.easeInOut(duration: 0.24), value: tableSection)
            .animation(.easeInOut(duration: 0.24), value: expandedPlanIDs)
        }
        .padding(.horizontal)
        .accessibilityIdentifier(selectedTab == .production ? "productionTable" : "plansTable")
    }

    private var fixedCornerHeader: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: superHeaderHeight)
            tableHorizontalDivider
            tableCell(
                "Analysis",
                width: planColumnWidth,
                height: columnHeaderHeight,
                alignment: .leading
            )
        }
        .frame(width: planColumnWidth, height: headerHeight)
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .background(Color(uiColor: .systemBackground))
        .accessibilityIdentifier("fixedPlanHeader")
    }

    private func sectionHeader(viewportWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            metaHeader(width: viewportWidth)
            tableHorizontalDivider

            GeometryReader { _ in
                Group {
                    switch tableSection {
                    case .summary:
                        summaryColumnHeader(width: viewportWidth)
                    case .probability:
                        probabilityColumnHeader
                            .offset(x: -scrollOffset.x)
                    }
                }
                .id(tableSection)
                .transition(sectionTransition)
            }
        }
        .frame(height: headerHeight)
        .clipped()
        .background(Color(uiColor: .systemBackground))
        .accessibilityIdentifier("planColumnHeader")
    }

    private func metaHeader(width: CGFloat) -> some View {
        ZStack {
            Text(
                tableSection == .summary
                    ? "Turns until acquired/built"
                    : "Probability within N turns"
            )

            HStack {
                if tableSection == .probability {
                    sectionArrow
                }
                Spacer()
                if tableSection == .summary {
                    sectionArrow
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(width: width, height: superHeaderHeight)
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
        .background(Color(uiColor: .systemBackground))
        .accessibilityIdentifier("planMetaHeader")
    }

    private func summaryColumnHeader(width: CGFloat) -> some View {
        let columnWidth = width / CGFloat(summaryColumns.count)

        return HStack(spacing: 0) {
            ForEach(summaryColumns, id: \.self) { title in
                tableCell(title, width: columnWidth, height: columnHeaderHeight)
            }
        }
        .frame(width: width, height: columnHeaderHeight)
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
        .background(Color(uiColor: .systemBackground))
        .accessibilityIdentifier("summaryPlanHeader")
    }

    private var probabilityColumnHeader: some View {
        HStack(spacing: 0) {
            ForEach(1...10, id: \.self) { turn in
                tableCell("T\(turn)", width: probabilityColumnWidth, height: columnHeaderHeight)
            }
        }
        .frame(width: probabilityGroupWidth, height: columnHeaderHeight)
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
        .background(Color(uiColor: .systemBackground))
        .accessibilityIdentifier("probabilityPlanHeader")
    }

    private var fixedPlanColumn: some View {
        GeometryReader { _ in
            planColumnContent
                .offset(y: -scrollOffset.y)
                .frame(width: planColumnWidth, height: rowsContentHeight, alignment: .top)
        }
        .frame(width: planColumnWidth)
        .clipped()
        .background(Color(uiColor: .systemBackground))
        .accessibilityIdentifier("fixedPlanColumn")
    }

    private var planColumnContent: some View {
        LazyVStack(spacing: 0) {
            ForEach(tableRows) { row in
                planCell(row)
                tableHorizontalDivider
            }
        }
    }

    @ViewBuilder
    private func planCell(_ row: PlanTableRow) -> some View {
        if row.isNewPlan {
            Button {
                beginNewPlan(kind: selectedTab.kind)
            } label: {
                Label(row.name, systemImage: "plus")
                    .font(.caption.weight(.semibold))
                    .frame(width: planColumnWidth, height: rowHeight, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(row.accessibilityID)
        } else if row.isGroupLabel {
            Text(row.name)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
                .frame(
                    width: planColumnWidth - subrowLeadingInset,
                    height: rowHeight,
                    alignment: .leading
                )
                .padding(.leading, subrowLeadingInset)
                .frame(width: planColumnWidth, height: rowHeight, alignment: .leading)
                .background(Color(uiColor: .systemBackground))
                .accessibilityIdentifier(row.accessibilityID)
        } else {
            HStack(spacing: 5) {
                if row.isStep {
                    Color.clear.frame(width: subrowLeadingInset)
                }
                Image(systemName: row.systemImage)
                if !row.isStep {
                    Text(row.name)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Spacer(minLength: 0)
                }
            }
                .font(.caption.weight(.medium))
                .lineLimit(row.customPlan == nil ? 1 : 2)
                .minimumScaleFactor(0.72)
                .frame(width: planColumnWidth, height: rowHeight, alignment: .leading)
                .background(Color(uiColor: .systemBackground))
                .overlay(alignment: .topTrailing) {
                    if isShowingAllPlayers, let owner = row.owner {
                        OwnerCornerTriangle()
                            .fill(owner.color)
                            .overlay {
                                OwnerTriangleHypotenuse()
                                    .stroke(.primary.opacity(0.65), lineWidth: 1)
                            }
                            .frame(width: 13, height: 13)
                            .padding(.trailing, 2)
                            .accessibilityLabel("Owned by \(owner.displayName) player")
                            .accessibilityIdentifier("planOwner-\(owner.rawValue)")
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if let customPlan = row.customPlan {
                        withAnimation(.easeInOut(duration: 0.24)) {
                            if expandedPlanIDs.contains(customPlan.id) {
                                expandedPlanIDs.remove(customPlan.id)
                            } else {
                                expandedPlanIDs.insert(customPlan.id)
                            }
                        }
                    }
                }
                .onLongPressGesture {
                    if let customPlan = row.customPlan {
                        editingPlan = customPlan
                    } else if !row.isStep && !row.isGroupLabel {
                        activeAlert = .defaultPlan
                    }
                }
                .accessibilityHint(row.customPlan == nil ? "" : "Tap to expand; hold to edit this plan")
                .accessibilityIdentifier(row.accessibilityID)
        }
    }

    private func scrollingValues(viewportWidth: CGFloat) -> some View {
        GeometryReader { proxy in
            ScrollView([.horizontal, .vertical]) {
                Group {
                    switch tableSection {
                    case .summary:
                        summaryValues(width: viewportWidth)
                    case .probability:
                        probabilityValues
                    }
                }
                .id(tableSection)
                .transition(sectionTransition)
                .frame(
                    minWidth: proxy.size.width,
                    minHeight: proxy.size.height,
                    alignment: .topLeading
                )
            }
            .defaultScrollAnchor(.topLeading)
            .onScrollGeometryChange(for: CGPoint.self) { geometry in
                CGPoint(
                    x: geometry.contentOffset.x + geometry.contentInsets.leading,
                    y: geometry.contentOffset.y + geometry.contentInsets.top
                )
            } action: { _, newOffset in
                scrollOffset = PlanTableScrollState.synchronizedOffset(from: newOffset)
            }
            .simultaneousGesture(sectionSwipeGesture)
            .clipped()
            .accessibilityIdentifier("planValuesTable")
        }
    }

    private func summaryValues(width: CGFloat) -> some View {
        let columnWidth = width / CGFloat(summaryColumns.count)

        return LazyVStack(spacing: 0) {
            ForEach(tableRows) { row in
                Group {
                    if let plan = row.statistics {
                        HStack(spacing: 0) {
                            placeholderCell(
                                plan.mean.formatted(.number.precision(.fractionLength(1))),
                                width: columnWidth
                            )
                            placeholderCell(
                                plan.median.formatted(.number.precision(.fractionLength(0))),
                                width: columnWidth
                            )
                            placeholderCell(
                                plan.percentile25.formatted(.number.precision(.fractionLength(0))),
                                width: columnWidth
                            )
                            placeholderCell(
                                plan.percentile75.formatted(.number.precision(.fractionLength(0))),
                                width: columnWidth
                            )
                        }
                    } else {
                        Color.clear
                    }
                }
                .frame(width: width, height: rowHeight)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(row.statistics.map { accessibilitySummary(for: $0) } ?? "New plan")
                .accessibilityIdentifier(
                    valuesAccessibilityID(for: row)
                )
                tableHorizontalDivider
            }
        }
        .frame(width: width, alignment: .leading)
        .accessibilityIdentifier("summaryPlanValues")
    }

    private var probabilityValues: some View {
        LazyVStack(spacing: 0) {
            ForEach(tableRows) { row in
                Group {
                    if let plan = row.statistics {
                        HStack(spacing: 0) {
                            ForEach(Array(plan.turnProbabilities.enumerated()), id: \.offset) { _, probability in
                                placeholderCell("\(probability)%", width: probabilityColumnWidth)
                            }
                        }
                    } else {
                        Color.clear
                    }
                }
                .frame(width: probabilityGroupWidth, height: rowHeight, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(row.name) cumulative completion probabilities")
                .accessibilityIdentifier(
                    probabilitiesAccessibilityID(for: row)
                )
                tableHorizontalDivider
            }
        }
        .frame(width: probabilityGroupWidth, alignment: .leading)
        .accessibilityIdentifier("probabilityPlanValues")
    }

    private var sectionArrow: some View {
        Button {
            switchSection()
        } label: {
            Image(systemName: tableSection == .summary ? "chevron.right" : "chevron.left")
                .font(.caption2.bold())
                .frame(width: 22, height: superHeaderHeight)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary.opacity(0.45))
        .accessibilityLabel(
            tableSection == .summary ? "Show probability columns" : "Show estimated turns columns"
        )
        .accessibilityIdentifier("planSectionArrow")
    }

    private var sectionSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 28)
            .onEnded { value in
                let horizontal = value.translation.width
                guard abs(horizontal) > abs(value.translation.height) * 1.25 else { return }

                switch tableSection {
                case .summary where horizontal < -48:
                    showProbabilitySection()
                case .probability where horizontal > 48 && scrollOffset.x <= 1:
                    showSummarySection()
                default:
                    break
                }
            }
    }

    private func switchSection() {
        switch tableSection {
        case .summary: showProbabilitySection()
        case .probability: showSummarySection()
        }
    }

    private func showProbabilitySection() {
        scrollOffset.x = 0
        tableSection = .probability
    }

    private func showSummarySection() {
        scrollOffset.x = 0
        tableSection = .summary
    }

    private var sectionTransition: AnyTransition {
        tableSection == .probability
            ? .push(from: .trailing)
            : .push(from: .leading)
    }

    private func placeholderCell(_ value: String, width: CGFloat) -> some View {
        Text(value)
            .font(.subheadline.monospacedDigit())
            .foregroundStyle(.red)
            .frame(width: width, height: rowHeight)
            .accessibilityLabel("Placeholder \(value)")
    }

    private func tableCell(
        _ value: String,
        width: CGFloat,
        height: CGFloat? = nil,
        alignment: Alignment = .center
    ) -> some View {
        Text(value).frame(width: width, height: height, alignment: alignment)
    }

    private var tableHorizontalDivider: some View {
        Rectangle()
            .fill(tableLineColor)
            .frame(height: 1)
            .accessibilityHidden(true)
    }

    private var tableVerticalDivider: some View {
        Rectangle()
            .fill(tableLineColor)
            .frame(width: 1)
            .accessibilityHidden(true)
    }

    private var tableLineColor: Color {
        Color.secondary.opacity(0.28)
    }

    private func accessibilitySummary(for plan: DefaultPlan) -> String {
        "\(plan.name), placeholder mean \(plan.mean.formatted(.number.precision(.fractionLength(1)))) turns, median \(Int(plan.median)) turns"
    }

    private func valuesAccessibilityID(for row: PlanTableRow) -> String {
        if row.isNewPlan { return "newPlanValues" }
        if let plan = row.customPlan { return "customPlanValues-\(plan.id.uuidString)" }
        if row.accessibilityID.hasPrefix("defaultPlan-") {
            return row.accessibilityID.replacingOccurrences(of: "defaultPlan-", with: "defaultPlanValues-")
        }
        return "\(row.accessibilityID)Values"
    }

    private func probabilitiesAccessibilityID(for row: PlanTableRow) -> String {
        if row.isNewPlan { return "newPlanProbabilities" }
        if let plan = row.customPlan { return "customPlanProbabilities-\(plan.id.uuidString)" }
        if row.accessibilityID.hasPrefix("defaultPlan-") {
            return row.accessibilityID.replacingOccurrences(
                of: "defaultPlan-",
                with: "defaultPlanProbabilities-"
            )
        }
        return "\(row.accessibilityID)Probabilities"
    }

    private var headerHeight: CGFloat {
        superHeaderHeight + columnHeaderHeight + 1
    }

    private var probabilityGroupWidth: CGFloat {
        probabilityColumnWidth * 10
    }

    private var rowsContentHeight: CGFloat {
        CGFloat(tableRows.count) * (rowHeight + 1)
    }

    private var tableRows: [PlanTableRow] {
        var rows: [PlanTableRow] = []

        if selectedTab == .production {
            rows.append(contentsOf: DefaultPlan.placeholders(
                for: selectedPlayer,
                hand: board.hand(for: selectedPlayer)
            ).map { plan in
                PlanTableRow(
                    id: "default-\(plan.id)",
                    name: plan.name,
                    systemImage: plan.systemImage,
                    statistics: plan,
                    customPlan: nil,
                    owner: nil,
                    isNewPlan: false,
                    isGroupLabel: false,
                    isStep: false,
                    accessibilityID: "defaultPlan-\(plan.name)"
                )
            })
        }

        rows.append(contentsOf: customRows(kind: selectedTab.kind))
        let creationName = selectedTab == .production ? "New production check" : "New plan"
        rows.append(PlanTableRow(
            id: "new-\(selectedTab.kind.rawValue)",
            name: creationName,
            systemImage: "plus",
            statistics: nil,
            customPlan: nil,
            owner: nil,
            isNewPlan: true,
            isGroupLabel: false,
            isStep: false,
            accessibilityID: selectedTab == .production
                ? "newProductionCheckButton"
                : "newPlanButton"
        ))
        return rows
    }

    private func customRows(kind: CustomPlanKind) -> [PlanTableRow] {
        let visibleItems = CustomPlan.visible(
            to: selectedPlayer,
            includesAllPlayers: isShowingAllPlayers,
            in: board.customPlans
        ).filter { $0.kind == kind }
        var rows: [PlanTableRow] = []

        for plan in visibleItems {
            rows.append(PlanTableRow(
                id: "custom-\(plan.id.uuidString)",
                name: plan.name,
                systemImage: plan.icon,
                statistics: DefaultPlan.placeholder(
                    for: plan,
                    player: plan.player,
                    hand: board.hand(for: plan.player)
                ),
                customPlan: plan,
                owner: plan.player,
                isNewPlan: false,
                isGroupLabel: false,
                isStep: false,
                accessibilityID: "customPlan-\(plan.id.uuidString)"
            ))

            guard expandedPlanIDs.contains(plan.id) else { continue }

            rows.append(groupRow(
                id: "custom-\(plan.id.uuidString)-card-stats",
                name: "Card stats after plan completion",
                accessibilityID: "customPlanCardStats-\(plan.id.uuidString)"
            ))
            let cardStatistics = DefaultPlan.placeholders(
                forCardStatsAfter: plan,
                player: plan.player,
                hand: board.hand(for: plan.player)
            )
            for (resource, statistic) in zip(ResourceCard.allCases, cardStatistics) {
                rows.append(subrow(
                    id: "custom-\(plan.id.uuidString)-card-\(resource.rawValue)",
                    name: resource.displayName,
                    systemImage: resource.systemImage,
                    statistics: statistic,
                    accessibilityID: "customPlanCard-\(plan.id.uuidString)-\(resource.rawValue)"
                ))
            }

            if !plan.constructionSteps.isEmpty {
                rows.append(groupRow(
                    id: "custom-\(plan.id.uuidString)-steps",
                    name: "Steps",
                    accessibilityID: "customPlanSteps-\(plan.id.uuidString)"
                ))
                let statistics = DefaultPlan.placeholders(
                    forConstructionStepsIn: plan,
                    player: plan.player,
                    hand: board.hand(for: plan.player)
                )
                for (index, statistic) in statistics.enumerated() {
                    rows.append(subrow(
                        id: "custom-\(plan.id.uuidString)-step-\(index)",
                        name: "Step \(index + 1)",
                        systemImage: statistic.systemImage,
                        statistics: statistic,
                        accessibilityID: "customPlanStep-\(plan.id.uuidString)-\(index)"
                    ))
                }
            }
        }
        return rows
    }

    private func groupRow(id: String, name: String, accessibilityID: String) -> PlanTableRow {
        PlanTableRow(
            id: id,
            name: name,
            systemImage: "",
            statistics: nil,
            customPlan: nil,
            owner: nil,
            isNewPlan: false,
            isGroupLabel: true,
            isStep: false,
            accessibilityID: accessibilityID
        )
    }

    private func subrow(
        id: String,
        name: String,
        systemImage: String,
        statistics: DefaultPlan,
        accessibilityID: String
    ) -> PlanTableRow {
        PlanTableRow(
            id: id,
            name: name,
            systemImage: systemImage,
            statistics: statistics,
            customPlan: nil,
            owner: nil,
            isNewPlan: false,
            isGroupLabel: false,
            isStep: true,
            accessibilityID: accessibilityID
        )
    }

    private func beginNewPlan(kind: CustomPlanKind) {
        let owner: PlayerColor = isShowingAllPlayers ? .red : selectedPlayer
        selectedPlayer = owner
        editingPlan = CustomPlan(
            name: CustomPlan.nextDefaultName(
                for: kind,
                player: owner,
                in: board.customPlans
            ),
            kind: kind,
            player: owner
        )
    }

    private func save(_ plan: CustomPlan) {
        selectedPlayer = plan.player
        board.savePlan(plan)
    }

}

#Preview {
    PlanBrowserView(board: BoardState(), selectedPlayer: .constant(.red))
}
