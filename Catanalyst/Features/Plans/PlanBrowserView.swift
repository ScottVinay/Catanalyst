import SwiftUI

struct PlanBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scrollOffset = CGPoint.zero

    private let summaryColumns = ["Mean", "Median", "25th", "75th"]
    private let planColumnWidth: CGFloat = 150
    private let summaryColumnWidth: CGFloat = 68
    private let probabilityColumnWidth: CGFloat = 58

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
        ScrollView([.horizontal, .vertical]) {
            LazyVStack(spacing: 0) {
                superHeader
                tableHeader
                Divider()
                ForEach(DefaultPlan.placeholders) { plan in
                    planRow(plan)
                    Divider()
                }
            }
            .padding(.horizontal)
        }
        .onScrollGeometryChange(for: CGPoint.self) { geometry in
            geometry.contentOffset
        } action: { _, newOffset in
            scrollOffset = newOffset
        }
        .accessibilityIdentifier("defaultPlanTable")
    }

    private var superHeader: some View {
        HStack(spacing: 0) {
            Color.clear
                .frame(width: planColumnWidth, height: 30)
                .background(Color(uiColor: .systemBackground))
                .offset(x: stickyHorizontalOffset)
                .zIndex(3)

            tableCell(
                "Turns until acquired/built",
                width: summaryColumnWidth * CGFloat(summaryColumns.count),
                height: 30
            )
            tableCell(
                "Probability of being acquired/built within N turns",
                width: probabilityColumnWidth * 10,
                height: 30
            )
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
        .background(Color(uiColor: .systemBackground))
        .offset(y: stickyVerticalOffset)
        .zIndex(2)
        .accessibilityIdentifier("planSuperHeader")
    }

    private var tableHeader: some View {
        HStack(spacing: 0) {
            tableCell("Plan", width: planColumnWidth, height: 34, alignment: .leading)
                .background(Color(uiColor: .systemBackground))
                .offset(x: stickyHorizontalOffset)
                .zIndex(3)
            ForEach(summaryColumns, id: \.self) { title in
                tableCell(title, width: summaryColumnWidth, height: 34)
            }
            ForEach(1...10, id: \.self) { turn in
                tableCell("T\(turn)", width: probabilityColumnWidth, height: 34)
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .background(Color(uiColor: .systemBackground))
        .offset(y: stickyVerticalOffset)
        .zIndex(2)
        .accessibilityIdentifier("planColumnHeader")
    }

    private func planRow(_ plan: DefaultPlan) -> some View {
        HStack(spacing: 0) {
            Label(plan.name, systemImage: plan.systemImage)
                .font(.subheadline.weight(.medium))
                .frame(width: planColumnWidth, height: 44, alignment: .leading)
                .background(Color(uiColor: .systemBackground))
                .offset(x: stickyHorizontalOffset)
                .zIndex(1)

            placeholderCell(plan.mean.formatted(.number.precision(.fractionLength(1))))
            placeholderCell(plan.median.formatted(.number.precision(.fractionLength(0))))
            placeholderCell(plan.percentile25.formatted(.number.precision(.fractionLength(0))))
            placeholderCell(plan.percentile75.formatted(.number.precision(.fractionLength(0))))

            ForEach(Array(plan.turnProbabilities.enumerated()), id: \.offset) { _, probability in
                placeholderCell("\(probability)%", width: probabilityColumnWidth)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary(for: plan))
        .accessibilityIdentifier("defaultPlan-\(plan.id)")
    }

    private func placeholderCell(_ value: String, width: CGFloat = 68) -> some View {
        Text(value)
            .font(.subheadline.monospacedDigit())
            .foregroundStyle(.red)
            .frame(width: width, height: 44)
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

    private func accessibilitySummary(for plan: DefaultPlan) -> String {
        "\(plan.name), placeholder mean \(plan.mean.formatted(.number.precision(.fractionLength(1)))) turns, median \(Int(plan.median)) turns"
    }

    private var stickyHorizontalOffset: CGFloat {
        max(0, scrollOffset.x)
    }

    private var stickyVerticalOffset: CGFloat {
        max(0, scrollOffset.y)
    }
}

#Preview {
    PlanBrowserView()
}
