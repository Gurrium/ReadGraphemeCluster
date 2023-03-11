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

            expected.forEach {
                continuation.yield($0)
            }

            for await char in stream {
                print("input \"\(char)\"")
                try pipe.fileHandleForWriting.write(contentsOf: Array(char.utf8))
                try await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }

//        let testTask = Task {
            var actual = ""
            for try await character in AsyncCharacterSequence(fileHandle: pipe.fileHandleForReading) {
                actual.append(character)
                print("read:", character)
                if actual == expected {
                    break
                }
            }
//        }

//        let timeoutTask = Task {
//            try await Task.sleep(nanoseconds: 1_000_000)
//            XCTFail("timeout")
//            testTask.cancel()
//        }
//
//        do {
//            _ = try await testTask.value
//            timeoutTask.cancel()
//        }
    }

//    func testHoge() async throws {
//        let task = Task {
//            defer {
//                print("returned")
//            }
//            return "hoge"
//        }
//
//        try await Task.sleep(nanoseconds: 1_000_000)
//
//        print(try await task.value)
//    }

    func test_cancellingTask() async throws {
        _ = try await withThrowingTaskGroup(of: Bool.self) { group in
            group.addTask {
                var continuation: AsyncStream<Void>.Continuation!
                let stream = AsyncStream<Void> { continuation = $0 }

                continuation.yield(())

                for try await _ in stream {
                    print("hoge")
                }

                if Task.isCancelled {
                    print("cancelled")
                    return false
                }

                return false
            }

            group.addTask {
                true
            }

            let ret = try? await group.next()
            group.cancelAll()
            XCTAssertTrue(try XCTUnwrap(ret))
        }

        print("end")
    }
}
