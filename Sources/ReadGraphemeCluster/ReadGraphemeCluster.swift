import Foundation

enum BoundaryPropertyValue {
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

    func match(_ scalar: UnicodeScalar) -> Bool {
        switch self {
        case .sot:
            preconditionFailure("sot doesn't match anything")
        case .eot:
            preconditionFailure("eot doesn't match anything")
        case .cr:
            return scalar.value == 0x000d
        case .lf:
            return scalar.value == 0x000a
        case .control:
            let generalCategory = scalar.properties.generalCategory

            return (
                generalCategory == .lineSeparator ||
                generalCategory == .paragraphSeparator ||
                generalCategory == .control ||
                generalCategory == .unassigned && scalar.properties.isDefaultIgnorableCodePoint ||
                generalCategory == .format
            ) &&
            scalar.value != 0x000d &&
            scalar.value != 0x000a &&
            scalar.value != 0x200c &&
            scalar.value != 0x200d &&
            // https://www.unicode.org/Public/UCD/latest/ucd/auxiliary/GraphemeBreakProperty.txt
            (
                (0x0600...0x0605).contains(scalar.value) ||
                scalar.value == 0x06dd ||
                scalar.value == 0x070f ||
                (0x0890...0x0891).contains(scalar.value) ||
                scalar.value == 0x08e2 ||
                scalar.value == 0x0d4e ||
                scalar.value == 0x110bd ||
                scalar.value == 0x110cd ||
                (0x111c2...0x111c3).contains(scalar.value) ||
                scalar.value == 0x1193f ||
                scalar.value == 0x11941 ||
                scalar.value == 0x11a3a ||
                (0x11a84...0x11ab9).contains(scalar.value) ||
                scalar.value == 0x11d46 ||
                scalar.value == 0x11f02
            )
        case .extend:
        case .zwj:
        case .ri:
        case .prepend:
        case .spacingMark:
        case .l:
        case .v:
        case .t:
        case .lv:
        case .lvt:
        case .eBase:
        case .eModifier:
        case .glueAfterZWJ:
        case .ebg:
        case .any:
        }
    }
}

public struct ReadGraphemeCluster {}

public func readGraphemeCluster(from fileHandle: FileHandle) -> UnicodeScalar {
    .init(0x0020)
}
