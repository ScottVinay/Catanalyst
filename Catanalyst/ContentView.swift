import SwiftUI

struct ContentView: View {
    @State private var board: BoardState?

    var body: some View {
        Group {
            if let board {
                BoardScreen(board: board)
            } else {
                BoardSelectionScreen {
                    board = BoardState()
                }
            }
        }
    }
}

private struct BoardSelectionScreen: View {
    let createStandardBoard: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "hexagon.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.orange)

                VStack(spacing: 8) {
                    Text("Create a board")
                        .font(.largeTitle.bold())
                    Text("Choose the board size you want to enter.")
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 12) {
                    Button(action: createStandardBoard) {
                        BoardChoiceLabel(
                            title: "Standard board",
                            detail: "19 hexes · rows of 3, 4, 5, 4, 3"
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("standardBoardButton")

                    Button(action: {}) {
                        BoardChoiceLabel(title: "Large board", detail: "Coming later")
                    }
                    .buttonStyle(.bordered)
                    .disabled(true)

                    Button(action: {}) {
                        BoardChoiceLabel(title: "Custom board", detail: "Coming later")
                    }
                    .buttonStyle(.bordered)
                    .disabled(true)
                }
                .frame(maxWidth: 360)
            }
            .padding(24)
            .navigationTitle("Catanalyst")
        }
    }
}

private struct BoardChoiceLabel: View {
    let title: String
    let detail: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.caption)
            }
            Spacer()
            Image(systemName: "chevron.right")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
}

#Preview {
    ContentView()
}
