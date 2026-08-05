import SwiftUI

struct HandView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedPlayer: PlayerColor
    let board: BoardState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PlayerSelector(selection: $selectedPlayer)

                    Text("These are the selected player's current cards. They affect the values shown in Analysis.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 12)
                        .accessibilityIdentifier("handHelperText")

                    HStack {
                        Text("Selected cards")
                            .font(.headline)
                        Spacer()
                        Button("Clear") { board.clearHand(for: selectedPlayer) }
                            .disabled(currentHand.isEmpty)
                            .accessibilityIdentifier("clearHandButton")
                    }

                    if currentHand.isEmpty {
                        Text("No cards in hand")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 120)
                            .accessibilityIdentifier("emptyHandCards")
                    } else {
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(ResourceCard.allCases.filter { currentHand[$0] > 0 }) { resource in
                                Button {
                                    board.removeCard(resource, from: selectedPlayer)
                                } label: {
                                    ResourceCardStackView(
                                        resource: resource,
                                        count: currentHand[resource],
                                        accessibilityIdentifier: "handSelectedCard-\(resource.rawValue)"
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("Removes one card from hand")
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Add cards").font(.headline)
                        HStack(spacing: 10) {
                            ForEach(ResourceCard.allCases) { resource in
                                Button {
                                    board.addCard(resource, to: selectedPlayer)
                                } label: {
                                    ResourceCardView(resource: resource, showsAddBadge: true)
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.plain)
                                .frame(maxWidth: .infinity)
                                .accessibilityLabel("Add \(resource.displayName) card to hand")
                                .accessibilityIdentifier("handAddCard-\(resource.rawValue)")
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Cards in hand")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .accessibilityIdentifier("closeHandButton")
                }
            }
        }
        .accessibilityIdentifier("handSheet")
    }

    private var currentHand: ResourceHand {
        board.hand(for: selectedPlayer)
    }
}
