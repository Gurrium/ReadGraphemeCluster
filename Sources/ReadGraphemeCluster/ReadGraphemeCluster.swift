import Foundation

enum GraphemeClusterBreak {
    case sot
    case eot
    case cr
    case lf
    case control
    case extend
    case zwj
    case ri
    case prepend
    case spacingMark
    case l
    case v
    case t
    case lv
    case lvt
    case eBase
    case eModifier
    case glueAfterZWJ
    case ebg
    case any
}

public struct ReadGraphemeCluster {}

public struct AsyncCharacterSequence: AsyncSequence {
    public typealias Element = Character

    let fileHandle: FileHandle

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(fileHandle: fileHandle)
    }

    public struct AsyncIterator: AsyncIteratorProtocol {
        let fileHandle: FileHandle

        public mutating func next() async throws -> Character? {
            for try await unicodeScalar in fileHandle.bytes.unicodeScalars {
                // TODO: detect grapheme cluster boundary
                return Character(unicodeScalar)
            }
        }
    }
}

// TODO: 必要なくなったので消す
func read(_ fileHandle: FileHandle) async -> UnicodeScalar {
    await withCheckedContinuation { continuation in
        // TODO: endian
        // TODO: UTF-16, UTF-32

        let replacementCharacter = UnicodeScalar(0xfffd)!
        var scalarValue: UInt32 = replacementCharacter.value
        var container: UInt32 = 0
        read(fileHandle.fileDescriptor, &container, 1)

        func buildScalar(countOfRemainingBytes: Int) {
            for _ in 0..<countOfRemainingBytes {
                container <<= 4

                let timer = Timer(timeInterval: 0 /* 0? */, repeats: false) { _ in
                    continuation.resume(returning: replacementCharacter)
                }

                read(fileHandle.fileDescriptor, &container, 1)
                timer.invalidate()
            }

            scalarValue = container
        }

        // ref: https://www.unicode.org/versions/Unicode15.0.0/ch03.pdf Table 3-6
        if container & 0b1000_0000 >> 7 == 0b0001 { // 00000000 0xxxxxxx
            buildScalar(countOfRemainingBytes: 0)
        } else if container & 0b1110_0000 >> 5 == 0b0110 { // 00000yyy yyxxxxxx
            buildScalar(countOfRemainingBytes: 1)
        } else if container & 0b1111_0000 >> 4 == 0b1110 { // zzzzyyyy yyxxxxxx
            buildScalar(countOfRemainingBytes: 2)
        } else if container & 0b1111_1000 >> 3 == 0b0001_1110 { // 000uuuuu zzzzyyyy yyxxxxxx
            buildScalar(countOfRemainingBytes: 3)
        }

        continuation.resume(returning: UnicodeScalar(scalarValue) ?? replacementCharacter)
    }
}
