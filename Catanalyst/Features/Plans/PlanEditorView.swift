import SwiftUI

struct PlanEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedPlayer: PlayerColor
    @State private var draft: CustomPlan
    @State private var isShowingHelp = false
    @State private var isShowingIconPicker = false
    @State private var placementKind: PlannedConstructionKind?
    @State private var isPreviewingConstructionPlan = false
    @State private var generatedDefaultName: String?

    let board: BoardState
    let defaultNameProvider: ((CustomPlanKind, PlayerColor) -> String)?
    let onSave: (CustomPlan) -> Void

    init(
        board: BoardState,
        plan: CustomPlan,
        selectedPlayer: Binding<PlayerColor>,
        generatedDefaultName: String? = nil,
        defaultNameProvider: ((CustomPlanKind, PlayerColor) -> String)? = nil,
        onSave: @escaping (CustomPlan) -> Void
    ) {
        self.board = board
        _draft = State(initialValue: plan)
        _selectedPlayer = selectedPlayer
        _generatedDefaultName = State(initialValue: generatedDefaultName)
        self.defaultNameProvider = defaultNameProvider
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 8) {
                            PlayerSelector(selection: $selectedPlayer)
                            if draft.kind == .constructions {
                                Button {
                                    isPreviewingConstructionPlan = true
                                } label: {
                                    Image(systemName: "circle.hexagongrid.fill")
                                        .frame(width: 30, height: 30)
                                }
                                .buttonStyle(.bordered)
                                .accessibilityLabel("Preview construction plan")
                                .accessibilityIdentifier("previewConstructionPlanButton")
                            }
                        }

                        HStack(spacing: 10) {
                            TextField("Plan name", text: $draft.name)
                                .textFieldStyle(.roundedBorder)
                                .accessibilityIdentifier("planNameField")

                            Button {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    isShowingIconPicker.toggle()
                                }
                            } label: {
                                ZStack(alignment: .bottomTrailing) {
                                    Image(systemName: draft.systemImage)
                                        .font(.title3)
                                        .frame(width: 42, height: 36)
                                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.caption)
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, Color.accentColor)
                                        .offset(x: 4, y: 4)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Change item icon")
                            .accessibilityIdentifier("analysisIconButton")
                        }

                        if isShowingIconPicker {
                            iconPicker
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        Text(helperText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if draft.kind == .cards {
                            selectedCards
                            cardPicker
                        } else {
                            constructionSteps
                        }

                        Color.clear
                            .frame(height: 1)
                            .id("planEditorBottom")
                    }
                    .padding()
                    .padding(.bottom, 12)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: draft.constructionSteps.count) { oldCount, newCount in
                    guard draft.kind == .constructions, newCount > oldCount else { return }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo("planEditorBottom", anchor: .bottom)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    Button("Clear") { draft.clearContents() }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                        .disabled(draft.cardCounts.isEmpty && draft.constructionSteps.isEmpty)
                        .accessibilityIdentifier(
                            draft.kind == .cards
                                ? "clearCardPlanButton"
                                : "clearConstructionPlanButton"
                        )

                    Button("Cancel") { dismiss() }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier("cancelPlanButton")

                    Button("Save") {
                        draft.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        draft.player = selectedPlayer
                        onSave(draft)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .disabled(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("savePlanButton")
                }
                .padding()
                .background(.bar)
            }
            .navigationTitle(editorTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingHelp = true
                    } label: {
                        Image(systemName: "questionmark.circle.fill")
                    }
                    .accessibilityLabel("Plan editing help")
                    .accessibilityIdentifier("planEditHelpButton")
                }
            }
            .alert("Editing a plan", isPresented: $isShowingHelp) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(helperText)
            }
            .fullScreenCover(item: $placementKind) { kind in
                ConstructionPlacementView(
                    board: board,
                    player: selectedPlayer,
                    kind: kind,
                    priorSteps: draft.constructionSteps
                ) { step in
                    draft.constructionSteps.append(step)
                }
            }
            .fullScreenCover(isPresented: $isPreviewingConstructionPlan) {
                ConstructionPlanPreviewView(
                    board: board,
                    player: selectedPlayer,
                    steps: draft.constructionSteps
                )
            }
            .onChange(of: selectedPlayer) { _, player in
                guard let generatedDefaultName,
                      draft.name == generatedDefaultName,
                      let defaultNameProvider else { return }
                let replacement = defaultNameProvider(draft.kind, player)
                draft.name = replacement
                self.generatedDefaultName = replacement
            }
        }
        .accessibilityIdentifier("planEditor")
    }

    private var helperText: String {
        switch draft.kind {
        case .cards:
            "Production check is complete when the player's hand contains at least the cards selected."
        case .constructions:
            "Plan shall be considered complete when the following have been built in order, starting from the state of the board at the point where the plan is made."
        }
    }

    private var editorTitle: String {
        draft.kind == .cards ? "Edit Production Check" : "Edit Plan"
    }

    private var iconPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Icon").font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(AnalysisItemIcon.choices, id: \.self) { systemImage in
                    Button {
                        draft.systemImage = systemImage
                        withAnimation(.easeInOut(duration: 0.18)) {
                            isShowingIconPicker = false
                        }
                    } label: {
                        Image(systemName: systemImage)
                            .font(.title3)
                            .frame(maxWidth: .infinity, minHeight: 38)
                            .background(
                                draft.systemImage == systemImage
                                    ? Color.accentColor.opacity(0.2)
                                    : Color.secondary.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        draft.systemImage == systemImage ? Color.accentColor : .clear,
                                        lineWidth: 2
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Use \(systemImage) icon")
                    .accessibilityValue(draft.systemImage == systemImage ? "Selected" : "")
                    .accessibilityAddTraits(draft.systemImage == systemImage ? .isSelected : [])
                    .accessibilityIdentifier("analysisIcon-\(systemImage)")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("analysisIconPicker")
    }

    private var selectedCards: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Selected cards").font(.headline)

            if draft.cardCounts.isEmpty {
                Text("No cards selected")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .accessibilityIdentifier("emptySelectedCards")
            } else {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(ResourceCard.allCases.filter { draft.cardCounts[$0, default: 0] > 0 }) { resource in
                        Button {
                            draft.removeCard(resource)
                        } label: {
                            ResourceCardStackView(
                                resource: resource,
                                count: draft.cardCounts[resource, default: 0],
                                accessibilityIdentifier: "selectedCard-\(resource.rawValue)"
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Removes one card")
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            }
        }
        .accessibilityIdentifier("selectedCards")
    }

    private var cardPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Add cards").font(.headline)
            HStack(spacing: 10) {
                ForEach(ResourceCard.allCases) { resource in
                    Button {
                        draft.addCard(resource)
                    } label: {
                        ResourceCardView(resource: resource, showsAddBadge: true)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Add \(resource.displayName) card")
                    .accessibilityIdentifier("addCard-\(resource.rawValue)")
                }
            }
        }
    }

    private var constructionSteps: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Construction steps").font(.headline)

            ForEach(Array(draft.constructionSteps.enumerated()), id: \.element.id) { index, step in
                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .frame(width: 24, height: 24)
                        .background(.quaternary, in: Circle())
                    Label(step.kind.displayName, systemImage: step.kind.systemImage)
                    Spacer()
                    if index == draft.constructionSteps.count - 1 {
                        Button {
                            draft.removeLastConstructionStep()
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove final construction step")
                        .accessibilityIdentifier("removeLastConstructionStepButton")
                    }
                }
                .padding(.vertical, 6)
                .accessibilityIdentifier("constructionStep-\(index)")
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("New step").font(.subheadline.weight(.semibold))
                HStack(spacing: 10) {
                    ForEach(PlannedConstructionKind.allCases) { kind in
                        Button {
                            placementKind = kind
                        } label: {
                            Label(kind.displayName, systemImage: kind.systemImage)
                                .labelStyle(.iconOnly)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Add \(kind.displayName) step")
                        .accessibilityIdentifier("addConstruction-\(kind.rawValue)")
                    }
                }
            }
            .padding()
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
            .accessibilityIdentifier("newConstructionStep")
        }
    }
}
