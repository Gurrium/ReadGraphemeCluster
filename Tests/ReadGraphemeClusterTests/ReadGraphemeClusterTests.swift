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

    actor Flag {
        var content: Bool

        init(content: Bool) {
            self.content = content
        }

        func set(_ content: Bool) {
            self.content = content
        }
    }

    func test_cancellingTask() async throws {
        let pipe = Pipe()
        let handle = pipe.fileHandleForReading
        let flag = Flag(content: true)

        try pipe.fileHandleForWriting.write(contentsOf: Array("a".utf8))

        let groupResult = try await withThrowingTaskGroup(of: Bool.self) { group in
            group.addTask {
                var it = handle.bytes.unicodeScalars.makeAsyncIterator()
                while let scalar = try await it.next() {
//                for try await scalar in handle.bytes.unicodeScalars {
                    print(scalar)
                    await flag.set(false)
                    try await Task.sleep(nanoseconds: 50_000)
                }

                return true
            }

            group.addTask {
                while await flag.content {
                    try await Task.sleep(nanoseconds: 1_000)
                }

                print("timeout")
                return false
            }

            let ret = try await group.next()!
            group.cancelAll()
            XCTAssertFalse(try XCTUnwrap(ret))

            return ret
        }

        print("groupResult:", groupResult)
    }
}
