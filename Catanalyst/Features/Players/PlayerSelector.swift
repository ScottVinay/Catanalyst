import SwiftUI

struct PlayerSelector: View {
    @Binding var selection: PlayerColor

    var body: some View {
        HStack(spacing: 7) {
            Text("Player:")
                .font(.subheadline.weight(.semibold))

            ForEach(PlayerColor.allCases) { player in
                playerButton(player) {
                    selection = player
                }
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
                    if player == selection {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(player == .white ? .black : .white)
                    }
                }
                .frame(width: 30, height: 30)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(player == selection
            ? "Selected player, \(player.displayName)"
            : "Select \(player.displayName) player")
        .accessibilityValue(player == selection ? "Selected" : "")
        .accessibilityAddTraits(player == selection ? .isSelected : [])
        .accessibilityIdentifier(
            player == selection ? "selectedPlayerButton" : "selectPlayer-\(player.rawValue)"
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
