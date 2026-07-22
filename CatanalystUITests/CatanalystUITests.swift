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
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
