import SwiftUI

struct ResourceCardView: View {
    let resource: ResourceCard
    var showsAddBadge = false
    var showsWhiteOutline = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 8)
                .fill(cardColor)
                .overlay {
                    if showsWhiteOutline {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.white, lineWidth: 2)
                    }
                }
                .aspectRatio(2.5 / 3.5, contentMode: .fit)

            Image(systemName: resource.systemImage)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if showsAddBadge {
                Image(systemName: "plus.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Color.accentColor)
                    .offset(x: 5, y: -5)
            }
        }
        .accessibilityLabel("\(resource.displayName) card")
    }

    private var iconColor: Color {
        resource == .ore ? .white : .black.opacity(0.72)
    }

    private var cardColor: Color {
        switch resource {
        case .brick: Color(red: 0.68, green: 0.25, blue: 0.08)
        case .wood: Color(red: 0.08, green: 0.36, blue: 0.17)
        case .hay: Color(red: 0.72, green: 0.76, blue: 0.18)
        case .sheep: Color(red: 0.55, green: 0.82, blue: 0.43)
        case .ore: Color(red: 0.25, green: 0.31, blue: 0.38)
        }
    }
}
