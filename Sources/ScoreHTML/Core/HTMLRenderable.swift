import ScoreCore

/// A node that knows how to write its own HTML representation.
///
/// Types conforming to `HTMLRenderable` can be dispatched directly by
/// `HTMLRenderer` without relying on runtime type checks. All built-in
/// Score primitive nodes adopt this protocol via extensions in the
/// ScoreHTML module.
package protocol HTMLRenderable {
    func renderHTML(into output: inout String, renderer: HTMLRenderer)
}
