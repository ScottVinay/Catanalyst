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

        let plansButton = app.buttons["plansButton"]
        XCTAssertTrue(plansButton.waitForExistence(timeout: 3))
        plansButton.tap()

        XCTAssertTrue(app.otherElements["planBrowser"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["planBrowserHelpButton"].exists)
        app.buttons["planGraphsButton"].tap()
        XCTAssertFalse(app.alerts["Plan Browser"].exists)
        app.buttons["planBrowserHelpButton"].tap()
        XCTAssertTrue(app.alerts["Plan Browser"].waitForExistence(timeout: 1))
        app.alerts["Plan Browser"].buttons["OK"].tap()
        XCTAssertTrue(app.otherElements["planBrowser"].exists)
        XCTAssertTrue(app.otherElements["defaultPlanTable"].exists)
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

        app.buttons["closePlanBrowserButton"].tap()
        XCTAssertFalse(app.otherElements["planBrowser"].exists)
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

        app.buttons["plansButton"].tap()
        XCTAssertTrue(app.otherElements["planBrowser"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["selectedPlayerButton"].label.contains("Blue"))
        XCTAssertLessThan(
            app.descendants(matching: .any)["planTabSelector"].frame.maxY,
            app.descendants(matching: .any)["playerSelector"].frame.minY
        )

        let tableFrame = app.otherElements["defaultPlanTable"].frame
        app.buttons["selectPlayer-red"].tap()
        XCTAssertEqual(app.otherElements["defaultPlanTable"].frame, tableFrame)
        XCTAssertTrue(app.buttons["selectedPlayerButton"].label.contains("Red"))
    }

    @MainActor
    func testCreatesAndEditsACustomCardsPlan() throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["standardBoardButton"].tap()
        app.buttons["plansButton"].tap()

        app.buttons["customPlansTab"].tap()
        XCTAssertTrue(app.otherElements["customPlanTable"].waitForExistence(timeout: 2))
        app.buttons["newPlanButton"].tap()
        let chooser = app.descendants(matching: .any)["planTypeChooser"]
        XCTAssertTrue(chooser.waitForExistence(timeout: 2))
        XCTAssertEqual(chooser.frame.midX, app.windows.firstMatch.frame.midX, accuracy: 1)
        XCTAssertEqual(chooser.frame.midY, app.windows.firstMatch.frame.midY, accuracy: 50)
        XCTAssertTrue(app.buttons["planTypeHelpButton"].exists)
        XCTAssertLessThan(app.buttons["Cards"].frame.midY, app.buttons["Constructions"].frame.midY)
        XCTAssertEqual(app.buttons["Cards"].frame.midX, app.buttons["Constructions"].frame.midX, accuracy: 1)
        app.buttons["Cards"].tap()

        XCTAssertEqual(app.textFields["planNameField"].value as? String, "Card plan 1")

        XCTAssertTrue(app.otherElements["planEditor"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["planEditHelpButton"].exists)
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
        XCTAssertLessThan(plan.frame.midY, app.buttons["newPlanButton"].frame.midY)
        let customValues = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'customPlanValues-'")
        ).firstMatch
        XCTAssertTrue(customValues.exists)
        XCTAssertEqual(plan.frame.midY, customValues.frame.midY, accuracy: 1.5)

        app.buttons["selectPlayer-blue"].tap()
        XCTAssertFalse(plan.exists)
        XCTAssertTrue(app.buttons["newPlanButton"].exists)

        app.buttons["selectPlayer-red"].tap()
        XCTAssertTrue(plan.waitForExistence(timeout: 2))
        plan.tap()
        XCTAssertTrue(app.otherElements["planDetail"].waitForExistence(timeout: 2))
        app.buttons["editCustomPlanButton"].tap()
        XCTAssertTrue(app.otherElements["planEditor"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.otherElements["planDetail"].exists)
        app.buttons["cancelPlanButton"].tap()
        XCTAssertTrue(app.otherElements["planBrowser"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.otherElements["planDetail"].exists)
    }

    @MainActor
    func testCreatesAConstructionPlanPlaceholder() throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["standardBoardButton"].tap()
        app.buttons["plansButton"].tap()
        app.buttons["customPlansTab"].tap()
        app.buttons["newPlanButton"].tap()
        app.buttons["Constructions"].tap()

        XCTAssertEqual(app.textFields["planNameField"].value as? String, "Con plan 1")

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
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
