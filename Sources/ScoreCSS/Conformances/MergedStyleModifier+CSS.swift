import ScoreCore

/// Emits CSS declarations by merging defaults with user overrides.
///
/// Declarations from `defaults` are emitted first, then any declaration
/// from `overrides` that shares the same property name replaces the
/// default. This ensures user-supplied styles always win — if the
/// component default is `padding: 24px` but the user passes
/// `padding: 32px`, only `padding: 32px` is emitted.
extension MergedStyleModifier: CSSRepresentable {
    func cssDeclarations() -> [CSSDeclaration] {
        // Collect default declarations.
        var merged: [(property: String, value: String)] = []
        for modifier in defaults {
            for decl in CSSEmitter.declarations(for: modifier) {
                merged.append((decl.property, decl.value))
            }
        }

        // Collect override declarations and replace matching properties.
        var overrideDeclarations: [(property: String, value: String)] = []
        for modifier in overrides {
            for decl in CSSEmitter.declarations(for: modifier) {
                overrideDeclarations.append((decl.property, decl.value))
            }
        }

        // Build a set of overridden property names.
        let overriddenProperties = Set(overrideDeclarations.map(\.property))

        // Filter out defaults that are overridden, then append overrides.
        var result: [CSSDeclaration] = []
        for (property, value) in merged where !overriddenProperties.contains(property) {
            result.append(CSSDeclaration(property: property, value: value))
        }
        for (property, value) in overrideDeclarations {
            result.append(CSSDeclaration(property: property, value: value))
        }

        return result
    }
}
