import SwiftUI

enum BoardEditTool: String, CaseIterable, Identifiable {
    case terrain = "Terrain"
    case number = "Numbers"

    var id: Self { self }
}

private enum BoardZoom: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case detail = "Detail"

    var id: Self { self }
}

struct BoardScreen: View {
    let board: BoardState

    @State private var isEditing = false
    @State private var editTool = BoardEditTool.terrain
    @State private var zoom = BoardZoom.overview

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isEditing {
                    Picker("Hex editing mode", selection: $editTool) {
                        ForEach(BoardEditTool.allCases) { tool in
                            Text(tool.rawValue).tag(tool)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .accessibilityIdentifier("hexEditModePicker")
                } else {
                    Picker("Board zoom", selection: $zoom) {
                        ForEach(BoardZoom.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .frame(maxWidth: 300)
                }

                BoardEditorView(
                    board: board,
                    isEditing: isEditing,
                    editTool: editTool,
                    isDetailZoom: zoom == .detail
                )
                .accessibilityIdentifier("boardEditor")
            }
            .navigationTitle("Board")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                bottomBar
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

                toolbarButton("Plans", systemImage: "list.bullet.rectangle") {}
                    .disabled(true)
                    .accessibilityHint("Plan editing is not available yet")

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
