//
//  CatanalystUITests.swift
//  CatanalystUITests
//
//  Created by Scott Vinay on 20/07/2026.
//

import XCTest

final class CatanalystUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testCreatesAStandardBoardAndEntersEditMode() throws {
        let app = XCUIApplication()
        app.launch()

        let standardBoard = app.buttons["standardBoardButton"]
        XCTAssertTrue(standardBoard.waitForExistence(timeout: 3))
        standardBoard.tap()

        XCTAssertLessThan(app.buttons["editBoardButton"].frame.midX, app.buttons["handButton"].frame.midX)
        XCTAssertLessThan(app.buttons["handButton"].frame.midX, app.buttons["analysisButton"].frame.midX)
        app.buttons["handButton"].tap()
        XCTAssertTrue(app.otherElements["handSheet"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.navigationBars["Cards in hand"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["emptyHandCards"].exists)
        app.buttons["handAddCard-brick"].tap()
        app.buttons["handAddCard-brick"].tap()
        let redBrickStack = app.descendants(matching: .any)["handSelectedCard-brick"]
        XCTAssertEqual(redBrickStack.label, "2 Brick cards")
        redBrickStack.tap()
        XCTAssertEqual(redBrickStack.label, "1 Brick cards")

        app.buttons["selectPlayer-blue"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["emptyHandCards"].exists)
        app.buttons["handAddCard-ore"].tap()
        XCTAssertEqual(
            app.descendants(matching: .any)["handSelectedCard-ore"].label,
            "1 Ore cards"
        )
        app.buttons["selectPlayer-red"].tap()
        XCTAssertEqual(redBrickStack.label, "1 Brick cards")
        app.buttons["closeHandButton"].tap()
        XCTAssertFalse(app.otherElements["handSheet"].exists)

        app.buttons["handButton"].tap()
        XCTAssertEqual(
            app.descendants(matching: .any)["handSelectedCard-brick"].label,
            "1 Brick cards"
        )
        app.buttons["clearHandButton"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["emptyHandCards"].exists)
        app.buttons["closeHandButton"].tap()

        let editButton = app.buttons["editBoardButton"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3))
        editButton.tap()

        XCTAssertTrue(app.buttons["doneEditingButton"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.segmentedControls["hexEditModePicker"].exists)
        XCTAssertEqual(
            app.segmentedControls["hexEditModePicker"].frame.midX,
            app.windows.firstMatch.frame.midX,
            accuracy: 1
        )
        XCTAssertTrue(app.buttons["boardEditHelpButton"].exists)
    }

    @MainActor
    func testLongPressDragEditsTerrainAndCentreReleaseCancels() throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["standardBoardButton"].tap()
        app.buttons["editBoardButton"].tap()

        let centerHex = app.descendants(matching: .any)["hex-0,0"]
        XCTAssertTrue(centerHex.waitForExistence(timeout: 3))

        let initialTerrain = centerHex.value as? String
        let centre = centerHex.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))

        centerHex.tap()
        centerHex.tap()
        XCTAssertEqual(centerHex.value as? String, initialTerrain)
        XCTAssertFalse(app.descendants(matching: .any)["hexPickerOption-0"].exists)

        centre.press(forDuration: 0.6)
        XCTAssertEqual(centerHex.value as? String, initialTerrain)
        XCTAssertFalse(app.descendants(matching: .any)["hexPickerOption-0"].exists)

        let brickOption = centre.withOffset(CGVector(dx: 0, dy: -centerHex.frame.width * 0.9))
        centre.press(forDuration: 0.6, thenDragTo: brickOption)
        XCTAssertEqual(centerHex.value as? String, "Brick")
    }

    @MainActor
    func testOpensDefaultPlanBrowser() throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["standardBoardButton"].tap()

        let analysisButton = app.buttons["analysisButton"]
        XCTAssertTrue(analysisButton.waitForExistence(timeout: 3))
        analysisButton.tap()

        XCTAssertTrue(app.otherElements["analysisBrowser"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["analysisHelpButton"].exists)
        let graphButton = app.buttons["planGraphsButton"]
        let helpButton = app.buttons["analysisHelpButton"]
        XCTAssertFalse(graphButton.frame.intersects(helpButton.frame))
        graphButton.tap()
        XCTAssertFalse(app.alerts["Analysis"].exists)
        helpButton.tap()
        XCTAssertTrue(app.alerts["Analysis"].waitForExistence(timeout: 1))
        app.alerts["Analysis"].buttons["OK"].tap()
        graphButton.tap()
        XCTAssertFalse(app.alerts["Analysis"].exists)
        XCTAssertTrue(app.otherElements["analysisBrowser"].exists)
        XCTAssertTrue(app.otherElements["productionTable"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["defaultPlan-Ore"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["defaultPlan-Dev Card"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["planSuperHeader"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["planColumnHeader"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["fixedPlanColumn"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["fixedPlanHeader"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["summaryPlanHeader"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["probabilityPlanHeader"].exists)

        let firstPlan = app.descendants(matching: .any)["defaultPlan-Ore"]
        let firstValues = app.descendants(matching: .any)["defaultPlanValues-Ore"]
        XCTAssertTrue(firstValues.exists)
        XCTAssertEqual(firstPlan.frame.midY, firstValues.frame.midY, accuracy: 1.5)

        let table = app.otherElements["planValuesTable"]
        let metaHeader = app.descendants(matching: .any)["planMetaHeader"]
        let sectionArrow = app.buttons["planSectionArrow"]
        XCTAssertTrue(metaHeader.exists)
        XCTAssertTrue(metaHeader.frame.contains(
            CGPoint(x: sectionArrow.frame.midX, y: sectionArrow.frame.midY)
        ))

        table.swipeDown()
        XCTAssertEqual(firstPlan.frame.midY, firstValues.frame.midY, accuracy: 1.5)

        table.swipeLeft()
        XCTAssertTrue(
            app.descendants(matching: .any)["probabilityPlanHeader"]
                .waitForExistence(timeout: 2)
        )
        XCTAssertFalse(app.descendants(matching: .any)["summaryPlanHeader"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["defaultPlan-Ore"].isHittable)
        let fixedMetaHeaderFrame = metaHeader.frame
        table.swipeLeft()
        XCTAssertTrue(app.descendants(matching: .any)["probabilityPlanValues"].exists)
        XCTAssertEqual(metaHeader.frame.minX, fixedMetaHeaderFrame.minX, accuracy: 1)
        XCTAssertEqual(metaHeader.frame.maxX, fixedMetaHeaderFrame.maxX, accuracy: 1)

        sectionArrow.tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["summaryPlanHeader"]
                .waitForExistence(timeout: 2)
        )
        table.swipeUp()
        XCTAssertTrue(app.descendants(matching: .any)["planColumnHeader"].isHittable)

        app.buttons["closeAnalysisButton"].tap()
        XCTAssertFalse(app.otherElements["analysisBrowser"].exists)
    }

    @MainActor
    func testPlayerSelectionIsSharedWithPlans() throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["standardBoardButton"].tap()

        XCTAssertFalse(app.buttons["selectedPlayerButton"].exists)
        let viewingBoardFrame = app.otherElements["boardEditor"].frame
        app.buttons["editBoardButton"].tap()

        let boardFrame = app.otherElements["boardEditor"].frame
        let pickerFrame = app.segmentedControls["hexEditModePicker"].frame
        XCTAssertEqual(boardFrame, viewingBoardFrame)
        XCTAssertLessThan(
            pickerFrame.maxY,
            app.descendants(matching: .any)["playerSelector"].frame.minY
        )
        let selectedFrame = app.buttons["selectedPlayerButton"].frame
        let blueFrame = app.buttons["selectPlayer-blue"].frame
        XCTAssertGreaterThan(blueFrame.minX, selectedFrame.maxX)
        XCTAssertEqual(blueFrame.midY, selectedFrame.midY, accuracy: 1)

        app.buttons["selectPlayer-blue"].tap()
        XCTAssertEqual(app.buttons["selectedPlayerButton"].value as? String, "Selected")
        XCTAssertEqual(app.otherElements["boardEditor"].frame, boardFrame)
        XCTAssertEqual(app.segmentedControls["hexEditModePicker"].frame, pickerFrame)
        app.buttons["doneEditingButton"].tap()
        XCTAssertFalse(app.buttons["selectedPlayerButton"].exists)

        app.buttons["analysisButton"].tap()
        XCTAssertTrue(app.otherElements["analysisBrowser"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["selectedPlayerButton"].label.contains("Blue"))
        XCTAssertLessThan(
            app.descendants(matching: .any)["planTabSelector"].frame.maxY,
            app.descendants(matching: .any)["playerSelector"].frame.minY
        )

        let tableFrame = app.otherElements["productionTable"].frame
        app.buttons["selectPlayer-red"].tap()
        XCTAssertEqual(app.otherElements["productionTable"].frame, tableFrame)
        XCTAssertTrue(app.buttons["selectedPlayerButton"].label.contains("Red"))
    }

    @MainActor
    func testCreatesAndEditsACustomCardsPlan() throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["standardBoardButton"].tap()
        app.buttons["analysisButton"].tap()

        XCTAssertTrue(app.otherElements["productionTable"].waitForExistence(timeout: 2))
        app.buttons["newProductionCheckButton"].tap()
        XCTAssertEqual(app.textFields["planNameField"].value as? String, "Prod 1")

        XCTAssertTrue(app.otherElements["planEditor"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["planEditHelpButton"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["analysisIconPicker"].exists)
        app.buttons["analysisIcon-flag.fill"].tap()
        app.buttons["addCard-brick"].tap()
        app.buttons["addCard-brick"].tap()
        app.buttons["addCard-ore"].tap()
        XCTAssertEqual(app.descendants(matching: .any)["selectedCard-brick"].label, "2 Brick cards")
        XCTAssertEqual(
            app.descendants(matching: .any)["selectedCard-brick"].value as? String,
            "White outlined stack"
        )
        app.buttons["clearCardPlanButton"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["emptySelectedCards"].exists)
        app.buttons["addCard-brick"].tap()

        let name = app.textFields["planNameField"]
        name.tap()
        name.press(forDuration: 1)
        app.menuItems["Select All"].tap()
        name.typeText("City Hand")
        app.buttons["savePlanButton"].tap()

        let plan = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'customPlan-'")
        ).firstMatch
        XCTAssertTrue(plan.waitForExistence(timeout: 2))
        XCTAssertTrue(plan.label.contains("City Hand"))
        XCTAssertTrue(app.descendants(matching: .any)["summaryPlanHeader"].exists)
        XCTAssertLessThan(plan.frame.midY, app.buttons["newProductionCheckButton"].frame.midY)
        let customValues = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'customPlanValues-'")
        ).firstMatch
        XCTAssertTrue(customValues.exists)
        XCTAssertEqual(plan.frame.midY, customValues.frame.midY, accuracy: 1.5)

        plan.tap()
        let cardRows = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'customPlanCard-' AND NOT identifier CONTAINS 'Values' AND NOT identifier CONTAINS 'Probabilities'")
        )
        XCTAssertTrue(app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'customPlanCardStats-'")
        ).firstMatch.waitForExistence(timeout: 2))
        XCTAssertEqual(cardRows.count, 5)
        let firstCard = cardRows.element(boundBy: 0)
        let firstCardValues = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'customPlanCard-' AND identifier ENDSWITH 'Values'")
        ).firstMatch
        XCTAssertEqual(firstCard.frame.midY, firstCardValues.frame.midY, accuracy: 1.5)
        plan.tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'customPlanCardStats-'")
        ).firstMatch.waitForNonExistence(timeout: 2))

        app.buttons["selectPlayer-blue"].tap()
        XCTAssertFalse(plan.exists)
        XCTAssertTrue(app.buttons["newProductionCheckButton"].exists)

        app.buttons["selectAllPlayers"].tap()
        XCTAssertTrue(plan.waitForExistence(timeout: 2))
        XCTAssertTrue(app.descendants(matching: .any)["planOwner-red"].exists)
        app.buttons["newProductionCheckButton"].tap()
        XCTAssertTrue(app.buttons["selectedPlayerButton"].label.contains("Red"))
        XCTAssertEqual(app.textFields["planNameField"].value as? String, "Prod 1")
        app.buttons["selectPlayer-blue"].tap()
        XCTAssertEqual(app.textFields["planNameField"].value as? String, "Prod 1")
        app.buttons["cancelPlanButton"].tap()

        app.buttons["selectPlayer-red"].tap()
        XCTAssertTrue(plan.waitForExistence(timeout: 2))
        plan.press(forDuration: 0.7)
        XCTAssertTrue(app.otherElements["planEditor"].waitForExistence(timeout: 2))
        let savedBrickStack = app.descendants(matching: .any)["selectedCard-brick"]
        XCTAssertEqual(savedBrickStack.label, "1 Brick cards")
        savedBrickStack.tap()
        XCTAssertTrue(app.descendants(matching: .any)["emptySelectedCards"].exists)
        app.buttons["cancelPlanButton"].tap()
        XCTAssertTrue(app.otherElements["analysisBrowser"].waitForExistence(timeout: 2))

        plan.press(forDuration: 0.7)
        XCTAssertEqual(
            app.descendants(matching: .any)["selectedCard-brick"].label,
            "1 Brick cards"
        )
        app.buttons["cancelPlanButton"].tap()

        app.buttons["newProductionCheckButton"].tap()
        XCTAssertEqual(app.textFields["planNameField"].value as? String, "Prod 1")
        app.buttons["cancelPlanButton"].tap()

        app.buttons["selectPlayer-blue"].tap()
        app.buttons["newProductionCheckButton"].tap()
        XCTAssertEqual(app.textFields["planNameField"].value as? String, "Prod 1")
        app.buttons["cancelPlanButton"].tap()

        app.buttons["plansAnalysisTab"].tap()
        XCTAssertTrue(app.otherElements["plansTable"].waitForExistence(timeout: 2))
        app.buttons["newPlanButton"].tap()
        XCTAssertEqual(app.textFields["planNameField"].value as? String, "Plan 1")
        app.buttons["cancelPlanButton"].tap()
    }

    @MainActor
    func testCreatesAConstructionPlanPlaceholder() throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["standardBoardButton"].tap()
        app.buttons["analysisButton"].tap()
        app.buttons["plansAnalysisTab"].tap()
        app.buttons["newPlanButton"].tap()

        XCTAssertEqual(app.textFields["planNameField"].value as? String, "Plan 1")

        XCTAssertTrue(app.otherElements["newConstructionStep"].waitForExistence(timeout: 2))
        XCTAssertGreaterThan(
            app.buttons["previewConstructionPlanButton"].frame.minX,
            app.otherElements["playerSelector"].frame.maxX
        )
        app.buttons["addConstruction-settlement"].tap()
        XCTAssertTrue(app.otherElements["constructionPlacement"].waitForExistence(timeout: 2))
        app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'plannedBuildingTarget-'")
        ).firstMatch.tap()
        XCTAssertTrue(app.otherElements["plannedPlacementConfirmation"].waitForExistence(timeout: 0.5))
        XCTAssertTrue(app.otherElements["constructionPlacement"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["constructionStep-0"].waitForExistence(timeout: 2))
        app.buttons["previewConstructionPlanButton"].tap()
        XCTAssertTrue(app.otherElements["constructionPlanPreview"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'plannedBuildingTarget-'")
        ).firstMatch.exists)
        app.buttons["closeConstructionPreviewButton"].tap()
        XCTAssertTrue(app.otherElements["planEditor"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.descendants(matching: .any)["constructionStep-0"].exists)
        XCTAssertTrue(app.buttons["removeLastConstructionStepButton"].exists)
        app.buttons["removeLastConstructionStepButton"].tap()
        XCTAssertFalse(app.descendants(matching: .any)["constructionStep-0"].exists)
        XCTAssertFalse(app.buttons["clearConstructionPlanButton"].isEnabled)
        XCTAssertTrue(app.buttons["savePlanButton"].isEnabled)
    }

    @MainActor
    func testInvalidPlacementFeedbackAppearsLowAndDismisses() throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["standardBoardButton"].tap()
        app.buttons["analysisButton"].tap()
        app.buttons["plansAnalysisTab"].tap()
        app.buttons["newPlanButton"].tap()
        app.buttons["addConstruction-road"].tap()

        let board = app.otherElements["boardEditor"]
        XCTAssertTrue(board.waitForExistence(timeout: 2))
        app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'plannedRoadTarget-'")
        ).firstMatch.tap()

        let message = app.staticTexts["placementErrorMessage"]
        XCTAssertTrue(message.waitForExistence(timeout: 1))
        XCTAssertGreaterThan(message.frame.midY, board.frame.midY)
        XCTAssertTrue(message.waitForNonExistence(timeout: 2))
        XCTAssertTrue(app.otherElements["constructionPlacement"].exists)

        app.buttons["cancelConstructionPlacementButton"].tap()
        app.buttons["addConstruction-city"].tap()
        app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'plannedBuildingTarget-'")
        ).firstMatch.tap()
        XCTAssertTrue(message.waitForExistence(timeout: 1))
        XCTAssertEqual(message.label, "City must upgrade a settlement of the same colour.")
        XCTAssertFalse(app.descendants(matching: .any)["constructionStep-0"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
