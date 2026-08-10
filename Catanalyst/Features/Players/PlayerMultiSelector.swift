import SwiftUI

struct PlayerMultiSelector: View {
    @Binding var selection: Set<PlayerColor>
    var onRemove: ((PlayerColor) -> Void)? = nil

    var body: some View {
        HStack(spacing: 7) {
            Text("Players:")
                .font(.subheadline.weight(.semibold))

            ForEach(PlayerColor.allCases) { player in
                Button {
                    if selection.contains(player) {
                        if selection.count > 1 {
                            if let onRemove { onRemove(player) } else { selection.remove(player) }
                        }
                    } else {
                        selection.insert(player)
                    }
                } label: {
                    Circle()
                        .fill(player.color)
                        .overlay(Circle().stroke(.primary.opacity(0.35), lineWidth: player == .white ? 1.5 : 0.5))
                        .overlay {
                            if selection.contains(player) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(player == .white ? .black : .white)
                            }
                        }
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(player.displayName) player")
                .accessibilityValue(selection.contains(player) ? "Selected" : "Not selected")
                .accessibilityAddTraits(selection.contains(player) ? .isSelected : [])
                .accessibilityIdentifier("toggleGamePlayer-\(player.rawValue)")
            }
        }
        .padding(6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("gamePlayerSelector")
    }
}
