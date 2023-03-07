import XCTest
import System
@testable import ReadGraphemeCluster

final class ReadGraphemeClusterTests: XCTestCase {
    func test_readGraphemeCluster() async throws {
//        let url = Bundle.module.url(forResource: "input", withExtension: "txt")!
//        let fileHandle = try! FileHandle(forUpdating: url)

        let pipe = Pipe()
        let expected = "hoge"

        Task.detached {
            var continuation: AsyncStream<Character>.Continuation!
            let stream = AsyncStream<Character> { continuation = $0 }

            try await Task.sleep(nanoseconds: 5_000_000)
            expected.forEach {
                continuation.yield($0)
            }

            for await char in stream {
                try await Task.sleep(nanoseconds: 5_000_000)
                try pipe.fileHandleForWriting.write(contentsOf: Array(char.utf8))
            }
        }

        var actual = ""
        for try await character in AsyncCharacterSequence(fileHandle: pipe.fileHandleForReading) {
            actual.append(character)
            if actual == expected {
                break
            }
        }
    }
}
