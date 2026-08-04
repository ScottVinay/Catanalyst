import SwiftUI

struct ConstructionPlacementView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var placedStep: PlannedConstructionStep?
    @State private var completionTask: Task<Void, Never>?

    let board: BoardState
    let player: PlayerColor
    let kind: PlannedConstructionKind
    let priorSteps: [PlannedConstructionStep]
    let onPlace: (PlannedConstructionStep) -> Void

    var body: some View {
        NavigationStack {
            BoardEditorView(
                board: board,
                isEditing: false,
                editTool: .terrain,
                selectedPlayer: player,
                placementMode: placedStep == nil ? kind : nil,
                ghostSteps: priorSteps + [placedStep].compactMap { $0 }
            ) { step in
                guard placedStep == nil else { return }
                placedStep = step
                completionTask = Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(800))
                    guard !Task.isCancelled else { return }
                    onPlace(step)
                    dismiss()
                }
            }
            .navigationTitle("Placing \(kind.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        completionTask?.cancel()
                        dismiss()
                    }
                        .accessibilityIdentifier("cancelConstructionPlacementButton")
                }
            }
            .overlay(alignment: .bottom) {
                if let placedStep {
                    Label("Placed \(placedStep.kind.displayName)", systemImage: "checkmark.circle.fill")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.regularMaterial, in: Capsule())
                        .padding(.bottom, 20)
                        .accessibilityIdentifier("plannedPlacementConfirmation")
                }
            }
        }
        .accessibilityIdentifier("constructionPlacement")
        .onDisappear { completionTask?.cancel() }
    }
}

struct ConstructionPlanPreviewView: View {
    @Environment(\.dismiss) private var dismiss

    let board: BoardState
    let player: PlayerColor
    let steps: [PlannedConstructionStep]

    var body: some View {
        NavigationStack {
            BoardEditorView(
                board: board,
                isEditing: false,
                editTool: .terrain,
                selectedPlayer: player,
                placementMode: nil,
                ghostSteps: steps
            )
            .navigationTitle("Plan preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .accessibilityIdentifier("closeConstructionPreviewButton")
                }
            }
        }
        .accessibilityIdentifier("constructionPlanPreview")
    }
}
