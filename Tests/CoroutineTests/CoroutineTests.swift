import XCTest
@testable import Coroutine

func c(yield: (Int)->()) {
    yield(1)
    yield(2)
    yield(3)
}

class CoroutineTests: XCTestCase {
    func testCoroutine() {
        let cr = Coroutine<Int>(entry:c)
        XCTAssertEqual(cr.next(), 1)
        XCTAssertEqual(cr.next(), 2)
        XCTAssertEqual(cr.next(), 3)
        XCTAssertNil(cr.next())
    }
    
    func testIterator() {
        var n=0;
        let cr = Coroutine(entry:c)
        for i in cr {
            n=n+1
            XCTAssertEqual(n, i)
        }
    }

    static var allTests : [(String, (CoroutineTests) -> () throws -> Void)] {
        return [
            ("testCoroutine", testCoroutine),
            ("testIterator", testIterator),
        ]
    }
}
