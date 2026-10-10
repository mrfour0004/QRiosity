//
//  QRiosityUITests.swift
//  QRiosityUITests
//
//  Created by mrfour on 2020/9/2.
//

import XCTest

// MARK: - QRiosityUITests

final class QRiosityUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}

// MARK: - LabelManagementUITests

/// End-to-end checks for label editing through the app's accessibility interface.
@MainActor
final class LabelManagementUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCreateCancelRenameAndDeleteLabel() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let collection = app.tabBars.buttons["Collected"]
        XCTAssertTrue(collection.waitForExistence(timeout: 15), app.debugDescription)
        collection.tap()
        app.buttons["Manage Labels"].tap()
        XCTAssertTrue(app.navigationBars["Manage Labels"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Bookmark"].exists)
        let bookmark = app.cells.containing(.staticText, identifier: "Bookmark").firstMatch
        XCTAssertFalse(bookmark.buttons["Label Options"].exists)

        let title = "UI Check " + UUID().uuidString.prefix(8)
        app.buttons["New Label"].tap()
        XCTAssertTrue(app.textFields["labelTitle"].waitForExistence(timeout: 5))
        let selectedSymbol = app.images["labelSelectedSymbol"]
        XCTAssertTrue(selectedSymbol.exists)
        XCTAssertLessThan(selectedSymbol.frame.maxX, app.textFields["labelTitle"].frame.minX)
        XCTAssertEqual(selectedSymbol.frame.midY, app.textFields["labelTitle"].frame.midY, accuracy: 2)
        XCTAssertFalse(app.buttons["symbol-star.fill"].staticTexts["Star"].exists)
        let editorScreenshot = XCTAttachment(screenshot: app.screenshot())
        editorScreenshot.name = "Label icon picker"
        editorScreenshot.lifetime = .keepAlways
        add(editorScreenshot)
        app.textFields["labelTitle"].tap()
        app.textFields["labelTitle"].typeText(title)
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["Manage Labels"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts[title].exists)

        app.buttons["New Label"].tap()
        XCTAssertTrue(app.textFields["labelTitle"].waitForExistence(timeout: 5))
        app.buttons["symbol-star.fill"].tap()
        app.textFields["labelTitle"].tap()
        app.textFields["labelTitle"].typeText(title)
        app.buttons["saveLabel"].tap()
        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 5), app.debugDescription)
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons[title].waitForExistence(timeout: 5))
        app.buttons[title].tap()
        XCTAssertTrue(app.staticTexts["No Labeled Codes"].exists)

        app.buttons["Manage Labels"].tap()
        app.cells.containing(.staticText, identifier: title).firstMatch.buttons["Label Options"].tap()
        app.buttons["Edit Label"].tap()
        XCTAssertTrue(app.textFields["labelTitle"].waitForExistence(timeout: 5))
        app.textFields["labelTitle"].tap()
        app.textFields["labelTitle"].typeText(" Renamed")
        app.buttons["saveLabel"].tap()
        let renamed = title + " Renamed"
        XCTAssertTrue(app.staticTexts[renamed].waitForExistence(timeout: 5))
        app.cells.containing(.staticText, identifier: renamed).firstMatch.buttons["Label Options"].tap()
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.staticTexts["Your codes will be kept. Codes with no remaining labels will appear in History."].waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.staticTexts[renamed].exists)
        app.cells.containing(.staticText, identifier: renamed).firstMatch.buttons["Label Options"].tap()
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.alerts["Delete Label?"].waitForExistence(timeout: 5))
        app.alerts.buttons["Delete"].tap()
        XCTAssertFalse(app.staticTexts[renamed].waitForExistence(timeout: 2))
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["All"].isSelected)
        let collectionScreenshot = XCTAttachment(screenshot: app.screenshot())
        collectionScreenshot.name = "Collected label filters"
        collectionScreenshot.lifetime = .keepAlways
        add(collectionScreenshot)
    }

    func testIconOnlyLabelInTraditionalChinese() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(zh-Hant)", "-AppleLocale", "zh_TW"]
        app.launch()
        let collection = app.tabBars.buttons["收藏"]
        XCTAssertTrue(collection.waitForExistence(timeout: 15), app.debugDescription)
        collection.tap()
        app.buttons["管理標籤"].tap()
        XCTAssertTrue(app.navigationBars["管理標籤"].waitForExistence(timeout: 5))
        let candidates = [("圖釘", "pin.fill"), ("旗幟", "flag.fill"), ("星號", "star.fill")]
        let candidate = try XCTUnwrap(candidates.first { !app.staticTexts[$0.0].exists })
        app.buttons["新增標籤"].tap()
        XCTAssertTrue(app.textFields["labelTitle"].waitForExistence(timeout: 5))
        app.buttons["symbol-\(candidate.1)"].tap()
        let pickerScreenshot = XCTAttachment(screenshot: app.screenshot())
        pickerScreenshot.name = "Traditional Chinese icon picker"
        pickerScreenshot.lifetime = .keepAlways
        add(pickerScreenshot)
        app.buttons["saveLabel"].tap()
        XCTAssertTrue(app.staticTexts[candidate.0].waitForExistence(timeout: 5))
        app.buttons["完成"].tap()
        XCTAssertTrue(app.buttons[candidate.0].waitForExistence(timeout: 5))
        app.buttons[candidate.0].tap()
        let filterScreenshot = XCTAttachment(screenshot: app.screenshot())
        filterScreenshot.name = "Icon-only label filter"
        filterScreenshot.lifetime = .keepAlways
        add(filterScreenshot)
        app.buttons["管理標籤"].tap()
        app.cells.containing(.staticText, identifier: candidate.0).firstMatch.buttons["標籤選項"].tap()
        app.buttons["刪除"].tap()
        XCTAssertTrue(app.alerts["刪除標籤？"].waitForExistence(timeout: 5))
        app.alerts.buttons["刪除"].tap()
        XCTAssertFalse(app.staticTexts[candidate.0].waitForExistence(timeout: 2))
    }

    func testCollectedNavigationCollapsesWhenScrolled() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let collection = app.tabBars.buttons["Collected"]
        XCTAssertTrue(collection.waitForExistence(timeout: 15))
        collection.tap()
        let title = app.navigationBars["Collected"].staticTexts["Collected"].firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        let navigationBar = app.navigationBars["Collected"]
        let expandedHeight = navigationBar.frame.height
        let scrollView = app.scrollViews["collectedScrollView"]
        XCTAssertTrue(scrollView.exists)
        let initialScreenshot = XCTAttachment(screenshot: app.screenshot())
        initialScreenshot.name = "Collected expanded navigation"
        initialScreenshot.lifetime = .keepAlways
        add(initialScreenshot)
        scrollView.swipeUp()
        let collapsed = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in navigationBar.frame.height < expandedHeight - 1 }, object: nil
        )
        XCTAssertEqual(XCTWaiter.wait(for: [collapsed], timeout: 5), .completed)
        let filterBar = app.scrollViews["labelFilterBar"]
        XCTAssertTrue(filterBar.exists)
        XCTAssertGreaterThanOrEqual(filterBar.buttons["All"].frame.minY, navigationBar.frame.maxY - 1)
        XCTAssertTrue(filterBar.buttons["All"].isHittable)
        let pinnedPosition = filterBar.buttons["All"].frame.minY
        scrollView.swipeUp()
        XCTAssertEqual(filterBar.buttons["All"].frame.minY, pinnedPosition, accuracy: 1)
        XCTAssertTrue(filterBar.buttons["Bookmark"].isHittable)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Collected pinned labels and soft edge"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        scrollView.swipeDown()
        let restoredScreenshot = XCTAttachment(screenshot: app.screenshot())
        restoredScreenshot.name = "Collected restored navigation"
        restoredScreenshot.lifetime = .keepAlways
        add(restoredScreenshot)
        let expanded = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in navigationBar.frame.height >= expandedHeight - 1 }, object: nil
        )
        XCTAssertEqual(XCTWaiter.wait(for: [expanded], timeout: 5), .completed)
    }

}
