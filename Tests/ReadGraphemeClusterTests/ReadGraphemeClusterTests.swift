import XCTest
@testable import ReadGraphemeCluster

final class ReadGraphemeClusterTests: XCTestCase {
    func test_readGraphemeCluster() throws {
        let url = Bundle.module.url(forResource: "input", withExtension: "txt")!
        let mockFileHandle = try! FileHandle(forReadingFrom: url)
        let char = readGraphemeCluster(from: mockFileHandle)

        XCTAssertEqual(char, " ")
    }
}
