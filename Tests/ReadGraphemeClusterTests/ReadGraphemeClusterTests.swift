import XCTest
import System
@testable import ReadGraphemeCluster

final class ReadGraphemeClusterTests: XCTestCase {
    func test_readGraphemeCluster() async throws {
//        let url = Bundle.module.url(forResource: "input", withExtension: "txt")!
//        let mockFileHandle = try! FileHandle(forReadingFrom: url)
        let duplicatedStdin = try FileDescriptor.standardInput.duplicate()

        for try await scalar in AsyncCharacterSequence(fileHandle: FileHandle(fileDescriptor: duplicatedStdin.rawValue)) {
            print(scalar)
        }

        try duplicatedStdin.writeAll([

        ])
    }
}
