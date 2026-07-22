import SwiftUI

private struct ActiveHexPicker: Equatable {
    let coordinate: HexCoordinate
    var selectedIndex: Int?
}

struct BoardEditorView: View {
    let board: BoardState
    let isEditing: Bool
    let editTool: BoardEditTool
    let isDetailZoom: Bool

    @State private var activePicker: ActiveHexPicker?

    var body: some View {
        GeometryReader { proxy in
            let availableSize = proxy.size
            let baseSize = min(
                availableSize.width / (sqrt(3) * 5.6),
                availableSize.height / 9.0
            )
            let hexSize = baseSize * (isDetailZoom ? 1.22 : 1)
            let origin = CGPoint(x: availableSize.width / 2, y: availableSize.height / 2)

            ZStack {
                ForEach(board.tiles) { tile in
                    HexTileView(tile: tile, hexSize: hexSize)
                        .position(BoardGeometry.center(
                            for: tile.coordinate,
                            hexSize: hexSize,
                            origin: origin
                        ))
                        .gesture(hexEditingGesture(for: tile, hexSize: hexSize))
                }

                ForEach(Array(board.roads)) { edge in
                    RoadView(edge: edge, hexSize: hexSize, origin: origin)
                }

                ForEach(Array(board.buildings.keys), id: \.self) { vertex in
                    if let building = board.buildings[vertex] {
                        BuildingView(building: building, hexSize: hexSize)
                            .position(BoardGeometry.point(
                                for: vertex,
                                hexSize: hexSize,
                                origin: origin
                            ))
                    }
                }

                if isEditing && activePicker == nil {
                    structuralEditingTargets(hexSize: hexSize, origin: origin)
                }

                if let activePicker,
                   let tile = board.tiles.first(where: { $0.coordinate == activePicker.coordinate }) {
                    selectionWheel(
                        around: BoardGeometry.center(
                            for: tile.coordinate,
                            hexSize: hexSize,
                            origin: origin
                        ),
                        hexSize: hexSize,
                        selectedIndex: activePicker.selectedIndex
                    )
                }
            }
            .animation(.easeInOut(duration: 0.18), value: isDetailZoom)
            .onChange(of: isEditing) { _, editing in
                if !editing { activePicker = nil }
            }
            .onChange(of: editTool) { _, _ in
                activePicker = nil
            }
        }
        .padding(8)
    }

    @ViewBuilder
    private func structuralEditingTargets(hexSize: CGFloat, origin: CGPoint) -> some View {
        ForEach(BoardGeometry.standardEdges) { edge in
            let start = BoardGeometry.point(for: edge.start, hexSize: hexSize, origin: origin)
            let end = BoardGeometry.point(for: edge.end, hexSize: hexSize, origin: origin)
            let midpoint = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
            let length = hypot(end.x - start.x, end.y - start.y)
            let angle = atan2(end.y - start.y, end.x - start.x)

            Capsule()
                .fill(.clear)
                .contentShape(Capsule())
                .frame(width: length, height: max(16, hexSize * 0.32))
                .rotationEffect(.radians(angle))
                .position(midpoint)
                .onTapGesture { board.toggleRoad(on: edge) }
                .accessibilityLabel(board.roads.contains(edge) ? "Remove road" : "Add road")
                .accessibilityAddTraits(.isButton)
        }

        ForEach(BoardGeometry.standardVertices) { vertex in
            Circle()
                .fill(.clear)
                .contentShape(Circle())
                .frame(width: max(22, hexSize * 0.46), height: max(22, hexSize * 0.46))
                .position(BoardGeometry.point(for: vertex, hexSize: hexSize, origin: origin))
                .onTapGesture { board.cycleBuilding(at: vertex) }
                .accessibilityLabel("Change building")
                .accessibilityAddTraits(.isButton)
        }
    }

    private func hexEditingGesture(for tile: HexTile, hexSize: CGFloat) -> some Gesture {
        LongPressGesture(minimumDuration: 0.35)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { value in
                guard isEditing else { return }
                switch value {
                case .first(true):
                    activePicker = ActiveHexPicker(coordinate: tile.coordinate)
                case let .second(true, drag):
                    activePicker = ActiveHexPicker(
                        coordinate: tile.coordinate,
                        selectedIndex: selectionIndex(
                            for: drag?.translation ?? .zero,
                            hexSize: hexSize
                        )
                    )
                default:
                    break
                }
            }
            .onEnded { value in
                guard isEditing else { return }
                var translation = CGSize.zero
                if case let .second(_, drag) = value {
                    translation = drag?.translation ?? .zero
                }
                applySelection(
                    selectionIndex(for: translation, hexSize: hexSize),
                    to: tile.coordinate
                )
                activePicker = nil
            }
    }

    private var optionCount: Int {
        switch editTool {
        case .terrain: Terrain.allCases.count
        case .number: NumberToken.allCases.count
        }
    }

    private func selectionIndex(for translation: CGSize, hexSize: CGFloat) -> Int? {
        let distance = hypot(translation.width, translation.height)
        guard distance >= hexSize * 0.48 else { return nil }

        let startAngle = -Double.pi / 2
        let step = 2 * Double.pi / Double(optionCount)
        var relativeAngle = atan2(translation.height, translation.width) - startAngle
        if relativeAngle < 0 { relativeAngle += 2 * Double.pi }
        return Int((relativeAngle / step).rounded()) % optionCount
    }

    private func applySelection(_ index: Int?, to coordinate: HexCoordinate) {
        guard let index else { return }
        switch editTool {
        case .terrain:
            board.setTerrain(Terrain.allCases[index], at: coordinate)
        case .number:
            board.setNumber(NumberToken.allCases[index], at: coordinate)
        }
    }

    @ViewBuilder
    private func selectionWheel(
        around center: CGPoint,
        hexSize: CGFloat,
        selectedIndex: Int?
    ) -> some View {
        let radius = hexSize * 1.55
        ForEach(0..<optionCount, id: \.self) { index in
            let angle = (-Double.pi / 2) + (2 * Double.pi * Double(index) / Double(optionCount))
            let selected = selectedIndex == index
            pickerOption(at: index, selected: selected)
                .frame(
                    width: selected ? hexSize * 0.72 : hexSize * 0.58,
                    height: selected ? hexSize * 0.72 : hexSize * 0.58
                )
                .position(
                    x: center.x + CGFloat(cos(angle)) * radius,
                    y: center.y + CGFloat(sin(angle)) * radius
                )
                .shadow(radius: selected ? 4 : 1)
        }
    }

    @ViewBuilder
    private func pickerOption(at index: Int, selected: Bool) -> some View {
        switch editTool {
        case .terrain:
            let terrain = Terrain.allCases[index]
            Circle()
                .fill(terrain.color)
                .overlay(Circle().stroke(selected ? Color.primary : .white, lineWidth: selected ? 4 : 2))
                .accessibilityLabel(terrain.displayName)
        case .number:
            let token = NumberToken.allCases[index]
            Circle()
                .fill(Color.tokenBackground)
                .overlay {
                    Text("\(token.rawValue)")
                        .font(.caption.bold())
                        .foregroundStyle(token.isHighProbability ? .red : .primary)
                }
                .overlay(Circle().stroke(selected ? Color.primary : .white, lineWidth: selected ? 4 : 2))
                .accessibilityLabel("Number \(token.rawValue)")
        }
    }
}

private struct HexTileView: View {
    let tile: HexTile
    let hexSize: CGFloat

    var body: some View {
        Hexagon()
            .fill(tile.terrain.color)
            .overlay(Hexagon().stroke(.white.opacity(0.85), lineWidth: max(1.5, hexSize * 0.04)))
            .overlay {
                if let number = tile.number {
                    NumberTokenView(token: number, size: hexSize * 0.8)
                } else if tile.terrain == .ocean {
                    Image(systemName: "water.waves")
                        .foregroundStyle(.white.opacity(0.75))
                        .font(.system(size: hexSize * 0.34))
                }
            }
            .frame(width: sqrt(3) * hexSize, height: 2 * hexSize)
            .contentShape(Hexagon())
            .accessibilityElement(children: .combine)
            .accessibilityLabel(tileAccessibilityLabel)
    }

    private var tileAccessibilityLabel: String {
        if let number = tile.number {
            return "\(tile.terrain.displayName) hex, number \(number.rawValue)"
        }
        return "\(tile.terrain.displayName) hex"
    }
}

private struct NumberTokenView: View {
    let token: NumberToken
    let size: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            Text("\(token.rawValue)")
                .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
            HStack(spacing: 1) {
                ForEach(0..<token.pipCount, id: \.self) { _ in
                    Circle().frame(width: max(2, size * 0.055), height: max(2, size * 0.055))
                }
            }
        }
        .foregroundStyle(token.isHighProbability ? .red : .black)
        .frame(width: size, height: size)
        .background(Color.tokenBackground, in: Circle())
    }
}

private struct RoadView: View {
    let edge: BoardEdge
    let hexSize: CGFloat
    let origin: CGPoint

    var body: some View {
        let start = BoardGeometry.point(for: edge.start, hexSize: hexSize, origin: origin)
        let end = BoardGeometry.point(for: edge.end, hexSize: hexSize, origin: origin)
        let midpoint = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
        let length = hypot(end.x - start.x, end.y - start.y)
        let angle = atan2(end.y - start.y, end.x - start.x)

        Capsule()
            .fill(.red)
            .overlay(Capsule().stroke(.white, lineWidth: 1))
            .frame(width: length * 0.82, height: max(6, hexSize * 0.16))
            .rotationEffect(.radians(angle))
            .position(midpoint)
            .accessibilityHidden(true)
    }
}

private struct BuildingView: View {
    let building: Building
    let hexSize: CGFloat

    var body: some View {
        Image(systemName: building == .city ? "building.2.fill" : "house.fill")
            .font(.system(size: building == .city ? hexSize * 0.42 : hexSize * 0.34))
            .foregroundStyle(.red)
            .padding(2)
            .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 3))
            .accessibilityHidden(true)
    }
}

private struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width / sqrt(3), rect.height / 2)
        var path = Path()
        for index in 0..<6 {
            let angle = (-Double.pi / 2) + Double(index) * Double.pi / 3
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            index == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}

private extension Terrain {
    var color: Color {
        switch self {
        case .brick: .brick
        case .ore: .ore
        case .wheat: .wheat
        case .lumber: .lumber
        case .wool: .wool
        case .desert: .desert
        case .ocean: .ocean
        }
    }
}

private extension Color {
    static let brick = Color(red: 0.72, green: 0.24, blue: 0.16)
    static let ore = Color(red: 0.42, green: 0.45, blue: 0.48)
    static let wheat = Color(red: 0.90, green: 0.68, blue: 0.20)
    static let lumber = Color(red: 0.16, green: 0.42, blue: 0.22)
    static let wool = Color(red: 0.48, green: 0.72, blue: 0.33)
    static let desert = Color(red: 0.82, green: 0.67, blue: 0.43)
    static let ocean = Color(red: 0.14, green: 0.48, blue: 0.68)
    static let tokenBackground = Color(red: 0.94, green: 0.88, blue: 0.70)
}
