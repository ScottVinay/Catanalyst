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

struct PlanBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedPlayer: PlayerColor
    @State private var scrollOffset = CGPoint.zero
    @State private var verticalOverscroll: CGFloat = 0
    @State private var tableSection = PlanTableSection.summary
    @State private var isSelectingPlayer = false
    @State private var selectedTab = PlanBrowserTab.default
    @State private var customPlans: [CustomPlan] = []
    @State private var editingPlan: CustomPlan?
    @State private var viewedPlan: CustomPlan?
    @State private var isChoosingPlanKind = false
    @State private var showsDefaultPlanMessage = false

    private let summaryColumns = ["Mean", "Median", "25th", "75th"]
    private let planColumnWidth: CGFloat = 118
    private let probabilityColumnWidth: CGFloat = 58
    private let superHeaderHeight: CGFloat = 30
    private let columnHeaderHeight: CGFloat = 34
    private let rowHeight: CGFloat = 44

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Color.clear.frame(height: 42)
                tabSelector
                if selectedTab == .default {
                    planTable
                } else {
                    customPlansView
                }
            }
            .overlay(alignment: .topLeading) {
                PlayerSelector(
                    selection: $selectedPlayer,
                    isExpanded: $isSelectingPlayer
                )
                .padding(.horizontal)
                .zIndex(2)
            }
            .padding(.top, 8)
            .navigationTitle(isSelectingPlayer ? "Select player" : "Plans")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .accessibilityIdentifier("closePlanBrowserButton")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {} label: {
                        Image(systemName: "chart.bar.xaxis")
                    }
                    .disabled(true)
                    .accessibilityLabel("Graphs")
                    .accessibilityHint("Graph navigation is not available yet")
                    .accessibilityIdentifier("planGraphsButton")
                }
            }
            .confirmationDialog(
                "Choose plan type",
                isPresented: $isChoosingPlanKind,
                titleVisibility: .visible
            ) {
                Button("Cards") { beginNewPlan(kind: .cards) }
                Button("Constructions") { beginNewPlan(kind: .constructions) }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(item: $editingPlan) { plan in
                PlanEditorView(plan: plan, selectedPlayer: $selectedPlayer) { save($0) }
            }
            .sheet(item: $viewedPlan) { plan in
                PlanDetailView(plan: plan, selectedPlayer: $selectedPlayer) { save($0) }
            }
            .alert("Default plans cannot be edited.", isPresented: $showsDefaultPlanMessage) {
                Button("OK", role: .cancel) {}
            }
        }
        .accessibilityIdentifier("planBrowser")
    }

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(PlanBrowserTab.allCases) { tab in
                Button {
                    selectedTab = tab
                    isSelectingPlayer = false
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

    private var customPlansView: some View {
        List {
            ForEach(customPlans) { plan in
                Label(plan.name, systemImage: plan.icon)
                    .contentShape(Rectangle())
                    .onLongPressGesture { viewedPlan = plan }
                    .accessibilityHint("Hold to view or edit this plan")
                    .accessibilityIdentifier("customPlan-\(plan.id.uuidString)")
            }

            Button {
                isChoosingPlanKind = true
            } label: {
                Label("New Plan", systemImage: "plus")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityIdentifier("newPlanButton")
        }
        .listStyle(.plain)
        .accessibilityIdentifier("customPlansList")
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
        .accessibilityIdentifier("defaultPlanTable")
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
            ForEach(plans) { plan in
                planCell(plan)
                tableHorizontalDivider
            }
        }
    }

    private func planCell(_ plan: DefaultPlan) -> some View {
        Label(plan.name, systemImage: plan.systemImage)
            .font(.subheadline.weight(.medium))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(width: planColumnWidth, height: rowHeight, alignment: .leading)
            .background(Color(uiColor: .systemBackground))
            .contentShape(Rectangle())
            .onLongPressGesture { showsDefaultPlanMessage = true }
            .accessibilityIdentifier("defaultPlan-\(plan.id)")
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
            ForEach(plans) { plan in
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
                .frame(width: width, height: rowHeight)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(accessibilitySummary(for: plan))
                .accessibilityIdentifier("defaultPlanValues-\(plan.id)")
                tableHorizontalDivider
            }
        }
        .frame(width: width, alignment: .leading)
        .accessibilityIdentifier("summaryPlanValues")
    }

    private var probabilityValues: some View {
        LazyVStack(spacing: 0) {
            ForEach(plans) { plan in
                HStack(spacing: 0) {
                    ForEach(Array(plan.turnProbabilities.enumerated()), id: \.offset) { _, probability in
                        placeholderCell("\(probability)%", width: probabilityColumnWidth)
                    }
                }
                .frame(width: probabilityGroupWidth, height: rowHeight, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(plan.name) cumulative completion probabilities")
                .accessibilityIdentifier("defaultPlanProbabilities-\(plan.id)")
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
        CGFloat(plans.count) * (rowHeight + 1)
    }

    private var plans: [DefaultPlan] {
        DefaultPlan.placeholders(for: selectedPlayer)
    }

    private func beginNewPlan(kind: CustomPlanKind) {
        editingPlan = CustomPlan(
            name: kind == .cards ? "New Cards Plan" : "New Construction Plan",
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
}

#Preview {
    PlanBrowserView(selectedPlayer: .constant(.red))
}
