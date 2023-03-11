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

actor GraphemeCluster {
    var character: Character {
        var scalars = scalars

        if canBreak {
            scalars.removeLast()
        }

        // FIXME: 一つ以上のExtended Grapheme Clusterを入れると落ちる
        // preconditionFailureっぽいのでそのままでもいいかも
        return Character(
            scalars.reduce("", { partialResult, scalar in
                partialResult.appending(String(scalar))
            })
        )
    }

    var lastScalar: UnicodeScalar? {
        scalars.last
    }

    private(set) var canBreak = false

    private var current: GraphemeClusterBreak
    private var scalars = [UnicodeScalar]()

    init(scalar: UnicodeScalar? = nil) {
        if let scalar {
            self.current = GraphemeClusterBreak(scalar: scalar)
            self.scalars = [scalar]
        } else {
            self.current = .sot
        }
    }

    /// 状態を変更する。
    /// - Parameters:
    ///   - scalar: 次のUnicodeScalar
    func transitionBy(_ scalar: UnicodeScalar) {
        let next = GraphemeClusterBreak(scalar: scalar)

        switch (current, next) {
        case  (.sot, .any):
            canBreak = false
        case (.any, .eot):
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
        scalars.append(scalar)
    }
}

public struct ReadGraphemeCluster {}

actor Flag {
    var content = true

    func setContent(_ flag: Bool) {
        content = flag
    }
}

public struct AsyncCharacterSequence: AsyncSequence {
    public typealias Element = Character

    let fileHandle: FileHandle

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(fileHandle: fileHandle)
    }

    public class AsyncIterator: AsyncIteratorProtocol {
        private struct TimeoutError: Error {}

        let fileHandle: FileHandle

        private var previousScalar: UnicodeScalar?

        init(fileHandle: FileHandle) {
            self.fileHandle = fileHandle
        }

        public func next() async throws -> Character? {
            print("next previousScalar:", previousScalar)
            let graphemeCluster = GraphemeCluster(scalar: previousScalar)
            let flag = Flag()

            let taskGroupResult = await withThrowingTaskGroup(of: (Character, UnicodeScalar)?.self) { taskGroup in
                taskGroup.addTask { [weak fileHandle] in
                    guard let fileHandle else { return nil }

                    for try await scalar in fileHandle.bytes.unicodeScalars {
                        if Task.isCancelled {
                            return nil
                        }

                        print("scalar:", scalar)
                        await graphemeCluster.transitionBy(scalar)

                        if await graphemeCluster.canBreak {
                            print("A")
                            return await (graphemeCluster.character, graphemeCluster.lastScalar!)
                        }

                        await flag.setContent(false)
                    }

                    if let lastScalar = await graphemeCluster.lastScalar {
                        print("B")
                        return (await graphemeCluster.character, lastScalar)
                    } else {
                        print("C")
                        return nil
                    }
                }

                taskGroup.addTask {
                    while await flag.content {
                        try await Task.sleep(nanoseconds: 1_000)
                    }

                    guard !Task.isCancelled else { return nil }

                    if let lastScalar = await graphemeCluster.lastScalar {
                        print("D")
                        return (await graphemeCluster.character, lastScalar)
                    } else {
                        print("E")
                        return nil
                    }
                }

                let ret = try? await taskGroup.next()!
                    taskGroup.cancelAll()

                print("ret:", ret)
                defer {
                    print("defer ")
                }
                return ret
            }

            if let result = taskGroupResult {
                previousScalar = result.1
                print("set previousScalar:", previousScalar)
                return result.0
            } else {
                return nil
            }
        }
    }
}
