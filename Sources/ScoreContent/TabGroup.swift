import ScoreCore
import ScoreHTML

/// A single tab within a ``TabGroup``.
///
/// Each `Tab` has a label displayed in the tab bar and content rendered when
/// the tab is selected. Tabs are combined inside a ``TabGroup`` to produce a
/// CSS-only tabbed interface that requires no JavaScript.
///
/// ```swift
/// TabGroup {
///     Tab("HTML") {
///         CodeBlock(code: htmlSource, language: "html")
///     }
///     Tab("CSS") {
///         CodeBlock(code: cssSource, language: "css")
///     }
/// }
/// ```
public struct Tab: Sendable {

    /// The visible label shown in the tab bar.
    public let label: String

    /// The pre-rendered HTML content for this tab panel.
    let renderedContent: String

    /// The raw source text used for copy-to-clipboard, if available.
    let sourceText: String?

    /// Creates a tab with the given label and content node.
    ///
    /// The content is rendered to HTML eagerly when the tab is created.
    ///
    /// - Parameters:
    ///   - label: The text displayed in the tab bar.
    ///   - content: A node builder producing the panel content.
    public init(_ label: String, @NodeBuilder content: () -> some Node) {
        self.label = label
        self.renderedContent = HTMLRenderer().render(content())
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
        self.renderedContent = HTMLRenderer().render(content())
        self.sourceText = sourceText
    }

    /// Creates a tab from a pre-rendered HTML string.
    ///
    /// Used internally by ``MarkdownConverter`` when grouping consecutive
    /// tab-marked fenced code blocks.
    ///
    /// - Parameters:
    ///   - label: The text displayed in the tab bar.
    ///   - html: Pre-rendered HTML for the panel content.
    init(label: String, html: String) {
        self.label = label
        self.renderedContent = html
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
public struct TabGroup: Node {

    /// The tabs displayed in this group.
    public let tabs: [Tab]

    /// Whether the tab bar displays a copy-to-clipboard button for the active tab.
    public let showsCopyButton: Bool

    /// An optional filename displayed in the tab bar alongside the tab labels.
    public let filename: String?

    /// Creates a tab group from the given tab array.
    ///
    /// - Parameters:
    ///   - filename: An optional filename displayed in the tab bar. Defaults to `nil`.
    ///   - showsCopyButton: Whether to show a copy button. Defaults to `false`.
    ///   - tabs: A closure returning an array of ``Tab`` values.
    public init(
        filename: String? = nil,
        showsCopyButton: Bool = false,
        @TabBuilder tabs: () -> [Tab]
    ) {
        self.tabs = tabs()
        self.showsCopyButton = showsCopyButton
        self.filename = filename
    }

    /// Creates a tab group from a pre-built array of tabs.
    ///
    /// Used internally by ``MarkdownConverter`` when grouping consecutive
    /// tab-marked fenced code blocks.
    init(tabs: [Tab]) {
        self.tabs = tabs
        self.showsCopyButton = false
        self.filename = nil
    }

    public var body: some Node {
        RawTextNode(renderHTML())
    }

    private func renderHTML() -> String {
        guard !tabs.isEmpty else { return "" }

        let groupId = "tg-\(abs(tabs.map(\.label).joined().hashValue))"
        var html = "<div data-tab-group>"

        for (index, _) in tabs.enumerated() {
            let inputId = "\(groupId)-\(index)"
            let checked = index == 0 ? " checked" : ""
            html.append(
                "<input type=\"radio\" name=\"\(groupId)\" id=\"\(inputId)\"\(checked)>"
            )
        }

        html.append("<nav data-tab-bar>")
        if let filename {
            html.append("<span data-code-label>\(escapeHTML(filename))</span>")
        }
        html.append("<span data-tab-labels>")
        for (index, tab) in tabs.enumerated() {
            let inputId = "\(groupId)-\(index)"
            html.append(
                "<label for=\"\(inputId)\" data-tab-label>\(escapeHTML(tab.label))</label>"
            )
        }
        html.append("</span>")
        if showsCopyButton {
            html.append(
                """
                <button data-code-copy onclick="var g=this.closest('[data-tab-group]');\
                var inputs=g.querySelectorAll('input[type=radio]');\
                var idx=0;for(var i=0;i<inputs.length;i++){if(inputs[i].checked){idx=i;break}}\
                var src=g.querySelectorAll('[data-tab-source]')[idx];\
                navigator.clipboard.writeText(src.textContent)\
                .then((function(){var b=this;b.textContent='Copied!';\
                setTimeout(function(){b.textContent='Copy'},1500)}).bind(this))">Copy</button>
                """)
        }
        html.append("</nav>")

        for tab in tabs {
            html.append("<div data-tab-panel>")
            if let source = tab.sourceText {
                html.append("<pre data-tab-source hidden>\(escapeHTML(source))</pre>")
            }
            html.append(tab.renderedContent)
            html.append("</div>")
        }

        html.append("</div>")
        return html
    }

    private func escapeHTML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}

/// A result builder that collects ``Tab`` values into an array.
@resultBuilder
public struct TabBuilder {

    /// Builds an array of tabs from individual ``Tab`` expressions.
    public static func buildBlock(_ tabs: Tab...) -> [Tab] {
        tabs
    }
}
