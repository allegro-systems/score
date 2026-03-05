import ScoreCore

/// A trigger button for a single tab within a ``TabGroup``.
///
/// `TabTrigger` renders as a button inside the tab list and is
/// linked to its corresponding ``TabPanel`` via the `panelID`.
///
/// ### Example
///
/// ```swift
/// TabTrigger(panelID: "overview-panel", isActive: true) {
///     Text(verbatim: "Overview")
/// }
/// ```
public struct TabTrigger<Content: Node>: Component {

    /// The ID of the associated ``TabPanel``.
    public let panelID: String

    /// Whether this trigger is the currently active tab.
    public let isActive: Bool

    /// The visible content inside the trigger button.
    public let content: Content

    /// Creates a tab trigger.
    ///
    /// - Parameters:
    ///   - panelID: The identifier of the panel this trigger controls.
    ///   - isActive: Whether this tab is currently active. Defaults to `false`.
    ///   - content: A `@NodeBuilder` closure producing the trigger's
    ///     visible content.
    public init(
        panelID: String,
        isActive: Bool = false,
        @NodeBuilder content: () -> Content
    ) {
        self.panelID = panelID
        self.isActive = isActive
        self.content = content()
    }

    public var body: some Node {
        Button {
            content
        }
        .dataAttribute("part", "trigger")
        .dataAttribute("state", isActive ? "active" : "inactive")
        .accessibility(role: "tab")
    }
}

/// A single tab panel within a ``TabGroup``.
///
/// Each `TabPanel` represents one tab's label and associated content.
///
/// ### Example
///
/// ```swift
/// TabPanel(label: "Overview", isActive: true) {
///     Text(verbatim: "Overview content goes here.")
/// }
/// ```
public struct TabPanel<Content: Node>: Component {

    /// The visible label for this tab.
    public let label: String

    /// Whether this tab is the initially active tab.
    public let isActive: Bool

    /// The content displayed when this tab is selected.
    public let content: Content

    /// Creates a tab panel.
    ///
    /// - Parameters:
    ///   - label: The tab's visible label text.
    ///   - isActive: Whether this tab starts as active. Defaults to `false`.
    ///   - content: A `@NodeBuilder` closure producing the panel's content.
    public init(
        label: String,
        isActive: Bool = false,
        @NodeBuilder content: () -> Content
    ) {
        self.label = label
        self.isActive = isActive
        self.content = content()
    }

    public var body: some Node {
        Section {
            content
        }
        .dataAttribute("part", "panel")
        .dataAttribute("state", isActive ? "active" : "inactive")
        .accessibility(role: "tabpanel")
    }
}

/// A tabbed interface that switches between content panels.
///
/// `TabGroup` renders a tab trigger list followed by the ``TabPanel``
/// children. The Score theme and runtime handle switching between
/// panels based on which tab is selected.
///
/// The trigger list is automatically generated from the ``TabPanel``
/// children's labels, and a separate ``TabTrigger`` sub-component is
/// available for custom trigger rendering.
///
/// ### Example
///
/// ```swift
/// TabGroup {
///     TabPanel(label: "Overview", isActive: true) {
///         Text(verbatim: "Overview content")
///     }
///     TabPanel(label: "Settings") {
///         Text(verbatim: "Settings content")
///     }
/// }
/// ```
public struct TabGroup<Content: Node>: Component {

    /// The zero-based index of the currently active tab.
    @State public var activeIndex: Int

    /// The ``TabPanel`` children that form the tabbed interface.
    public let content: Content

    /// Switches to the tab at the given index.
    ///
    /// The clicked trigger's `data-index` attribute determines which tab
    /// to activate. Called via `event.currentTarget.dataset.index`.
    @Action(js: "var i = parseInt(event.currentTarget.dataset.index, 10); if (!isNaN(i)) activeIndex.set(i)")
    public var switchTab = {}

    /// Creates a tab group.
    ///
    /// - Parameters:
    ///   - activeIndex: The initially active tab index. Defaults to `0`.
    ///   - content: A `@NodeBuilder` closure providing ``TabPanel``
    ///     children.
    public init(
        activeIndex: Int = 0,
        @NodeBuilder content: () -> Content
    ) {
        let tabEffect = """
            var idx = activeIndex.get(); \
            scope.querySelectorAll('[data-part="trigger"]').forEach(function(t, i) { t.dataset.state = i === idx ? 'active' : 'inactive'; }); \
            scope.querySelectorAll('[data-part="panel"]').forEach(function(p, i) { p.dataset.state = i === idx ? 'active' : 'inactive'; })
            """
        self._activeIndex = State(wrappedValue: activeIndex, effect: tabEffect)
        self.content = content()
    }

    public var body: some Node {
        Stack {
            content
        }
        .dataAttribute("component", "tabs")
        .accessibility(role: "tablist")
    }
}
