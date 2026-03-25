/// A modifier that makes a node draggable using the HTML5 Drag and Drop API.
///
/// ### Example
///
/// ```swift
/// Card()
///     .draggable(data: "card-1")
/// ```
///
/// ### HTML Mapping
///
/// Adds `draggable="true"` and `data-drag-data` attributes to the element.
public struct DraggableModifier: ModifierValue {

    /// The data to transfer when dragging.
    public let data: String

    /// The allowed drag effect.
    public let effectAllowed: DragEffect

    public init(data: String, effectAllowed: DragEffect = .move) {
        self.data = data
        self.effectAllowed = effectAllowed
    }
}

/// A modifier that marks a node as a valid drop target.
///
/// ### Example
///
/// ```swift
/// Container()
///     .dropTarget(action: "handleDrop")
/// ```
public struct DropTargetModifier: ModifierValue {

    /// The name of the action handler to invoke on drop.
    public let handler: String

    /// The allowed drop effect.
    public let dropEffect: DragEffect

    public init(handler: String, dropEffect: DragEffect = .move) {
        self.handler = handler
        self.dropEffect = dropEffect
    }
}

/// The visual effect shown during a drag-and-drop operation.
public enum DragEffect: String, Sendable {
    case copy
    case move
    case link
    case none
}

extension Node {

    /// Makes this node draggable with the given transfer data.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Card(title: "Task")
    ///     .draggable(data: "task-123")
    /// ```
    public func draggable(data: String, effectAllowed: DragEffect = .move) -> ModifiedNode<Self> {
        modifier(DraggableModifier(data: data, effectAllowed: effectAllowed))
    }

    /// Makes this node a valid drop target.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Column()
    ///     .dropTarget(handler: "handleDrop")
    /// ```
    public func dropTarget(handler: String, dropEffect: DragEffect = .move) -> ModifiedNode<Self> {
        modifier(DropTargetModifier(handler: handler, dropEffect: dropEffect))
    }
}
