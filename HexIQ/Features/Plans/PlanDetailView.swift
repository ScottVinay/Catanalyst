import SwiftUI

struct PlanDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let plan: CustomPlan
    let onEdit: (CustomPlan) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: plan.icon)
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)
                Text(plan.name).font(.title2.bold())
                Button("Edit") { onEdit(plan) }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("editCustomPlanButton")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .accessibilityIdentifier("planDetail")
    }
}
