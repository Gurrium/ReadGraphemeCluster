import Foundation

enum GraphemeCluterBreak {
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

public func readGraphemeCluster(from fileHandle: FileHandle) -> UnicodeScalar {
    .init(0x0020)
}
