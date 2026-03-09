/// Injects development-time annotations and scripts into rendered HTML.
public struct DevToolsInjector: Sendable {

    private init() {}

    /// Annotates a component's HTML with `data-score-*` attributes for dev tools.
    ///
    /// In production, returns the HTML unchanged.
    public static func annotateComponent(
        bodyHTML: String,
        componentName: String,
        sourceFile: String,
        sourceLine: Int,
        environment: Environment
    ) -> String {
        guard environment == .development else { return bodyHTML }

        // Find the first `>` in the HTML and inject attributes before it
        guard let closeIndex = bodyHTML.firstIndex(of: ">") else { return bodyHTML }

        var result = String(bodyHTML[..<closeIndex])
        result.append(" data-score-component=\"\(componentName)\"")
        result.append(" data-score-file=\"\(sourceFile)\"")
        result.append(" data-score-line=\"\(sourceLine)\"")
        result.append(String(bodyHTML[closeIndex...]))
        return result
    }

    /// Returns a `<script>` tag for the Score dev tools, or empty in production.
    public static func scriptTag(environment: Environment) -> String {
        guard environment == .development else { return "" }
        return "<script type=\"module\" src=\"/static/score-devtools.js\"></script>"
    }

    /// Returns a `<script>` tag with reactive state metadata for dev tools,
    /// or empty in production or when no state exists.
    public static func stateMetadataScript(
        stateNames: [String],
        computedNames: [String],
        environment: Environment
    ) -> String {
        guard environment == .development else { return "" }
        guard !stateNames.isEmpty || !computedNames.isEmpty else { return "" }

        let stateJSON = stateNames.map { "\"\($0)\"" }.joined(separator: ", ")
        let computedJSON = computedNames.map { "\"\($0)\"" }.joined(separator: ", ")

        return """
            <script>
            window.__SCORE_DEV_META__ = {
              states: [\(stateJSON)],
              computeds: [\(computedJSON)]
            };
            </script>
            """
    }
}
