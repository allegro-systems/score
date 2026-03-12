/// A node that renders an inline SVG element.
///
/// `Svg` wraps its children in an `<svg>` element with an optional
/// `viewBox`, intrinsic dimensions, and a default fill. Child content is
/// typically composed of SVG shape nodes such as ``Path``, ``Circle``,
/// ``SvgRect``, and ``SvgLine``.
///
/// ### Example
///
/// ```swift
/// Svg(viewBox: "0 0 24 24", width: 24, height: 24) {
///     Path(d: "M12 2L2 22h20L12 2z", fill: "currentColor")
/// }
/// ```
public struct Svg<Content: Node>: Node, SourceLocatable {

    /// The SVG coordinate system defined as `"minX minY width height"`.
    public let viewBox: String?

    /// The rendered width of the SVG element in CSS pixels.
    public let width: Int?

    /// The rendered height of the SVG element in CSS pixels.
    public let height: Int?

    /// The default fill colour applied to child shapes.
    ///
    /// Set to `"none"` to disable fills by default.
    public let fill: String?

    /// The child nodes rendered inside the `<svg>` element.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates an SVG element with the given attributes and child content.
    public init(
        viewBox: String? = nil,
        width: Int? = nil,
        height: Int? = nil,
        fill: String? = nil,
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.viewBox = viewBox
        self.width = width
        self.height = height
        self.fill = fill
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    public var body: Never { fatalError() }
}

/// A node that renders an SVG `<path>` element.
///
/// `Path` defines a geometric shape using the `d` attribute's path data
/// syntax. Presentation attributes control stroke and fill rendering.
///
/// ### Example
///
/// ```swift
/// Path(
///     d: "M10 10 H 90 V 90 H 10 Z",
///     stroke: "currentColor",
///     strokeWidth: 2,
///     fill: "none"
/// )
/// ```
public struct Path: Node, SourceLocatable {

    /// The path data string defining the shape geometry.
    public let d: String

    /// The stroke colour. When `nil`, no stroke is rendered.
    public let stroke: String?

    /// The stroke width in SVG user units.
    public let strokeWidth: Double?

    /// The shape used at the end of open subpaths.
    public let strokeLinecap: String?

    /// The shape used at the corners of stroked paths.
    public let strokeLinejoin: String?

    /// The fill colour. Set to `"none"` for an unfilled path.
    public let fill: String?

    /// The opacity of the element, from `0` (transparent) to `1` (opaque).
    public let opacity: Double?
    public let sourceLocation: SourceLocation

    /// Creates a path element with the given attributes.
    public init(
        d: String,
        stroke: String? = nil,
        strokeWidth: Double? = nil,
        strokeLinecap: String? = nil,
        strokeLinejoin: String? = nil,
        fill: String? = nil,
        opacity: Double? = nil,
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column
    ) {
        self.d = d
        self.stroke = stroke
        self.strokeWidth = strokeWidth
        self.strokeLinecap = strokeLinecap
        self.strokeLinejoin = strokeLinejoin
        self.fill = fill
        self.opacity = opacity
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
    }

    public var body: Never { fatalError() }
}

/// A node that renders an SVG `<circle>` element.
///
/// ### Example
///
/// ```swift
/// Circle(cx: 50, cy: 50, r: 40, fill: "currentColor")
/// ```
public struct Circle: Node, SourceLocatable {

    /// The x-coordinate of the circle centre.
    public let cx: Double

    /// The y-coordinate of the circle centre.
    public let cy: Double

    /// The radius of the circle.
    public let r: Double

    /// The fill colour. Set to `"none"` for an unfilled circle.
    public let fill: String?

    /// The stroke colour.
    public let stroke: String?

    /// The stroke width in SVG user units.
    public let strokeWidth: Double?

    /// The opacity of the element.
    public let opacity: Double?
    public let sourceLocation: SourceLocation

    /// Creates a circle element with the given attributes.
    public init(
        cx: Double,
        cy: Double,
        r: Double,
        fill: String? = nil,
        stroke: String? = nil,
        strokeWidth: Double? = nil,
        opacity: Double? = nil,
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column
    ) {
        self.cx = cx
        self.cy = cy
        self.r = r
        self.fill = fill
        self.stroke = stroke
        self.strokeWidth = strokeWidth
        self.opacity = opacity
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
    }

    public var body: Never { fatalError() }
}

/// A node that renders an SVG `<rect>` element.
///
/// Named `SvgRect` to avoid collision with layout rectangle types.
///
/// ### Example
///
/// ```swift
/// SvgRect(x: 10, y: 10, width: 80, height: 80, fill: "currentColor")
/// ```
public struct SvgRect: Node, SourceLocatable {

    /// The x-coordinate of the rectangle's origin.
    public let x: Double

    /// The y-coordinate of the rectangle's origin.
    public let y: Double

    /// The width of the rectangle.
    public let width: Double

    /// The height of the rectangle.
    public let height: Double

    /// The horizontal corner radius for rounded rectangles.
    public let rx: Double?

    /// The vertical corner radius for rounded rectangles.
    public let ry: Double?

    /// The fill colour.
    public let fill: String?

    /// The stroke colour.
    public let stroke: String?

    /// The stroke width.
    public let strokeWidth: Double?

    /// The element opacity.
    public let opacity: Double?
    public let sourceLocation: SourceLocation

    /// Creates a rectangle element with the given attributes.
    public init(
        x: Double = 0,
        y: Double = 0,
        width: Double,
        height: Double,
        rx: Double? = nil,
        ry: Double? = nil,
        fill: String? = nil,
        stroke: String? = nil,
        strokeWidth: Double? = nil,
        opacity: Double? = nil,
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column
    ) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.rx = rx
        self.ry = ry
        self.fill = fill
        self.stroke = stroke
        self.strokeWidth = strokeWidth
        self.opacity = opacity
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
    }

    public var body: Never { fatalError() }
}

/// A node that renders an SVG `<line>` element.
///
/// Named `SvgLine` to avoid collision with text line types.
///
/// ### Example
///
/// ```swift
/// SvgLine(x1: 0, y1: 0, x2: 100, y2: 100, stroke: "currentColor")
/// ```
public struct SvgLine: Node, SourceLocatable {

    /// The x-coordinate of the line's start point.
    public let x1: Double

    /// The y-coordinate of the line's start point.
    public let y1: Double

    /// The x-coordinate of the line's end point.
    public let x2: Double

    /// The y-coordinate of the line's end point.
    public let y2: Double

    /// The stroke colour.
    public let stroke: String?

    /// The stroke width.
    public let strokeWidth: Double?

    /// The line cap style.
    public let strokeLinecap: String?

    /// The element opacity.
    public let opacity: Double?
    public let sourceLocation: SourceLocation

    /// Creates a line element with the given attributes.
    public init(
        x1: Double,
        y1: Double,
        x2: Double,
        y2: Double,
        stroke: String? = nil,
        strokeWidth: Double? = nil,
        strokeLinecap: String? = nil,
        opacity: Double? = nil,
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column
    ) {
        self.x1 = x1
        self.y1 = y1
        self.x2 = x2
        self.y2 = y2
        self.stroke = stroke
        self.strokeWidth = strokeWidth
        self.strokeLinecap = strokeLinecap
        self.opacity = opacity
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
    }

    public var body: Never { fatalError() }
}
