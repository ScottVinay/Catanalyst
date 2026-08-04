import SwiftUI

enum BoardEditTool: String, CaseIterable, Identifiable {
    case terrain = "Terrain"
    case number = "Numbers"

    var id: Self { self }
}

struct BoardScreen: View {
    let board: BoardState

    @State private var isEditing = false
    @State private var editTool = BoardEditTool.terrain
    @State private var isShowingPlans = false
    @State private var selectedPlayer = PlayerColor.red
    @State private var isSelectingPlayer = false
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    PlayerSelector(
                        selection: $selectedPlayer,
                        isExpanded: $isSelectingPlayer
                    )
                    .zIndex(1)

                    if isEditing {
                        Picker("Hex editing mode", selection: $editTool) {
                            ForEach(BoardEditTool.allCases) { tool in
                                Text(tool.rawValue).tag(tool)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("hexEditModePicker")
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                BoardEditorView(
                    board: board,
                    isEditing: isEditing,
                    editTool: editTool,
                    selectedPlayer: selectedPlayer
                )
                .accessibilityIdentifier("boardEditor")
            }
            .navigationTitle(isSelectingPlayer ? "Select player" : "Board")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                bottomBar
            }
            .sheet(isPresented: $isShowingPlans) {
                PlanBrowserView(selectedPlayer: $selectedPlayer)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if isEditing {
                Button {
                    isEditing = false
                } label: {
                    Label("Done", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("doneEditingButton")
            } else {
                toolbarButton("Edit", systemImage: "pencil") {
                    isEditing = true
                }
                .accessibilityIdentifier("editBoardButton")

                toolbarButton("Plans", systemImage: "list.bullet.rectangle") {
                    isShowingPlans = true
                }
                .accessibilityIdentifier("plansButton")

                toolbarButton("Player", systemImage: "person.crop.circle") {}
                    .disabled(true)
                    .accessibilityHint("Player summaries are not available yet")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private func toolbarButton(
        _ title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .labelStyle(.titleAndIcon)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }
}
