import XCTest

import pod_binaryTests

var tests = [XCTestCaseEntry]()
tests += pod_binaryTests.allTests()
XCTMain(tests)
