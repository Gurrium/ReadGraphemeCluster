import XCTest
import System
@testable import ReadGraphemeCluster

final class ReadGraphemeClusterTests: XCTestCase {
    func test_readGraphemeCluster() async throws {
        let url = Bundle.module.url(forResource: "input", withExtension: "txt")!
        let fileHandle = try! FileHandle(forUpdating: url)

        let expected = "hoge"
        fileHandle.writeabilityHandler = { fh in
            expected.forEach { char in
                XCTAssertNotNil(try? fh.write(contentsOf: Array(char.utf8)))
            }
        }

        //        Task.detached {
        //            let sheeps: UInt64 = 500_000_000
        //            try await Task.sleep(nanoseconds: sheeps)
        //            await withThrowingTaskGroup(of: Void.self, body: { taskGroup in
        //                expected.forEach { char in
        //                    taskGroup.addTask {
        //                        print("tg:", char)
            //                        XCTAssertNoThrow(try fileHandle.write(contentsOf: Array(char.utf8)))
            //                        try await Task.sleep(nanoseconds: sheeps)
            //                    }
            //                }
            //            })

        //            try expected.forEach { char in
        //                print("ee char:", char)
        //                XCTAssertNoThrow(try fileHandle.write(contentsOf: Array(char.utf8)))
        //            }
        //        }

        let exp = expectation(description: "wait for reading")
        var actual = ""
        for try await character in AsyncCharacterSequence(fileHandle: fileHandle) {
            actual.append(character)
            if actual == expected {
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 1)
    }
}
