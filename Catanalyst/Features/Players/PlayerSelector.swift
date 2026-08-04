import SwiftUI

struct PlayerSelector: View {
    @Binding var selection: PlayerColor
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(spacing: 8) {
            playerButton(selection, isCurrent: true) {
                withAnimation(.easeInOut(duration: 0.18)) {
                    isExpanded.toggle()
                }
            }

            if isExpanded {
                ForEach(PlayerColor.allCases.filter { $0 != selection }) { player in
                    playerButton(player, isCurrent: false) {
                        selection = player
                        withAnimation(.easeInOut(duration: 0.18)) {
                            isExpanded = false
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .padding(6)
        .background(.ultraThinMaterial, in: Capsule())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("playerSelector")
    }

    private func playerButton(
        _ player: PlayerColor,
        isCurrent: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Circle()
                .fill(player.color)
                .overlay(Circle().stroke(.primary.opacity(0.35), lineWidth: player == .white ? 1.5 : 0.5))
                .frame(width: 30, height: 30)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            isCurrent
                ? "Selected player, \(player.displayName)"
                : "Select \(player.displayName) player"
        )
        .accessibilityValue(isCurrent ? (isExpanded ? "Expanded" : "Collapsed") : "")
        .accessibilityIdentifier(
            isCurrent ? "selectedPlayerButton" : "selectPlayer-\(player.rawValue)"
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
