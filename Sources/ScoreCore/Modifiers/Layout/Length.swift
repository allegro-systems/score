/// A CSS length value that can be expressed as pixels or a percentage.
///
/// `Length` enables sizing modifiers to accept both absolute pixel values
/// and relative percentage values. It conforms to `ExpressibleByIntegerLiteral`
/// and `ExpressibleByFloatLiteral` so that bare numeric literals default to
/// pixel values, preserving the familiar `.size(maxWidth: 960)` call-site
/// syntax while also allowing `.size(height: .percent(100))`.
///
/// ### Example
///
/// ```swift
/// // Pixel value (via literal)
/// .size(width: 320)
///
/// // Percentage value (via static member)
/// .size(height: .percent(100))
/// ```
public enum Length: Sendable, Hashable {

    /// An absolute length in pixels.
    case pixels(Double)

    /// A relative length as a percentage of the containing block.
    case percent(Double)

    /// A viewport-height relative length.
    case vh(Double)

    /// A viewport-width relative length.
    case vw(Double)
}

extension Length: DevDescribable {
    public var devDescription: String {
        switch self {
        case .pixels(let v):
            return v.cleanValue
        case .percent(let v):
            return "\(v.cleanValue)%"
        case .vh(let v):
            return "\(v.cleanValue)vh"
        case .vw(let v):
            return "\(v.cleanValue)vw"
        }
    }
}

extension Length: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: IntegerLiteralType) {
        self = .pixels(Double(value))
    }
}

extension Length: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .pixels(value)
    }
}
