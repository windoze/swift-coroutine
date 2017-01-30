import XCTest
@testable import Coroutine

func c(yield: (Int) -> ()) {
    yield(1)
    yield(2)
    yield(3)
}

func c1(initValue: String, yield: (Int) -> String) {
    XCTAssertEqual(initValue, "1")
    XCTAssertEqual(yield(1), "2")
    XCTAssertEqual(yield(2), "3")
    XCTAssertEqual(yield(3), "")
}

class CoroutineTests: XCTestCase {
    func testCoroutineSequence() {
        let cr = CoroutineSequence(entry: c)
        XCTAssertEqual(cr.next(), 1)
        XCTAssertEqual(cr.next(), 2)
        XCTAssertEqual(cr.next(), 3)
        XCTAssertNil(cr.next())
    }

    func testCoroutineIterator() {
        var n = 0;
        let cr = CoroutineSequence(entry: c)
        for i in cr {
            n = n + 1
            XCTAssertEqual(n, i)
        }
    }

    func testCoroutine() {
        let cr = Coroutine(entry: c1)
        XCTAssertEqual(cr.next(withValue: "1"), 1)
        XCTAssertEqual(cr.next(withValue: "2"), 2)
        XCTAssertEqual(cr.next(withValue: "3"), 3)
        XCTAssertNil(cr.next(withValue: ""))
    }

    static var allTests: [(String, (CoroutineTests) -> () throws -> Void)] {
        return [
                ("testCoroutineSequence", testCoroutineSequence),
                ("testCoroutineIterator", testCoroutineIterator),
                ("testCoroutine", testCoroutine),
        ]
    }
}
