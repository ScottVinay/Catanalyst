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
    @State private var isShowingAnalysis = false
    @State private var isShowingHand = false
    @State private var selectedPlayer = PlayerColor.red
    @State private var isShowingEditHelp = false
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                BoardEditorView(
                    board: board,
                    isEditing: isEditing,
                    editTool: editTool,
                    selectedPlayer: selectedPlayer
                )
                .accessibilityIdentifier("boardEditor")

                VStack(spacing: 8) {
                    if isEditing {
                        ZStack {
                            Picker("Hex editing mode", selection: $editTool) {
                                ForEach(BoardEditTool.allCases) { tool in
                                    Text(tool.rawValue).tag(tool)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: 240)
                            .accessibilityIdentifier("hexEditModePicker")

                            HStack {
                                Spacer()
                                Button {
                                    isShowingEditHelp = true
                                } label: {
                                    Image(systemName: "questionmark.circle.fill")
                                        .font(.title2)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Board editing help")
                                .accessibilityIdentifier("boardEditHelpButton")
                            }
                        }
                    }

                    if isEditing {
                        HStack {
                            PlayerSelector(selection: $selectedPlayer)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .navigationTitle("Board")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Editing the board", isPresented: $isShowingEditHelp) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Choose Terrain or Numbers, then hold a hex to open its radial choices. Roads and buildings are edited by tapping their edges or vertices.")
            }
            .overlay(alignment: .bottom) {
                bottomBar
            }
            .sheet(isPresented: $isShowingAnalysis) {
                PlanBrowserView(board: board, selectedPlayer: $selectedPlayer)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isShowingHand) {
                HandView(selectedPlayer: $selectedPlayer, board: board)
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

                toolbarButton("Hand", systemImage: "rectangle.stack") {
                    isShowingHand = true
                }
                .accessibilityIdentifier("handButton")

                toolbarButton("Analysis", systemImage: "list.bullet.rectangle") {
                    isShowingAnalysis = true
                }
                .accessibilityIdentifier("analysisButton")
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
