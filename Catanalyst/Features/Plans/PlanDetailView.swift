import SwiftUI

struct PlanDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedPlayer: PlayerColor
    @State private var plan: CustomPlan
    @State private var isEditing = false

    let onSave: (CustomPlan) -> Void

    init(
        plan: CustomPlan,
        selectedPlayer: Binding<PlayerColor>,
        onSave: @escaping (CustomPlan) -> Void
    ) {
        _plan = State(initialValue: plan)
        _selectedPlayer = selectedPlayer
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: plan.icon)
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)
                Text(plan.name).font(.title2.bold())
                Button("Edit") { isEditing = true }
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
            .sheet(isPresented: $isEditing) {
                PlanEditorView(plan: plan, selectedPlayer: $selectedPlayer) { updated in
                    plan = updated
                    onSave(updated)
                }
            }
        }
        .accessibilityIdentifier("planDetail")
    }
}
