import SwiftUI

struct ChangePlayersView: View {
    @Environment(\.dismiss) private var dismiss
    let board: BoardState
    @State private var pendingRemoval: PlayerColor?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Choose the player colours in this game.")
                    .foregroundStyle(.secondary)

                PlayerMultiSelector(selection: activeSelection) { player in
                    requestRemoval(player)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Change players")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .accessibilityIdentifier("closeChangePlayersButton")
                }
            }
            .alert(
                "Removing this player will remove their resources, cards, and plans.",
                isPresented: Binding(
                    get: { pendingRemoval != nil },
                    set: { if !$0 { pendingRemoval = nil } }
                ),
            ) {
                Button("Continue", role: .destructive) {
                    if let pendingRemoval { board.removePlayer(pendingRemoval) }
                    pendingRemoval = nil
                }
                Button("Cancel", role: .cancel) { pendingRemoval = nil }
            }
        }
        .accessibilityIdentifier("changePlayersScreen")
    }

    private var activeSelection: Binding<Set<PlayerColor>> {
        Binding(
            get: { Set(board.activePlayers) },
            set: { updated in
                let current = Set(board.activePlayers)
                for player in updated.subtracting(current) { board.addPlayer(player) }
            }
        )
    }

    private func requestRemoval(_ player: PlayerColor) {
        guard board.activePlayers.count > 1 else { return }
        if board.hasStoredState(for: player) {
            pendingRemoval = player
        } else {
            board.removePlayer(player)
        }
    }
}
