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
    var showsVertexValues = false
    var presentationRotationDegrees: Double? = nil
    var placementMode: PlannedConstructionKind? = nil
    var ghostSteps: [PlannedConstructionStep] = []
    var onPlaceStep: ((PlannedConstructionStep) -> Void)? = nil

    @State private var activePicker: ActiveHexPicker?
    @State private var highlightedPickerIndex: Int?
    @State private var pickerExpansion: CGFloat = 0
    @State private var suppressPanCompletion = false
    @State private var viewport = BoardViewport()
    @GestureState private var transientPan = CGSize.zero
    @GestureState private var isHexEditGestureActive = false
    @GestureState private var isMagnifying = false
    @State private var placementMessage: String?
    @State private var messageDismissalTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { proxy in
            let availableSize = proxy.size
            let baseSize = min(
                availableSize.width / (sqrt(3) * 5.6),
                availableSize.height / 9.0
            )
            let hexSize = baseSize * viewport.scale
            let restingOffset = viewport.displayOffset(in: availableSize)
            let pan = CGSize(
                width: restingOffset.width + transientPan.width,
                height: restingOffset.height + transientPan.height
            )
            let origin = CGPoint(
                x: (availableSize.width / 2) + pan.width,
                y: (availableSize.height / 2) + pan.height
            )
            let geometricCenter = BoardGeometry.geometricCenter(
                for: board.tiles.map(\.coordinate),
                hexSize: hexSize,
                origin: origin
            )
            let rotationAnchor = UnitPoint(
                x: availableSize.width == 0 ? 0.5 : geometricCenter.x / availableSize.width,
                y: availableSize.height == 0 ? 0.5 : geometricCenter.y / availableSize.height
            )
            let rotationDegrees = presentationRotationDegrees ?? board.orientation.degrees

            ZStack {
                ForEach(board.tiles) { tile in
                    HexTileView(
                        tile: tile,
                        hexSize: hexSize,
                        contentRotationDegrees: -rotationDegrees
                    )
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
                        .highPriorityGesture(
                            hexEditingGesture(
                                for: tile.coordinate,
                                center: BoardGeometry.center(
                                    for: tile.coordinate,
                                    hexSize: hexSize,
                                    origin: origin
                                ),
                                hexSize: hexSize
                            ),
                            including: isEditing ? .all : .none
                        )
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

                ghostRoads(hexSize: hexSize, origin: origin)

                if showsVertexValues {
                    vertexValues(hexSize: hexSize, origin: origin)
                } else {
                    ForEach(Array(board.buildings.keys), id: \.self) { vertex in
                        if let building = board.buildings[vertex] {
                            BuildingView(
                                building: building,
                                hexSize: hexSize,
                                color: board.owner(of: vertex).color
                            )
                                .rotationEffect(.degrees(-rotationDegrees))
                                .position(BoardGeometry.point(
                                    for: vertex,
                                    hexSize: hexSize,
                                    origin: origin
                                ))
                        }
                    }
                }

                ghostBuildings(
                    hexSize: hexSize,
                    origin: origin,
                    contentRotationDegrees: -rotationDegrees
                )

                if placementMode != nil {
                    constructionPlacementTargets(hexSize: hexSize, origin: origin)
                } else if isEditing && activePicker == nil {
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
                        contentRotationDegrees: -rotationDegrees
                    )
                }

                if let placementMessage {
                    Text(placementMessage)
                        .font(.subheadline.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 8)
                        .frame(maxWidth: 300)
                        .position(x: availableSize.width / 2, y: availableSize.height - 96)
                        .zIndex(20)
                        .accessibilityIdentifier("placementErrorMessage")
                }
            }
            .rotationEffect(
                .degrees(rotationDegrees),
                anchor: rotationAnchor
            )
            .coordinateSpace(.named("boardEditingSpace"))
            .contentShape(Rectangle())
            .simultaneousGesture(magnificationGesture)
            .simultaneousGesture(panGesture(in: availableSize))
            .animation(.easeInOut(duration: 0.18), value: viewport)
            .onChange(of: isEditing) { _, editing in
                if !editing { closePicker() }
            }
            .onChange(of: editTool) { _, _ in
                closePicker()
            }
            .onChange(of: isHexEditGestureActive) { _, isActive in
                if !isActive, activePicker != nil {
                    closePicker()
                }
            }
            .onChange(of: isMagnifying) { _, magnifying in
                if magnifying { closePicker() }
            }
        }
        .padding(8)
        .background(BoardWaterBackground())
    }

    private func vertexValues(hexSize: CGFloat, origin: CGPoint) -> some View {
        ForEach(BoardGeometry.standardVertices) { vertex in
            VertexValueView(
                value: BoardGeometry.pipValue(at: vertex, tiles: board.tiles),
                building: board.buildings[vertex],
                ownerColor: board.buildings[vertex] == nil ? nil : board.owner(of: vertex).color,
                hexSize: hexSize
            )
            .position(BoardGeometry.point(for: vertex, hexSize: hexSize, origin: origin))
            .accessibilityIdentifier("vertexValue-\(vertex.id)")
        }
    }

    private var magnificationGesture: some Gesture {
        MagnifyGesture()
            .updating($isMagnifying) { _, state, _ in state = true }
            .onEnded { value in
                viewport.finishMagnification(value.magnification)
            }
    }

    private func panGesture(in containerSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .updating($transientPan) { value, state, _ in
                guard viewport.zoom == .detail, activePicker == nil else { return }
                state = value.translation
            }
            .onEnded { value in
                if suppressPanCompletion {
                    suppressPanCompletion = false
                    return
                }
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

    }

    private func hexEditingGesture(
        for coordinate: HexCoordinate,
        center: CGPoint,
        hexSize: CGFloat
    ) -> some Gesture {
        LongPressGesture(
            minimumDuration: BoardHexEditGestureTiming.holdDuration(for: viewport.zoom),
            maximumDistance: 8
        )
            .sequenced(before: DragGesture(
                minimumDistance: 0,
                coordinateSpace: .named("boardEditingSpace")
            ))
            .updating($isHexEditGestureActive) { value, state, _ in
                switch value {
                case .first(true), .second(true, _):
                    state = true
                default:
                    break
                }
            }
            .onChanged { value in
                guard isEditing, !isMagnifying else { return }
                switch value {
                case .first(true):
                    openPicker(at: coordinate)
                    highlightedPickerIndex = nil
                case let .second(true, drag):
                    openPicker(at: coordinate)
                    highlightedPickerIndex = drag.flatMap {
                        pickerOptionIndex(at: $0.location, around: center, hexSize: hexSize)
                    }
                default:
                    break
                }
            }
            .onEnded { value in
                guard isEditing, !isMagnifying else { return }
                defer { closePicker() }
                guard case let .second(true, drag) = value,
                      let drag,
                      let index = pickerOptionIndex(
                        at: drag.location,
                        around: center,
                        hexSize: hexSize
                      ) else { return }
                applySelection(index, to: coordinate)
            }
    }

    private func openPicker(at coordinate: HexCoordinate) {
        guard activePicker?.coordinate != coordinate else { return }
        suppressPanCompletion = true
        activePicker = ActiveHexPicker(coordinate: coordinate)
        pickerExpansion = 0
        withAnimation(.easeOut(duration: 0.18)) {
            pickerExpansion = 1
        }
    }

    private func closePicker() {
        activePicker = nil
        highlightedPickerIndex = nil
        pickerExpansion = 0
        Task { @MainActor in
            await Task.yield()
            suppressPanCompletion = false
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
                .onTapGesture {
                    if let error = board.toggleRoad(on: edge, for: selectedPlayer) {
                        showPlacementError(error)
                    }
                }
                .accessibilityLabel(roadEditingLabel(for: edge))
                .accessibilityAddTraits(.isButton)
        }

        ForEach(BoardGeometry.standardVertices) { vertex in
            Circle()
                .fill(.clear)
                .contentShape(Circle())
                .frame(width: max(22, hexSize * 0.46), height: max(22, hexSize * 0.46))
                .position(BoardGeometry.point(for: vertex, hexSize: hexSize, origin: origin))
                .onTapGesture {
                    if let error = board.cycleBuilding(at: vertex, for: selectedPlayer) {
                        showPlacementError(error)
                    }
                }
                .accessibilityLabel(buildingEditingLabel(for: vertex))
                .accessibilityAddTraits(.isButton)
        }
    }

    @ViewBuilder
    private func ghostRoads(hexSize: CGFloat, origin: CGPoint) -> some View {
        ForEach(ghostSteps) { step in
            if case let .edge(edge) = step.location {
                RoadView(
                    edge: edge,
                    hexSize: hexSize,
                    origin: origin,
                    color: selectedPlayer.color.opacity(0.38),
                    outlineColor: .white.opacity(0.65)
                )
            }
        }
    }

    @ViewBuilder
    private func ghostBuildings(
        hexSize: CGFloat,
        origin: CGPoint,
        contentRotationDegrees: Double
    ) -> some View {
        ForEach(ghostSteps) { step in
            if case let .vertex(vertex) = step.location {
                BuildingView(
                    building: step.kind == .city ? .city : .settlement,
                    hexSize: hexSize,
                    color: selectedPlayer.color
                )
                .opacity(0.42)
                .rotationEffect(.degrees(contentRotationDegrees))
                .position(BoardGeometry.point(for: vertex, hexSize: hexSize, origin: origin))
            }
        }
    }

    @ViewBuilder
    private func constructionPlacementTargets(hexSize: CGFloat, origin: CGPoint) -> some View {
        if placementMode == .road {
            ForEach(BoardGeometry.standardEdges) { edge in
                let start = BoardGeometry.point(for: edge.start, hexSize: hexSize, origin: origin)
                let end = BoardGeometry.point(for: edge.end, hexSize: hexSize, origin: origin)
                let midpoint = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
                let length = hypot(end.x - start.x, end.y - start.y)
                let angle = atan2(end.y - start.y, end.x - start.x)

                Capsule()
                    .fill(.clear)
                    .contentShape(Capsule())
                    .frame(width: length, height: max(18, hexSize * 0.34))
                    .rotationEffect(.radians(angle))
                    .position(midpoint)
                    .onTapGesture { placeConstruction(on: .edge(edge)) }
                    .accessibilityLabel("Place planned road")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityIdentifier("plannedRoadTarget-\(edge.id)")
            }
        } else if placementMode == .settlement || placementMode == .city {
            ForEach(BoardGeometry.standardVertices) { vertex in
                Circle()
                    .fill(.clear)
                    .contentShape(Circle())
                    .frame(width: max(24, hexSize * 0.5), height: max(24, hexSize * 0.5))
                    .position(BoardGeometry.point(for: vertex, hexSize: hexSize, origin: origin))
                    .onTapGesture { placeConstruction(on: .vertex(vertex)) }
                    .accessibilityLabel("Place planned \(placementMode?.displayName ?? "building")")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityIdentifier("plannedBuildingTarget-\(vertex.id)")
            }
        }
    }

    private func placeConstruction(on location: ConstructionLocation) {
        guard let placementMode else { return }
        let projected = board.projected(adding: ghostSteps, for: selectedPlayer)
        let error: PlacementError?

        switch location {
        case let .edge(edge):
            error = projected.placeRoad(on: edge, for: selectedPlayer)
        case let .vertex(vertex):
            error = projected.placeBuilding(
                placementMode == .city ? .city : .settlement,
                at: vertex,
                for: selectedPlayer
            )
        }

        if let error {
            showPlacementError(error)
        } else {
            onPlaceStep?(PlannedConstructionStep(kind: placementMode, location: location))
        }
    }

    private func showPlacementError(_ error: PlacementError) {
        messageDismissalTask?.cancel()
        placementMessage = error.message
        messageDismissalTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1_500))
            guard !Task.isCancelled else { return }
            placementMessage = nil
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

    private func pickerOptionIndex(
        at location: CGPoint,
        around center: CGPoint,
        hexSize: CGFloat
    ) -> Int? {
        switch editTool {
        case .terrain:
            RadialPickerGeometry.terrainOptionIndex(
                at: location,
                around: center,
                hexSize: hexSize
            )
        case .number:
            RadialPickerGeometry.optionIndex(
                at: location,
                around: center,
                hexSize: hexSize,
                optionCount: optionCount
            )
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
        hexSize: CGFloat,
        contentRotationDegrees: Double
    ) -> some View {
        let standardOuterRadius = hexSize * RadialPickerGeometry.outerRadiusScale
        let outerRadius = hexSize * (editTool == .terrain
            ? RadialPickerGeometry.stackedOuterRadiusScale
            : RadialPickerGeometry.outerRadiusScale)

        ZStack {
            ForEach(0..<optionCount, id: \.self) { index in
                pickerSegment(at: index)
                    .fill(pickerOptionColor(at: index))
                    .overlay {
                        pickerSegment(at: index)
                            .stroke(
                                highlightedPickerIndex == index ? Color.yellow : .white.opacity(0.85),
                                lineWidth: highlightedPickerIndex == index ? 4 : 1.5
                            )
                    }
                    .shadow(
                        color: highlightedPickerIndex == index ? .yellow.opacity(0.45) : .black.opacity(0.2),
                        radius: highlightedPickerIndex == index ? 5 : 2
                    )
                    .accessibilityLabel(pickerOptionAccessibilityLabel(at: index))
                    .accessibilityIdentifier("hexPickerOption-\(index)")

                let angularCount = editTool == .terrain ? 6 : optionCount
                let angularIndex = editTool == .terrain && index == 6 ? 5 : index
                let angle = (-Double.pi / 2) + (2 * Double.pi * Double(angularIndex) / Double(angularCount))
                let iconRadius = editTool == .terrain && index == 6
                    ? (standardOuterRadius + outerRadius) / 2
                    : hexSize * (
                        RadialPickerGeometry.innerRadiusScale + RadialPickerGeometry.outerRadiusScale
                    ) / 2
                pickerOptionSymbol(at: index)
                    .rotationEffect(.degrees(contentRotationDegrees))
                    .position(
                        x: outerRadius + CGFloat(cos(angle)) * iconRadius,
                        y: outerRadius + CGFloat(sin(angle)) * iconRadius
                    )
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }

            if editTool == .number,
               let highlightedPickerIndex,
               case let .token(token) = NumberPickerOption.all[highlightedPickerIndex] {
                NumberTokenView(token: token, size: hexSize * 0.8)
                    .rotationEffect(.degrees(contentRotationDegrees))
                    .position(x: outerRadius, y: outerRadius)
                    .allowsHitTesting(false)
                    .accessibilityIdentifier("numberPickerPreview")
            }
        }
        .frame(width: outerRadius * 2, height: outerRadius * 2)
        .scaleEffect(0.58 + (0.42 * pickerExpansion))
        .opacity(pickerExpansion)
        .position(center)
        .animation(.easeOut(duration: 0.1), value: highlightedPickerIndex)
    }

    private func pickerSegment(at index: Int) -> RingSegment {
        if editTool == .terrain, index == 6 {
            return RingSegment(
                index: 5,
                count: 6,
                innerRadiusScale: RadialPickerGeometry.outerRadiusScale,
                segmentOuterRadiusScale: RadialPickerGeometry.stackedOuterRadiusScale,
                containerOuterRadiusScale: RadialPickerGeometry.stackedOuterRadiusScale
            )
        }
        return RingSegment(
            index: index,
            count: editTool == .terrain ? 6 : optionCount,
            innerRadiusScale: RadialPickerGeometry.innerRadiusScale,
            segmentOuterRadiusScale: RadialPickerGeometry.outerRadiusScale,
            containerOuterRadiusScale: editTool == .terrain
                ? RadialPickerGeometry.stackedOuterRadiusScale
                : RadialPickerGeometry.outerRadiusScale
        )
    }

    @ViewBuilder
    private func pickerOptionSymbol(at index: Int) -> some View {
        switch editTool {
        case .terrain:
            let terrain = Terrain.allCases[index]
            Image(systemName: terrain.systemImage)
                .font(.caption.bold())
                .foregroundStyle(terrain.symbolForegroundColor)
        case .number:
            switch NumberPickerOption.all[index] {
            case let .token(token):
                Text("\(token.rawValue)")
                    .font(.caption.bold())
                    .foregroundStyle(token.isHighProbability ? .red : .black)
            case .remove:
                Image(systemName: "xmark")
                    .font(.caption.bold())
                    .foregroundStyle(.black)
            }
        }
    }

    private func pickerOptionColor(at index: Int) -> Color {
        switch editTool {
        case .terrain: Terrain.allCases[index].color
        case .number: .tokenBackground
        }
    }

    private func pickerOptionAccessibilityLabel(at index: Int) -> String {
        switch editTool {
        case .terrain:
            Terrain.allCases[index].displayName
        case .number:
            switch NumberPickerOption.all[index] {
            case let .token(token): "Number \(token.rawValue)"
            case .remove: "Remove number"
            }
        }
    }
}

private struct RingSegment: Shape {
    let index: Int
    let count: Int
    var innerRadiusScale = RadialPickerGeometry.innerRadiusScale
    var segmentOuterRadiusScale = RadialPickerGeometry.outerRadiusScale
    var containerOuterRadiusScale = RadialPickerGeometry.outerRadiusScale

    func path(in rect: CGRect) -> Path {
        guard count > 0 else { return Path() }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * innerRadiusScale / containerOuterRadiusScale
        let segmentOuterRadius = outerRadius * segmentOuterRadiusScale / containerOuterRadiusScale
        let step = 2 * Double.pi / Double(count)
        let middle = (-Double.pi / 2) + (Double(index) * step)
        let start = Angle(radians: middle - (step / 2))
        let end = Angle(radians: middle + (step / 2))

        var path = Path()
        path.addArc(center: center, radius: segmentOuterRadius, startAngle: start, endAngle: end, clockwise: false)
        path.addArc(center: center, radius: innerRadius, startAngle: end, endAngle: start, clockwise: true)
        path.closeSubpath()
        return path
    }
}

private struct HexTileView: View {
    let tile: HexTile
    let hexSize: CGFloat
    let contentRotationDegrees: Double

    var body: some View {
        ZStack {
            Hexagon()
                .fill(tile.terrain.color)

            if let number = tile.number {
                NumberTokenView(token: number, size: hexSize * 0.8)
                    .rotationEffect(.degrees(contentRotationDegrees))
            }
        }
        .overlay(Hexagon().stroke(.white.opacity(0.85), lineWidth: max(1.5, hexSize * 0.04)))
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
        let symbol = building == .city ? "building.2.fill" : "house.fill"
        let size = building == .city ? hexSize * 0.42 : hexSize * 0.34
        ZStack {
            Image(systemName: symbol)
                .font(.system(size: size, weight: .black))
                .foregroundStyle(.black)
                .scaleEffect(1.16)
            Image(systemName: symbol)
                .font(.system(size: size, weight: .black))
                .foregroundStyle(color)
                .scaleEffect(0.88)
        }
            .padding(4)
            .background(.white, in: RoundedRectangle(cornerRadius: 4))
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(.black, lineWidth: 1)
            }
            .accessibilityHidden(true)
    }
}

private struct BoardWaterBackground: View {
    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(
                Color(red: 0.73, green: 0.90, blue: 0.97)
            ))
            for row in stride(from: CGFloat(24), through: size.height, by: 42) {
                var path = Path()
                path.move(to: CGPoint(x: -24, y: row))
                for x in stride(from: CGFloat(-24), through: size.width + 24, by: 24) {
                    path.addQuadCurve(
                        to: CGPoint(x: x + 24, y: row),
                        control: CGPoint(x: x + 12, y: row - 7)
                    )
                }
                context.stroke(path, with: .color(.white.opacity(0.22)), lineWidth: 1.2)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

private struct VertexValueView: View {
    let value: Int
    let building: Building?
    let ownerColor: Color?
    let hexSize: CGFloat

    var body: some View {
        let diameter = max(18, hexSize * 0.34)

        ZStack {
            if let ownerColor, building == .city {
                Circle()
                    .stroke(ownerColor, lineWidth: max(1, hexSize * 0.025))
                    .frame(width: diameter + 8, height: diameter + 8)
            }

            if let ownerColor {
                Circle()
                    .stroke(ownerColor, lineWidth: max(1, hexSize * 0.025))
                    .frame(width: diameter + 3, height: diameter + 3)
            }

            Circle()
                .fill(.black)
                .frame(width: diameter, height: diameter)

            Text("\(value)")
                .font(.system(size: diameter * 0.55, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        switch building {
        case .settlement: "Vertex value \(value), settlement"
        case .city: "Vertex value \(value), city"
        case nil: "Vertex value \(value)"
        }
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

    var symbolForegroundColor: Color {
        switch self {
        case .brick, .ore, .lumber, .ocean: .white
        case .wheat, .wool, .desert: .black
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
