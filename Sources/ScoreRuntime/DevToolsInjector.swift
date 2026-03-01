/// Injects development-only instrumentation into rendered HTML.
///
/// `DevToolsInjector` adds two kinds of annotations in development mode:
///
/// 1. **Component data attributes** — `data-score-component`, `data-score-file`,
///    and `data-score-line` on the root element of each page so the dev tools
///    panel can list components with clickable source links.
///
/// 2. **Dev tools script tag** — a `<script>` reference to
///    `/_score/score-devtools.js` that loads the floating panel UI.
///
/// In production mode, all methods are no-ops and return their inputs unchanged.
public enum DevToolsInjector: Sendable {

    /// Annotates page body HTML with component data attributes in development mode.
    ///
    /// Inserts `data-score-component`, `data-score-file`, and `data-score-line`
    /// on the first opening HTML tag found in `bodyHTML`.
    ///
    /// - Parameters:
    ///   - bodyHTML: The rendered HTML body string.
    ///   - componentName: The page/component type name.
    ///   - sourceFile: The Swift source file path.
    ///   - sourceLine: The line number in the source file.
    ///   - environment: The current environment.
    /// - Returns: The annotated HTML, or the original if in production.
    public static func annotateComponent(
        bodyHTML: String,
        componentName: String,
        sourceFile: String,
        sourceLine: Int,
        environment: Environment
    ) -> String {
        guard environment == .development else { return bodyHTML }

        // Find the first `<tagname` and inject attributes before the closing `>`.
        guard let openAngle = bodyHTML.firstIndex(of: "<") else { return bodyHTML }
        let afterOpen = bodyHTML.index(after: openAngle)
        guard afterOpen < bodyHTML.endIndex, bodyHTML[afterOpen] != "/" else { return bodyHTML }

        // Find the closing `>` of the first tag.
        guard let closeAngle = bodyHTML[afterOpen...].firstIndex(of: ">") else { return bodyHTML }

        let attrs = " data-score-component=\"\(componentName)\" data-score-file=\"\(sourceFile)\" data-score-line=\"\(sourceLine)\""

        var result = String(bodyHTML[bodyHTML.startIndex..<closeAngle])
        result.append(attrs)
        result.append(String(bodyHTML[closeAngle...]))
        return result
    }

    /// Returns the dev tools `<script>` tag for injection before `</body>`.
    ///
    /// Returns an empty string in production mode.
    ///
    /// - Parameter environment: The current environment.
    /// - Returns: A `<script>` tag string, or empty.
    public static func scriptTag(environment: Environment) -> String {
        guard environment == .development else { return "" }
        return "<script type=\"module\" src=\"/_score/score-devtools.js\"></script>"
    }

    /// Returns a metadata `<script>` block embedding reactive state names for
    /// the dev tools State tab.
    ///
    /// - Parameters:
    ///   - stateNames: The names of `@State` properties on this page.
    ///   - computedNames: The names of `@Computed` properties on this page.
    ///   - environment: The current environment.
    /// - Returns: A `<script>` tag with JSON metadata, or empty.
    public static func stateMetadataScript(
        stateNames: [String],
        computedNames: [String],
        environment: Environment
    ) -> String {
        guard environment == .development else { return "" }
        guard !stateNames.isEmpty || !computedNames.isEmpty else { return "" }

        let statesJSON = stateNames.map { "\"\($0)\"" }.joined(separator: ",")
        let computedsJSON = computedNames.map { "\"\($0)\"" }.joined(separator: ",")

        return "<script>window.__SCORE_DEV_META__={\"states\":[\(statesJSON)],\"computeds\":[\(computedsJSON)]};</script>"
    }
}
