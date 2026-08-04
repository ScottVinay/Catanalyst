import SwiftUI

private enum PlanTableSection: Equatable {
    case summary
    case probability
}

private enum PlanBrowserTab: String, CaseIterable, Identifiable {
    case `default` = "Default"
    case custom = "Custom"

    var id: Self { self }
}

private enum PlanBrowserAlert: String, Identifiable {
    case browserHelp
    case planTypeHelp
    case defaultPlan

    var id: Self { self }

    var title: String {
        switch self {
        case .browserHelp: "Plan Browser"
        case .planTypeHelp: "Choosing a plan type"
        case .defaultPlan: "Default plans cannot be edited."
        }
    }

    var message: String {
        switch self {
        case .browserHelp:
            "Use Default for standard build estimates and Custom for plans belonging to the selected player. Swipe the table to move between turns and probability columns."
        case .planTypeHelp:
            "Cards plans target a hand of resources. Constructions plans target an ordered sequence of things to build."
        case .defaultPlan:
            "Create a Custom plan if you want to edit its name, player, or contents."
        }
    }
}

private struct PlanTableRow: Identifiable {
    let id: String
    let name: String
    let systemImage: String
    let statistics: DefaultPlan?
    let customPlan: CustomPlan?
    let isNewPlan: Bool
}

struct PlanBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    let board: BoardState
    @Binding var selectedPlayer: PlayerColor
    @State private var scrollOffset = CGPoint.zero
    @State private var verticalOverscroll: CGFloat = 0
    @State private var tableSection = PlanTableSection.summary
    @State private var selectedTab = PlanBrowserTab.default
    @State private var customPlans: [CustomPlan] = []
    @State private var editingPlan: CustomPlan?
    @State private var viewedPlan: CustomPlan?
    @State private var pendingEditPlan: CustomPlan?
    @State private var isChoosingPlanKind = false
    @State private var activeAlert: PlanBrowserAlert?

    private let summaryColumns = ["Mean", "Median", "25th", "75th"]
    private let planColumnWidth: CGFloat = 118
    private let probabilityColumnWidth: CGFloat = 58
    private let superHeaderHeight: CGFloat = 30
    private let columnHeaderHeight: CGFloat = 34
    private let rowHeight: CGFloat = 44

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                tabSelector
                HStack {
                    PlayerSelector(selection: $selectedPlayer)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal)
                planTable
            }
            .padding(.top, 8)
            .navigationTitle("Plans")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .accessibilityIdentifier("closePlanBrowserButton")
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {} label: {
                        Image(systemName: "chart.bar.xaxis")
                    }
                    .disabled(true)
                    .accessibilityLabel("Graphs")
                    .accessibilityHint("Graph navigation is not available yet")
                    .accessibilityIdentifier("planGraphsButton")

                    Button {
                        activeAlert = .browserHelp
                    } label: {
                        Image(systemName: "questionmark.circle.fill")
                    }
                    .accessibilityLabel("Plan Browser help")
                    .accessibilityIdentifier("planBrowserHelpButton")
                }
            }
            .sheet(item: $editingPlan) { plan in
                PlanEditorView(board: board, plan: plan, selectedPlayer: $selectedPlayer) { save($0) }
            }
            .sheet(item: $viewedPlan, onDismiss: openPendingEditor) { plan in
                PlanDetailView(plan: plan) { planToEdit in
                    pendingEditPlan = planToEdit
                    viewedPlan = nil
                }
            }
            .overlay {
                if isChoosingPlanKind {
                    planTypeChooser
                        .transition(.scale(scale: 0.92).combined(with: .opacity))
                }
            }
            .alert(item: $activeAlert) { alert in
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .cancel(Text("OK"))
                )
            }
        }
        .accessibilityIdentifier("planBrowser")
    }

    private var planTypeChooser: some View {
        ZStack {
            Color.black.opacity(0.28)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Text("Choose plan type")
                        .font(.headline)
                    Spacer()
                    Button {
                        activeAlert = .planTypeHelp
                    } label: {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Plan type help")
                    .accessibilityIdentifier("planTypeHelpButton")
                }

                HStack(spacing: 12) {
                    planTypeButton("Cards", systemImage: "rectangle.stack.fill", kind: .cards)
                    planTypeButton("Constructions", systemImage: "hammer.fill", kind: .constructions)
                }

                Button("Cancel", role: .cancel) {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        isChoosingPlanKind = false
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 320)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
            .shadow(radius: 18)
            .accessibilityIdentifier("planTypeChooser")
        }
        .zIndex(10)
    }

    private func planTypeButton(
        _ title: String,
        systemImage: String,
        kind: CustomPlanKind
    ) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.16)) {
                isChoosingPlanKind = false
            }
            beginNewPlan(kind: kind)
        } label: {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier("choosePlanType-\(kind.rawValue)")
    }

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(PlanBrowserTab.allCases) { tab in
                Button {
                    selectedTab = tab
                    scrollOffset = .zero
                    verticalOverscroll = 0
                } label: {
                    Text(tab.rawValue)
                        .font(.subheadline.weight(selectedTab == tab ? .semibold : .regular))
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
                .accessibilityIdentifier("\(tab.rawValue.lowercased())PlansTab")
            }
        }
        .padding(2)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 9))
        .padding(.horizontal)
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
        }
        .padding(.horizontal)
        .accessibilityIdentifier(selectedTab == .default ? "defaultPlanTable" : "customPlanTable")
    }

    private var fixedCornerHeader: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: superHeaderHeight)
            tableHorizontalDivider
            tableCell(
                "Plan",
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
                isChoosingPlanKind = true
            } label: {
                Label("New Plan", systemImage: "plus")
                    .font(.caption.weight(.semibold))
                    .frame(width: planColumnWidth, height: rowHeight, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("newPlanButton")
        } else {
            Label(row.name, systemImage: row.systemImage)
                .font(selectedTab == .custom ? .caption.weight(.medium) : .subheadline.weight(.medium))
                .lineLimit(selectedTab == .custom ? 2 : 1)
                .minimumScaleFactor(0.72)
                .frame(width: planColumnWidth, height: rowHeight, alignment: .leading)
                .background(Color(uiColor: .systemBackground))
                .contentShape(Rectangle())
                .onTapGesture {
                    if let customPlan = row.customPlan {
                        viewedPlan = customPlan
                    }
                }
                .onLongPressGesture {
                    if row.customPlan == nil {
                        activeAlert = .defaultPlan
                    }
                }
                .accessibilityHint(row.customPlan == nil ? "" : "Tap to view or edit this plan")
                .accessibilityIdentifier(
                    row.customPlan.map { "customPlan-\($0.id.uuidString)" }
                        ?? "defaultPlan-\(row.name)"
                )
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
                .offset(y: verticalOverscroll)
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
                verticalOverscroll = min(0, newOffset.y)
                scrollOffset = CGPoint(
                    x: max(0, newOffset.x),
                    y: max(0, newOffset.y)
                )
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
                    row.customPlan.map { "customPlanValues-\($0.id.uuidString)" }
                        ?? (row.isNewPlan ? "newPlanValues" : "defaultPlanValues-\(row.name)")
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
                    row.customPlan.map { "customPlanProbabilities-\($0.id.uuidString)" }
                        ?? (row.isNewPlan ? "newPlanProbabilities" : "defaultPlanProbabilities-\(row.name)")
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
        switch selectedTab {
        case .default:
            DefaultPlan.placeholders(for: selectedPlayer).map { plan in
                PlanTableRow(
                    id: "default-\(plan.id)",
                    name: plan.name,
                    systemImage: plan.systemImage,
                    statistics: plan,
                    customPlan: nil,
                    isNewPlan: false
                )
            }
        case .custom:
            CustomPlan.belonging(to: selectedPlayer, in: customPlans).map { plan in
                PlanTableRow(
                    id: "custom-\(plan.id.uuidString)",
                    name: plan.name,
                    systemImage: plan.icon,
                    statistics: DefaultPlan.placeholder(for: plan, player: selectedPlayer),
                    customPlan: plan,
                    isNewPlan: false
                )
            } + [
                PlanTableRow(
                    id: "new-plan",
                    name: "New Plan",
                    systemImage: "plus",
                    statistics: nil,
                    customPlan: nil,
                    isNewPlan: true
                )
            ]
        }
    }

    private func beginNewPlan(kind: CustomPlanKind) {
        editingPlan = CustomPlan(
            name: CustomPlan.nextDefaultName(
                for: kind,
                player: selectedPlayer,
                in: customPlans
            ),
            kind: kind,
            player: selectedPlayer
        )
    }

    private func save(_ plan: CustomPlan) {
        selectedPlayer = plan.player
        if let index = customPlans.firstIndex(where: { $0.id == plan.id }) {
            customPlans[index] = plan
        } else {
            customPlans.append(plan)
        }
    }

    private func openPendingEditor() {
        guard let pendingEditPlan else { return }
        self.pendingEditPlan = nil
        editingPlan = pendingEditPlan
    }
}

#Preview {
    PlanBrowserView(board: BoardState(), selectedPlayer: .constant(.red))
}
