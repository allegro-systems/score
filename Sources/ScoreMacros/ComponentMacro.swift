import SwiftSyntax
import SwiftSyntaxMacros

/// Implementation of the `@Component` macro.
///
/// When applied to a struct, this macro:
/// 1. Adds `Component` protocol conformance via an extension.
/// 2. Applies `@NodeBuilder` to the `body` property so multi-expression
///    bodies work without an explicit annotation.
/// 3. If the struct has a `content: Content` stored property, generates
///    an `init` with a `@NodeBuilder` trailing-closure parameter that
///    wraps the builder result in `Content(...)`.
///
/// For structs without a `content: Content` property, only conformance
/// and the `@NodeBuilder` attribute are added — no initializer is generated.
public struct ComponentMacro: MemberMacro, MemberAttributeMacro, ExtensionMacro {

    // MARK: - MemberAttributeMacro

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        guard let variable = member.as(VariableDeclSyntax.self) else { return [] }

        let isBody = variable.bindings.contains { binding in
            binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "body"
                && binding.accessorBlock != nil
        }
        guard isBody else { return [] }

        let alreadyAnnotated = variable.attributes.contains { attr in
            attr.as(AttributeSyntax.self)?.attributeName.trimmedDescription == "NodeBuilder"
        }
        guard !alreadyAnnotated else { return [] }

        return [AttributeSyntax(atSign: .atSignToken(), attributeName: IdentifierTypeSyntax(name: .identifier("NodeBuilder")))]
    }

    // MARK: - MemberMacro

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw ComponentMacroError.notAStruct
        }

        let members = structDecl.memberBlock.members
        let hasContent = members.contains(where: { isContentProperty($0) })

        guard hasContent else { return [] }

        let storedProperties = members.compactMap { extractStoredProperty($0) }
        let nonContentProperties = storedProperties.filter { $0.name != "content" }

        var parameters: [String] = []
        var assignments: [String] = []

        for property in nonContentProperties {
            if let defaultValue = property.defaultValue {
                parameters.append("\(property.name): \(property.type) = \(defaultValue)")
            } else if property.isOptional {
                parameters.append("\(property.name): \(property.type) = nil")
            } else {
                parameters.append("\(property.name): \(property.type)")
            }
            assignments.append("self.\(property.name) = \(property.name)")
        }

        parameters.append("@NodeBuilder content: () -> some Node")
        assignments.append("self.content = Content(content())")

        let paramString = parameters.joined(separator: ", ")
        let bodyString = assignments.joined(separator: "\n        ")

        let initDecl: DeclSyntax = """
            init(\(raw: paramString)) {
                \(raw: bodyString)
            }
            """
        return [initDecl]
    }

    // MARK: - ExtensionMacro

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) else {
            throw ComponentMacroError.notAStruct
        }

        let alreadyConforms = protocols.isEmpty

        if alreadyConforms {
            return []
        }

        let extensionDecl: DeclSyntax = """
            extension \(type.trimmed): Component {}
            """

        guard let ext = extensionDecl.as(ExtensionDeclSyntax.self) else {
            return []
        }

        return [ext]
    }

    // MARK: - Helpers

    private static func isContentProperty(_ member: MemberBlockItemSyntax) -> Bool {
        guard let variable = member.decl.as(VariableDeclSyntax.self) else { return false }
        for binding in variable.bindings {
            guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                let typeAnnotation = binding.typeAnnotation
            else { continue }
            if pattern.identifier.text == "content"
                && typeAnnotation.type.trimmedDescription == "Content"
                && binding.accessorBlock == nil
            {
                return true
            }
        }
        return false
    }

    private static func extractStoredProperty(_ member: MemberBlockItemSyntax) -> StoredProperty? {
        guard let variable = member.decl.as(VariableDeclSyntax.self) else { return nil }

        for binding in variable.bindings {
            if binding.accessorBlock != nil { continue }

            guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                let typeAnnotation = binding.typeAnnotation
            else { continue }

            let name = pattern.identifier.text
            let type = typeAnnotation.type.trimmedDescription
            let defaultValue = binding.initializer?.value.trimmedDescription
            let isOptional =
                typeAnnotation.type.is(OptionalTypeSyntax.self)
                || typeAnnotation.type.is(ImplicitlyUnwrappedOptionalTypeSyntax.self)

            return StoredProperty(
                name: name,
                type: type,
                defaultValue: defaultValue,
                isOptional: isOptional
            )
        }

        return nil
    }

    private struct StoredProperty {
        let name: String
        let type: String
        let defaultValue: String?
        let isOptional: Bool
    }
}

enum ComponentMacroError: Error, CustomStringConvertible {
    case notAStruct

    var description: String {
        switch self {
        case .notAStruct:
            return "@Component can only be applied to structs"
        }
    }
}
