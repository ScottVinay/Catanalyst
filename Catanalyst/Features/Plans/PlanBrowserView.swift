import SwiftUI

struct PlanBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scrollOffset = CGPoint.zero

    private let summaryColumns = ["Mean", "Median", "25th", "75th"]
    private let planColumnWidth: CGFloat = 118
    private let summaryColumnWidth: CGFloat = 54
    private let probabilityColumnWidth: CGFloat = 58
    private let superHeaderHeight: CGFloat = 30
    private let columnHeaderHeight: CGFloat = 34
    private let rowHeight: CGFloat = 44

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                tabSelector
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
        }
        .accessibilityIdentifier("planBrowser")
    }

    private var tabSelector: some View {
        HStack(spacing: 0) {
            Text("Default")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 7))
                .accessibilityAddTraits(.isSelected)

            Text("Custom")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .accessibilityLabel("Custom, unavailable")
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
                    scrollingHeaders
                        .frame(width: valuesViewportWidth)
                }
                .frame(height: headerHeight)

                tableHorizontalDivider

                HStack(spacing: 0) {
                    fixedPlanColumn
                    tableVerticalDivider
                    scrollingValues
                        .frame(width: valuesViewportWidth)
                }
                .frame(maxHeight: .infinity)
            }
            .background(Color(uiColor: .systemBackground))
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

    private var scrollingHeaders: some View {
        GeometryReader { _ in
            headerContent
                .offset(x: -scrollOffset.x)
                .frame(width: valuesContentWidth, alignment: .leading)
        }
        .clipped()
        .background(Color(uiColor: .systemBackground))
        .accessibilityIdentifier("planColumnHeader")
    }

    private var headerContent: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                tableCell(
                    "Turns until acquired/built",
                    width: summaryGroupWidth,
                    height: superHeaderHeight
                )
                tableHorizontalDivider
                HStack(spacing: 0) {
                    ForEach(summaryColumns, id: \.self) { title in
                        tableCell(title, width: summaryColumnWidth, height: columnHeaderHeight)
                    }
                }
            }

            tableVerticalDivider

            VStack(spacing: 0) {
                tableCell(
                    "Probability of being acquired/built within N turns",
                    width: probabilityGroupWidth,
                    height: superHeaderHeight
                )
                tableHorizontalDivider
                HStack(spacing: 0) {
                    ForEach(1...10, id: \.self) { turn in
                        tableCell("T\(turn)", width: probabilityColumnWidth, height: columnHeaderHeight)
                    }
                }
            }
        }
        .frame(width: valuesContentWidth, height: headerHeight, alignment: .leading)
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
        .background(Color(uiColor: .systemBackground))
        .accessibilityIdentifier("planSuperHeader")
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
            ForEach(DefaultPlan.placeholders) { plan in
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
            .accessibilityIdentifier("defaultPlan-\(plan.id)")
    }

    private var scrollingValues: some View {
        GeometryReader { proxy in
            ScrollView([.horizontal, .vertical]) {
                valuesContent
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
                scrollOffset = CGPoint(
                    x: max(0, newOffset.x),
                    y: max(0, newOffset.y)
                )
            }
            .clipped()
            .accessibilityIdentifier("planValuesTable")
        }
    }

    private var valuesContent: some View {
        LazyVStack(spacing: 0) {
            ForEach(DefaultPlan.placeholders) { plan in
                valuesRow(plan)
                tableHorizontalDivider
            }
        }
        .frame(width: valuesContentWidth, alignment: .leading)
    }

    private func valuesRow(_ plan: DefaultPlan) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                placeholderCell(plan.mean.formatted(.number.precision(.fractionLength(1))))
                placeholderCell(plan.median.formatted(.number.precision(.fractionLength(0))))
                placeholderCell(plan.percentile25.formatted(.number.precision(.fractionLength(0))))
                placeholderCell(plan.percentile75.formatted(.number.precision(.fractionLength(0))))
            }
            .frame(width: summaryGroupWidth)

            tableVerticalDivider

            HStack(spacing: 0) {
                ForEach(Array(plan.turnProbabilities.enumerated()), id: \.offset) { _, probability in
                    placeholderCell("\(probability)%", width: probabilityColumnWidth)
                }
            }
            .frame(width: probabilityGroupWidth)
        }
        .frame(width: valuesContentWidth, height: rowHeight, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary(for: plan))
        .accessibilityIdentifier("defaultPlanValues-\(plan.id)")
    }

    private func placeholderCell(_ value: String, width: CGFloat = 68) -> some View {
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

    private var summaryGroupWidth: CGFloat {
        summaryColumnWidth * CGFloat(summaryColumns.count)
    }

    private var probabilityGroupWidth: CGFloat {
        probabilityColumnWidth * 10
    }

    private var valuesContentWidth: CGFloat {
        summaryGroupWidth + 1 + probabilityGroupWidth
    }

    private var rowsContentHeight: CGFloat {
        CGFloat(DefaultPlan.placeholders.count) * (rowHeight + 1)
    }
}

#Preview {
    PlanBrowserView()
}
