import SwiftUI

private struct ActiveHexPicker: Equatable {
    let coordinate: HexCoordinate
}

private enum NumberPickerOption {
    case token(NumberToken)
    case remove

    static let all: [NumberPickerOption] = NumberToken.allCases.map(Self.token) + [.remove]
}

struct BoardEditorView: View {
    let board: BoardState
    let isEditing: Bool
    let editTool: BoardEditTool
    let selectedPlayer: PlayerColor

    @State private var activePicker: ActiveHexPicker?
    @State private var viewport = BoardViewport()
    @GestureState private var transientPan = CGSize.zero

    var body: some View {
        GeometryReader { proxy in
            let availableSize = proxy.size
            let baseSize = min(
                availableSize.width / (sqrt(3) * 5.6),
                availableSize.height / 9.0
            )
            let hexSize = baseSize * viewport.scale
            let pan = viewport.zoom == .detail
                ? CGSize(
                    width: viewport.offset.width + transientPan.width,
                    height: viewport.offset.height + transientPan.height
                )
                : .zero
            let origin = CGPoint(
                x: (availableSize.width / 2) + pan.width,
                y: (availableSize.height / 2) + pan.height
            )

            ZStack {
                ForEach(board.tiles) { tile in
                    HexTileView(tile: tile, hexSize: hexSize)
                        .position(BoardGeometry.center(
                            for: tile.coordinate,
                            hexSize: hexSize,
                            origin: origin
                        ))
                        .onTapGesture {
                            tappedHex(
                                tile.coordinate,
                                hexSize: hexSize,
                                containerSize: availableSize
                            )
                        }
                }

                ForEach(Array(board.roads)) { edge in
                    let owner = board.owner(of: edge)
                    RoadView(
                        edge: edge,
                        hexSize: hexSize,
                        origin: origin,
                        color: owner.color,
                        outlineColor: owner == .white ? .gray : .white
                    )
                }

                ForEach(Array(board.buildings.keys), id: \.self) { vertex in
                    if let building = board.buildings[vertex] {
                        BuildingView(
                            building: building,
                            hexSize: hexSize,
                            color: board.owner(of: vertex).color
                        )
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
                        hexSize: hexSize
                    )
                }
            }
            .contentShape(Rectangle())
            .simultaneousGesture(magnificationGesture)
            .simultaneousGesture(panGesture(in: availableSize))
            .animation(.easeInOut(duration: 0.18), value: viewport)
            .onChange(of: isEditing) { _, editing in
                if !editing { activePicker = nil }
            }
            .onChange(of: editTool) { _, _ in
                activePicker = nil
            }
        }
        .padding(8)
    }

    private var magnificationGesture: some Gesture {
        MagnifyGesture()
            .onEnded { value in
                viewport.finishMagnification(value.magnification)
            }
    }

    private func panGesture(in containerSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .updating($transientPan) { value, state, _ in
                guard viewport.zoom == .detail else { return }
                state = value.translation
            }
            .onEnded { value in
                viewport.finishPan(value.translation, in: containerSize)
            }
    }

    private func tappedHex(
        _ coordinate: HexCoordinate,
        hexSize: CGFloat,
        containerSize: CGSize
    ) {
        if viewport.zoom == .detail {
            let boardPoint = BoardGeometry.center(
                for: coordinate,
                hexSize: hexSize,
                origin: .zero
            )
            viewport.center(on: boardPoint, in: containerSize)
        }

        guard isEditing else { return }
        if activePicker?.coordinate == coordinate {
            activePicker = nil
        } else {
            activePicker = ActiveHexPicker(coordinate: coordinate)
        }
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
                .onTapGesture { board.toggleRoad(on: edge, for: selectedPlayer) }
                .accessibilityLabel(roadEditingLabel(for: edge))
                .accessibilityAddTraits(.isButton)
        }

        ForEach(BoardGeometry.standardVertices) { vertex in
            Circle()
                .fill(.clear)
                .contentShape(Circle())
                .frame(width: max(22, hexSize * 0.46), height: max(22, hexSize * 0.46))
                .position(BoardGeometry.point(for: vertex, hexSize: hexSize, origin: origin))
                .onTapGesture { board.cycleBuilding(at: vertex, for: selectedPlayer) }
                .accessibilityLabel(buildingEditingLabel(for: vertex))
                .accessibilityAddTraits(.isButton)
        }
    }

    private func roadEditingLabel(for edge: BoardEdge) -> String {
        guard board.roads.contains(edge) else { return "Add \(selectedPlayer.displayName) road" }
        let owner = board.owner(of: edge)
        return owner == selectedPlayer
            ? "Remove \(owner.displayName) road"
            : "Road owned by \(owner.displayName) player"
    }

    private func buildingEditingLabel(for vertex: BoardVertex) -> String {
        guard board.buildings[vertex] != nil else {
            return "Add \(selectedPlayer.displayName) settlement"
        }
        let owner = board.owner(of: vertex)
        return owner == selectedPlayer
            ? "Change \(owner.displayName) building"
            : "Building owned by \(owner.displayName) player"
    }

    private var optionCount: Int {
        switch editTool {
        case .terrain: Terrain.allCases.count
        case .number: NumberPickerOption.all.count
        }
    }

    private func applySelection(_ index: Int, to coordinate: HexCoordinate) {
        switch editTool {
        case .terrain:
            board.setTerrain(Terrain.allCases[index], at: coordinate)
        case .number:
            switch NumberPickerOption.all[index] {
            case let .token(token):
                board.setNumber(token, at: coordinate)
            case .remove:
                board.clearNumber(at: coordinate)
            }
        }
    }

    @ViewBuilder
    private func selectionWheel(
        around center: CGPoint,
        hexSize: CGFloat
    ) -> some View {
        let radius = hexSize * 1.55
        ForEach(0..<optionCount, id: \.self) { index in
            let angle = (-Double.pi / 2) + (2 * Double.pi * Double(index) / Double(optionCount))
            Button {
                guard let coordinate = activePicker?.coordinate else { return }
                applySelection(index, to: coordinate)
                activePicker = nil
            } label: {
                pickerOption(at: index)
            }
                .buttonStyle(RadialPickerButtonStyle())
                .frame(width: hexSize * 0.62, height: hexSize * 0.62)
                .position(
                    x: center.x + CGFloat(cos(angle)) * radius,
                    y: center.y + CGFloat(sin(angle)) * radius
                )
                .shadow(radius: 2)
        }
    }

    @ViewBuilder
    private func pickerOption(at index: Int) -> some View {
        switch editTool {
        case .terrain:
            let terrain = Terrain.allCases[index]
            Circle()
                .fill(terrain.color)
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .accessibilityLabel(terrain.displayName)
        case .number:
            switch NumberPickerOption.all[index] {
            case let .token(token):
                Circle()
                    .fill(Color.tokenBackground)
                    .overlay {
                        Text("\(token.rawValue)")
                            .font(.caption.bold())
                            .foregroundStyle(token.isHighProbability ? .red : .primary)
                    }
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                    .accessibilityLabel("Number \(token.rawValue)")
            case .remove:
                Circle()
                    .fill(Color.tokenBackground)
                    .overlay {
                        Image(systemName: "xmark")
                            .font(.caption.bold())
                            .foregroundStyle(.primary)
                    }
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                    .accessibilityLabel("Remove number")
            }
        }
    }
}

private struct RadialPickerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.18 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
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
            .accessibilityValue(tile.terrain.displayName)
            .accessibilityIdentifier("hex-\(tile.coordinate.id)")
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
    let color: Color
    let outlineColor: Color

    var body: some View {
        let start = BoardGeometry.point(for: edge.start, hexSize: hexSize, origin: origin)
        let end = BoardGeometry.point(for: edge.end, hexSize: hexSize, origin: origin)
        let midpoint = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
        let length = hypot(end.x - start.x, end.y - start.y)
        let angle = atan2(end.y - start.y, end.x - start.x)

        Capsule()
            .fill(color)
            .overlay(Capsule().stroke(outlineColor, lineWidth: 1))
            .frame(width: length * 0.82, height: max(6, hexSize * 0.16))
            .rotationEffect(.radians(angle))
            .position(midpoint)
            .accessibilityHidden(true)
    }
}

private struct BuildingView: View {
    let building: Building
    let hexSize: CGFloat
    let color: Color

    var body: some View {
        Image(systemName: building == .city ? "building.2.fill" : "house.fill")
            .font(.system(size: building == .city ? hexSize * 0.42 : hexSize * 0.34))
            .foregroundStyle(color)
            .shadow(color: .black.opacity(0.45), radius: 0.8)
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
