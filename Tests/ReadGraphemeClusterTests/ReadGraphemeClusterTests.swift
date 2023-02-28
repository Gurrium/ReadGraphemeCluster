import XCTest
@testable import ReadGraphemeCluster

final class ReadGraphemeClusterTests: XCTestCase {
    func test_readGraphemeCluster() throws {
        let mockFileHandle = FileHandle(forReadingAtPath: "./input.txt")!
        let char = readGraphemeCluster(from: mockFileHandle)
    }
}
