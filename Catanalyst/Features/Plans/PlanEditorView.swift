import SwiftUI

struct PlanEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedPlayer: PlayerColor
    @State private var draft: CustomPlan
    @State private var isShowingHelp = false
    @State private var placementKind: PlannedConstructionKind?
    @State private var isPreviewingConstructionPlan = false

    let board: BoardState
    let onSave: (CustomPlan) -> Void

    init(
        board: BoardState,
        plan: CustomPlan,
        selectedPlayer: Binding<PlayerColor>,
        onSave: @escaping (CustomPlan) -> Void
    ) {
        self.board = board
        _draft = State(initialValue: plan)
        _selectedPlayer = selectedPlayer
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Color.clear.frame(height: 42)

                    TextField("Plan name", text: $draft.name)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("planNameField")

                    Text(helperText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if draft.kind == .cards {
                        selectedCards
                        cardPicker
                    } else {
                        constructionSteps
                    }
                }
                .padding()
            }
            .overlay(alignment: .topLeading) {
                PlayerSelector(selection: $selectedPlayer)
                    .padding(.leading, 16)
                    .padding(.top, 16)
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
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
        }
        .accessibilityIdentifier("planEditor")
    }

    private var helperText: String {
        switch draft.kind {
        case .cards:
            "Plan shall be considered complete when the player's hand contains at least the cards selected."
        case .constructions:
            "Plan shall be considered complete when the following have been built in order, starting from the state of the board at the point where the plan is made."
        }
    }

    private var editorTitle: String {
        draft.kind == .cards ? "Edit Cards Plan" : "Edit Construction Plan"
    }

    private var selectedCards: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Selected cards").font(.headline)
                Spacer()
                Button("Clear") { draft.clearContents() }
                    .disabled(draft.cardCounts.isEmpty)
                    .accessibilityIdentifier("clearCardPlanButton")
            }

            if draft.cardCounts.isEmpty {
                Text("No cards selected")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .accessibilityIdentifier("emptySelectedCards")
            } else {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(ResourceCard.allCases.filter { draft.cardCounts[$0, default: 0] > 0 }) { resource in
                        cardStack(resource, count: draft.cardCounts[resource, default: 0])
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            }
        }
        .accessibilityIdentifier("selectedCards")
    }

    private func cardStack(_ resource: ResourceCard, count: Int) -> some View {
        ZStack(alignment: .leading) {
            ForEach(0..<count, id: \.self) { index in
                ResourceCardView(resource: resource, showsWhiteOutline: true)
                    .frame(width: 52)
                    .offset(x: CGFloat(index) * 8)
            }
        }
        .frame(width: 52 + CGFloat(max(0, count - 1)) * 8, height: 76, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(count) \(resource.displayName) cards")
        .accessibilityValue("White outlined stack")
        .accessibilityIdentifier("selectedCard-\(resource.rawValue)")
    }

    private var cardPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Add cards").font(.headline)
            HStack(spacing: 10) {
                ForEach(ResourceCard.allCases) { resource in
                    Button {
                        draft.cardCounts[resource, default: 0] += 1
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
            HStack {
                Text("Construction steps").font(.headline)
                Spacer()
                Button {
                    isPreviewingConstructionPlan = true
                } label: {
                    Image(systemName: "circle.hexagongrid.fill")
                }
                .accessibilityLabel("Preview construction plan")
                .accessibilityIdentifier("previewConstructionPlanButton")
                Button("Clear") { draft.clearContents() }
                    .disabled(draft.constructionSteps.isEmpty)
                    .accessibilityIdentifier("clearConstructionPlanButton")
            }

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
