// Copyright © 2026 Mark Zaros. All Rights Reserved. License: GNU Public License 2.0 only.

import XCTest

final class ClipJointUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()
    }
}
