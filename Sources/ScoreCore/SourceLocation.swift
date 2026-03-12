/// A compile-time source location captured at a node's call site.
///
/// `SourceLocation` records where a node was created in Swift source code,
/// enabling development tools to map rendered HTML elements back to their
/// originating declarations. The location is captured automatically via
/// `#fileID`, `#filePath`, `#line`, and `#column` default parameter values
/// in node initializers, requiring no extra work from the caller.
///
/// Source locations are emitted as `data-source` attributes on HTML elements
/// when the renderer is running in development mode. The `filePath` property
/// provides the absolute filesystem path needed for editor integration (e.g.
/// opening the source file in VS Code or Cursor on click).
///
/// ### Example
///
/// ```swift
/// // SourceLocation is captured automatically — no action needed:
/// Paragraph {
///     "Hello, world!"
/// }
/// // In dev mode, renders: <p data-source="MyModule/HomePage.swift:12:5"
/// //   data-source-path="/abs/path/HomePage.swift">…</p>
/// ```
public struct SourceLocation: Sendable, Equatable {

    /// The file identifier in `Module/File.swift` format.
    ///
    /// This value comes from `#fileID` and provides a portable, compact
    /// representation of the source file without exposing absolute paths.
    public let fileID: String

    /// The absolute filesystem path to the source file.
    ///
    /// This value comes from `#filePath` and is used in development mode to
    /// enable click-to-open-in-editor functionality in the devtools overlay.
    public let filePath: String

    /// The line number in the source file where the node was created.
    public let line: Int

    /// The column number in the source file where the node was created.
    public let column: Int

    /// Creates a source location with the given file, line, and column.
    ///
    /// You rarely need to call this initializer directly — node initializers
    /// capture the location automatically via default parameter values.
    public init(
        fileID: String = #fileID,
        filePath: String = #filePath,
        line: Int = #line,
        column: Int = #column
    ) {
        self.fileID = fileID
        self.filePath = filePath
        self.line = line
        self.column = column
    }
}

/// A node that carries compile-time source location information.
///
/// Conforming to `SourceLocatable` allows the HTML renderer to emit
/// `data-source` attributes in development mode, mapping each rendered
/// element back to the Swift source line that created it.
///
/// All built-in Score nodes that render as HTML elements conform to this
/// protocol automatically. Custom nodes can opt in by adding a
/// `sourceLocation` property and capturing the location in their
/// initializer via `#fileID`, `#line`, and `#column` default parameters.
public protocol SourceLocatable {

    /// The source location where this node was created.
    var sourceLocation: SourceLocation { get }
}
