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
    }

    @MainActor
    func testTapOpensAndClosesTerrainPicker() throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["standardBoardButton"].tap()
        app.buttons["editBoardButton"].tap()

        let centerHex = app.descendants(matching: .any)["hex-0,0"]
        XCTAssertTrue(centerHex.waitForExistence(timeout: 3))

        centerHex.tap()
        XCTAssertTrue(app.buttons["Brick"].waitForExistence(timeout: 2))

        centerHex.tap()
        XCTAssertFalse(app.buttons["Brick"].exists)
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
        XCTAssertTrue(app.otherElements["defaultPlanTable"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["defaultPlan-Ore"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["defaultPlan-Development Card"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["planSuperHeader"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["planColumnHeader"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["fixedPlanColumn"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["fixedPlanHeader"].exists)

        let firstPlan = app.descendants(matching: .any)["defaultPlan-Ore"]
        let firstValues = app.descendants(matching: .any)["defaultPlanValues-Ore"]
        XCTAssertTrue(firstValues.exists)
        XCTAssertEqual(firstPlan.frame.midY, firstValues.frame.midY, accuracy: 1.5)

        let table = app.otherElements["planValuesTable"]
        table.swipeLeft()
        XCTAssertTrue(app.descendants(matching: .any)["defaultPlan-Ore"].isHittable)
        table.swipeUp()
        XCTAssertTrue(app.descendants(matching: .any)["planColumnHeader"].isHittable)

        app.buttons["closePlanBrowserButton"].tap()
        XCTAssertFalse(app.otherElements["planBrowser"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
