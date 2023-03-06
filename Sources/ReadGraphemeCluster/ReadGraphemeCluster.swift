import Foundation

enum GraphemeClusterBreak {
    case sot
    case eot
    case cr
    case lf
    case control
    case extend
    case zwj
    case regionalIndicator
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
    case eBaseGAZ
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

            // EOF?
            return nil
        }
    }
}
