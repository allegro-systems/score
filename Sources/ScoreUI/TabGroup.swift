import ScoreCSS
import ScoreCore
import ScoreHTML
import ScoreRuntime

/// A single tab within a ``TabGroup``.
///
/// Each `Tab` has a label displayed in the tab bar and content that is
/// rendered as part of the normal three-pass pipeline (CSS collection,
/// HTML rendering, JS emission). This means components with `@State`,
/// `@Action`, and reactive bindings work correctly inside tabs.
///
/// ```swift
/// TabGroup {
///     Tab("HTML") {
///         CodeBlock(code: htmlSource, language: "html")
///     }
///     Tab("Preview") {
///         Counter()
///     }
/// }
/// ```
public struct Tab: Sendable {

    /// The visible label shown in the tab bar.
    public let label: String

    /// The child node rendered when this tab is selected.
    let content: Content

    /// The raw source text used for copy-to-clipboard, if available.
    let sourceText: String?

    /// Creates a tab with the given label and content node.
    ///
    /// - Parameters:
    ///   - label: The text displayed in the tab bar.
    ///   - content: A node builder producing the panel content.
    public init(_ label: String, @NodeBuilder content: () -> some Node) {
        self.label = label
        self.content = Content(content())
        self.sourceText = nil
    }

    /// Creates a tab with the given label, source text for copying, and content.
    ///
    /// - Parameters:
    ///   - label: The text displayed in the tab bar.
    ///   - sourceText: The raw source text used for the copy button.
    ///   - content: A node builder producing the panel content.
    public init(_ label: String, sourceText: String, @NodeBuilder content: () -> some Node) {
        self.label = label
        self.content = Content(content())
        self.sourceText = sourceText
    }

    /// Creates a tab wrapping a pre-built `Content` value.
    ///
    /// Used internally when constructing tabs from already type-erased nodes.
    ///
    /// - Parameters:
    ///   - label: The text displayed in the tab bar.
    ///   - content: A type-erased node for the panel content.
    public init(_ label: String, content: Content) {
        self.label = label
        self.content = content
        self.sourceText = nil
    }
}

/// A CSS-only tabbed container that switches between panels without JavaScript.
///
/// `TabGroup` renders a series of ``Tab`` items as a tab bar followed by
/// content panels. Selection is driven entirely by hidden radio inputs and the
/// CSS `:checked` pseudo-class, so the component works without any client-side
/// scripting.
///
/// Because tabs store their content as live node trees rather than pre-rendered
/// HTML, the full rendering pipeline (CSS, HTML, and JS) walks through tab
/// content normally. This means components with `@State`, modifiers, and event
/// bindings all work correctly inside tabs.
///
/// The first tab is selected by default.
///
/// ```swift
/// TabGroup {
///     Tab("HTML") {
///         CodeBlock(code: htmlSource, language: "html")
///     }
///     Tab("CSS") {
///         CodeBlock(code: cssSource, language: "css")
///     }
///     Tab("JavaScript") {
///         CodeBlock(code: jsSource, language: "javascript")
///     }
/// }
/// ```
public struct TabGroup: Node, SourceLocatable {

    /// The tabs displayed in this group.
    public let tabs: [Tab]

    /// Whether the tab bar displays a copy-to-clipboard button for the active tab.
    public let showsCopyButton: Bool

    /// An optional filename displayed in the tab bar alongside the tab labels.
    public let filename: String?

    public let sourceLocation: SourceLocation

    /// Creates a tab group from the given tab array.
    ///
    /// - Parameters:
    ///   - filename: An optional filename displayed in the tab bar. Defaults to `nil`.
    ///   - showsCopyButton: Whether to show a copy button. Defaults to `false`.
    ///   - file: The source file (supplied automatically by the compiler).
    ///   - filePath: The full source path (supplied automatically by the compiler).
    ///   - line: The source line (supplied automatically by the compiler).
    ///   - column: The source column (supplied automatically by the compiler).
    ///   - tabs: A closure returning an array of ``Tab`` values.
    public init(
        filename: String? = nil,
        showsCopyButton: Bool = false,
        file: String = #fileID,
        filePath: String = #filePath,
        line: Int = #line,
        column: Int = #column,
        @TabBuilder tabs: () -> [Tab]
    ) {
        self.tabs = tabs()
        self.showsCopyButton = showsCopyButton
        self.filename = filename
        self.sourceLocation = SourceLocation(
            fileID: file, filePath: filePath, line: line, column: column
        )
    }

    /// Creates a tab group from a pre-built array of tabs.
    ///
    /// Used internally by markdown conversion when grouping consecutive
    /// tab-marked fenced code blocks.
    ///
    /// - Parameters:
    ///   - tabs: The tabs to display.
    ///   - file: The source file (supplied automatically by the compiler).
    ///   - filePath: The full source path (supplied automatically by the compiler).
    ///   - line: The source line (supplied automatically by the compiler).
    ///   - column: The source column (supplied automatically by the compiler).
    public init(
        tabs: [Tab],
        file: String = #fileID,
        filePath: String = #filePath,
        line: Int = #line,
        column: Int = #column
    ) {
        self.tabs = tabs
        self.showsCopyButton = false
        self.filename = nil
        self.sourceLocation = SourceLocation(
            fileID: file, filePath: filePath, line: line, column: column
        )
    }

    public var body: Never { fatalError() }
}

// MARK: - Result Builder

/// A result builder that collects ``Tab`` values into an array.
@resultBuilder
public struct TabBuilder {

    /// Builds an array of tabs from individual ``Tab`` expressions.
    public static func buildBlock(_ tabs: Tab...) -> [Tab] {
        tabs
    }
}

// MARK: - HTML Rendering

extension TabGroup: HTMLRenderable {
    package func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        guard !tabs.isEmpty else { return }

        let groupId = "tg-\(abs(tabs.map(\.label).joined().hashValue))"

        output.append("<div data-tab-group")
        if renderer.isDevMode {
            output.append(" data-source=\"\(sourceLocation.fileID):\(sourceLocation.line):\(sourceLocation.column)\"")
            output.append(" data-source-path=\"\(sourceLocation.filePath):\(sourceLocation.line):\(sourceLocation.column)\"")
        }
        output.append(">")

        for (index, _) in tabs.enumerated() {
            let inputId = "\(groupId)-\(index)"
            let checked = index == 0 ? " checked" : ""
            output.append(
                "<input type=\"radio\" name=\"\(groupId)\" id=\"\(inputId)\"\(checked)>"
            )
        }

        output.append("<nav data-tab-bar>")
        if let filename {
            output.append("<span data-code-label>\(filename.attributeEscaped)</span>")
        }
        output.append("<span data-tab-labels>")
        for (index, tab) in tabs.enumerated() {
            let inputId = "\(groupId)-\(index)"
            output.append(
                "<label for=\"\(inputId)\" data-tab-label>\(tab.label.attributeEscaped)</label>"
            )
        }
        output.append("</span>")
        if showsCopyButton {
            output.append(
                """
                <button data-code-copy onclick="var g=this.closest('[data-tab-group]');\
                var inputs=g.querySelectorAll('input[type=radio]');\
                var idx=0;for(var i=0;i<inputs.length;i++){if(inputs[i].checked){idx=i;break}}\
                var src=g.querySelectorAll('[data-tab-panel]')[idx].querySelector('[data-tab-source]');\
                if(!src)return;\
                navigator.clipboard.writeText(src.textContent)\
                .then((function(){var b=this;b.textContent='Copied!';\
                setTimeout(function(){b.textContent='Copy'},1500)}).bind(this))">Copy</button>\
                <script>(function(){var g=document.currentScript.closest('[data-tab-group]');\
                var btn=g.querySelector('[data-code-copy]');\
                var inputs=g.querySelectorAll('input[type=radio]');\
                function u(){var idx=0;for(var i=0;i<inputs.length;i++){if(inputs[i].checked){idx=i;break}}\
                var p=g.querySelectorAll('[data-tab-panel]')[idx];\
                btn.style.display=p.querySelector('[data-tab-source]')?'':'none'}\
                for(var i=0;i<inputs.length;i++)inputs[i].addEventListener('change',u);u()})()</script>
                """)
        }
        output.append("</nav>")

        for tab in tabs {
            output.append("<div data-tab-panel>")
            if let source = tab.sourceText {
                output.append("<pre data-tab-source hidden>\(source.attributeEscaped)</pre>")
            }
            renderer.write(tab.content, to: &output)
            output.append("</div>")
        }

        output.append("</div>")
    }
}

extension TabGroup: HTMLAttributeInjectable {
    package func renderHTML(
        merging extraAttributes: [(String, String)],
        into output: inout String,
        renderer: HTMLRenderer
    ) {
        renderHTML(into: &output, renderer: renderer)
    }
}

// MARK: - CSS Walking

extension TabGroup: CSSWalkable {
    package var htmlTag: String? { "div" }

    package func walkChildren(collector: inout CSSCollector) {
        for tab in tabs {
            collector.collect(from: tab.content)
        }
    }
}

// MARK: - JS Event Walking

extension TabGroup: JSEventWalkable {
    package func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {
        for tab in tabs {
            JSEmitter.walkForEvents(tab.content, into: &bindings)
        }
    }

    package func walkForJSElements(
        states: inout [JSEmitter.StateInfo],
        computeds: inout [JSEmitter.ComputedInfo],
        actions: inout [JSEmitter.ActionInfo]
    ) {
        for tab in tabs {
            JSEmitter.walkForComponents(
                tab.content, states: &states, computeds: &computeds, actions: &actions
            )
        }
    }

    package func walkForJSScoped(
        scopes: inout [JSEmitter.ComponentScope],
        pageLevelBindings: inout [JSEmitter.EventBinding],
        pageLevelReactive: inout [JSEmitter.ReactiveBinding]
    ) {
        for tab in tabs {
            JSEmitter.walkForScopes(
                tab.content,
                scopes: &scopes,
                pageLevelBindings: &pageLevelBindings,
                pageLevelReactive: &pageLevelReactive
            )
        }
    }

    package func walkForJSReactive(into bindings: inout [JSEmitter.ReactiveBinding]) {
        for tab in tabs {
            JSEmitter.walkForReactiveBindings(tab.content, into: &bindings)
        }
    }
}
