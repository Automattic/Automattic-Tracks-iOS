import XCTest

class NSArrayObjectsAfterIndexTests: XCTestCase {

    func testThatObjectsAfterIndexDoesntHaveOffByOneErrors() {
        assert(NSArray.create(withElementCount: 100).objects(afterIndex: 101).count == 0)
        assert(NSArray.create(withElementCount: 100).objects(afterIndex: 100).count == 0)
        assert(NSArray.create(withElementCount: 100).objects(afterIndex: 99).count == 0)
        assert(NSArray.create(withElementCount: 100).objects(afterIndex: 98).count == 1)
    }
}

extension NSArray{
    static func create(withElementCount elementCount: Int) -> NSArray{
        return (0 ..< elementCount).map({ $0 }) as NSArray
    }
}
