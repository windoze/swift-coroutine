import XCTest
@testable import Coroutine

class CoroutineTests: XCTestCase {
    func testCoroutineSequence() {
        let cr = CoroutineSequence<Int> {
            (yield) in
            yield(1)
            yield(2)
            yield(3)
        }
        XCTAssertEqual(cr.next(), 1)
        XCTAssertEqual(cr.next(), 2)
        XCTAssertEqual(cr.next(), 3)
        XCTAssertNil(cr.next())
    }

    func testCoroutineIterator() {
        XCTAssert(CoroutineSequence<Int> {
            (yield) in
            yield(1)
            yield(2)
            yield(3)
        }.lazy.elementsEqual(1...3))
    }

    func testCoroutine() {
        let cr = Coroutine<Int, String> {
            (initValue, yield) in
            XCTAssertEqual(initValue, "1")
            XCTAssertEqual(yield(1), "2")
            XCTAssertEqual(yield(2), "3")
            XCTAssertEqual(yield(3), "")
        }
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
