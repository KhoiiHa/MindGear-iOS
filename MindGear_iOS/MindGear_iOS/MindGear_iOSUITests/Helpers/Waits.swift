import XCTest

extension XCUIElement {
    func waitForExistence(timeout: TimeInterval = 5, file: StaticString = #file, line: UInt = #line) {
        let predicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        if result != .completed {
            XCTFail("Failed waiting for existence of \(self)", file: file, line: line)
        }
    }

    func waitForHittable(timeout: TimeInterval = 5, file: StaticString = #file, line: UInt = #line) {
        let predicate = NSPredicate(format: "exists == true AND hittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        if result != .completed {
            XCTFail("Failed waiting for hittable \(self)", file: file, line: line)
        }
    }

    func waitToDisappear(timeout: TimeInterval = 5, file: StaticString = #file, line: UInt = #line) {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        if result != .completed {
            XCTFail("Element \(self) did not disappear", file: file, line: line)
        }
    }
}

extension XCUIElementQuery {
    func element(matchingIdentifierPrefix prefix: String) -> XCUIElement {
        return self.matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix)).firstMatch
    }
}
