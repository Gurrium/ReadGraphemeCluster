import Foundation

enum GraphemeClusterBreak: CaseIterable {
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
    case any
    case eBase
    case eModifier
    case glueAfterZWJ
    case eBaseGAZ

    init(scalar: UnicodeScalar) {
        self = GraphemeClusterBreak.allCases.first { $0.match(scalar) }!
    }
}

struct Suteito {
    private var current: GraphemeClusterBreak

    init(current: GraphemeClusterBreak) {
        self.current = current
    }

    var canBreak = false

    /// 状態を変更する。
    /// - Parameters:
    ///   - scalar: 次のUnicodeScalar
    mutating func transitionBy(_ scalar: UnicodeScalar) {
        let next: GraphemeClusterBreak = .allCases.first { $0.match(scalar) }!

        switch (current, next) {
        case (.sot, .any),
            (.any, .eot):
            canBreak = true
        case (.cr, .lf):
            canBreak = false
        case (.control, _),
            (.cr, _),
            (.lf, _),
            (_, .control),
            (_, .cr),
            (_, .lf):
            canBreak = true
        case (.l, let rhs) where [.l, .v, .lv, .lvt].contains(rhs):
            canBreak = false
        case (.lv, let rhs) where [.v, .t].contains(rhs):
            canBreak = false
        case (.v, let rhs) where [.v, .t].contains(rhs):
            canBreak = false
        case (let lhs, .t) where [.lvt, .t].contains(lhs):
            canBreak = false
        case (_, let rhs) where [.extend, .zwj].contains(rhs):
            canBreak = false
        case (_, .spacingMark):
            canBreak = false
        case (.prepend, _):
            canBreak = false
            // TODO: GB11
            // TODO: GB12
            // TODO: GB13
        case (.any, .any):
            canBreak =  true
        default:
            canBreak = true
        }

        current = next
    }
}

public struct ReadGraphemeCluster {}

public struct AsyncCharacterSequence: AsyncSequence {
    public typealias Element = Character

    let fileHandle: FileHandle

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(fileHandle: fileHandle)
    }

    public struct AsyncIterator: AsyncIteratorProtocol {
        private struct TimeoutError: Error {}

        let fileHandle: FileHandle

        public mutating func next() async throws -> Character? {
            var suteito = Suteito(current: .sot)
            var scalars = [UnicodeScalar]()

            for try await scalar in fileHandle.bytes.unicodeScalars {
                // TODO: timeout
                suteito.transitionBy(scalar)

                if suteito.canBreak,
                   !scalars.isEmpty {
                    // FIXME: 一つ以上のExtended Grapheme Clusterを入れると落ちる
                    // preconditionFailureっぽいのでそのままでもいいかも
                    return Character(
                        scalars.reduce("", { partialResult, scalar in
                            partialResult.appending(String(scalar))
                        })
                    )
                } else {
                    scalars.append(scalar)
                }
            }

            // EOF?
            return nil
        }
    }
}
