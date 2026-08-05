import SwiftUI

struct PlayerSelector: View {
    @Binding var selection: PlayerColor
    private let allSelection: Binding<Bool>?

    init(selection: Binding<PlayerColor>, allSelection: Binding<Bool>? = nil) {
        _selection = selection
        self.allSelection = allSelection
    }

    var body: some View {
        HStack(spacing: 7) {
            Text("Player:")
                .font(.subheadline.weight(.semibold))

            ForEach(PlayerColor.allCases) { player in
                playerButton(player) {
                    allSelection?.wrappedValue = false
                    selection = player
                }
            }

            if let allSelection {
                Button {
                    allSelection.wrappedValue = true
                } label: {
                    Circle()
                        .fill(
                            AngularGradient(
                                gradient: Gradient(stops: PlayerColor.allCases.enumerated().flatMap { index, player in
                                    let start = Double(index) / Double(PlayerColor.allCases.count)
                                    let end = Double(index + 1) / Double(PlayerColor.allCases.count)
                                    return [
                                        Gradient.Stop(color: player.color, location: start),
                                        Gradient.Stop(color: player.color, location: end)
                                    ]
                                }),
                                center: .center
                            )
                        )
                        .overlay(Circle().stroke(.primary.opacity(0.35), lineWidth: 0.75))
                        .overlay {
                            if allSelection.wrappedValue {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                                    .shadow(radius: 1)
                            }
                        }
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(allSelection.wrappedValue ? "All players selected" : "Show all players")
                .accessibilityValue(allSelection.wrappedValue ? "Selected" : "")
                .accessibilityAddTraits(allSelection.wrappedValue ? .isSelected : [])
                .accessibilityIdentifier("selectAllPlayers")
            }
        }
        .padding(6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("playerSelector")
    }

    private func playerButton(
        _ player: PlayerColor,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Circle()
                .fill(player.color)
                .overlay(Circle().stroke(.primary.opacity(0.35), lineWidth: player == .white ? 1.5 : 0.5))
                .overlay {
                    if player == selection && allSelection?.wrappedValue != true {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(player == .white ? .black : .white)
                    }
                }
                .frame(width: 30, height: 30)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(player == selection && allSelection?.wrappedValue != true
            ? "Selected player, \(player.displayName)"
            : "Select \(player.displayName) player")
        .accessibilityValue(player == selection && allSelection?.wrappedValue != true ? "Selected" : "")
        .accessibilityAddTraits(player == selection && allSelection?.wrappedValue != true ? .isSelected : [])
        .accessibilityIdentifier(
            player == selection && allSelection?.wrappedValue != true
                ? "selectedPlayerButton"
                : "selectPlayer-\(player.rawValue)"
        )
    }
}

extension PlayerColor {
    var color: Color {
        switch self {
        case .red: .red
        case .blue: .blue
        case .white: .white
        case .orange: .orange
        case .green: .green
        case .brown: Color(red: 0.42, green: 0.24, blue: 0.12)
        }
    }
}
