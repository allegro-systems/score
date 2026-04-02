import SwiftOperators
import SwiftSyntax
import SwiftSyntaxMacros

/// Implementation of the `@Action` attached peer macro.
///
/// Given a function declaration like:
/// ```swift
/// @Action func toggle() {
///     liked.toggle()
///     count += liked ? 1 : -1
/// }
/// ```
///
/// The macro auto-generates a peer `ActionDescriptor` and `ActionRef`:
/// ```swift
/// let _action_toggle = ActionDescriptor(
///     name: "toggle",
///     body: "liked.set(!liked.get()); count.set(count.get() + (liked.get() ? 1 : -1))"
/// )
/// var $toggle: ActionRef { ActionRef("toggle") }
/// ```
///
/// For parameterized actions:
/// ```swift
/// @Action func editItem(id: String, title: String) {
///     edit = ItemEdit(id: id, title: title)
/// }
/// ```
///
/// Generates:
/// ```swift
/// let _action_editItem = ActionDescriptor(
///     name: "editItem",
///     body: "...",
///     parameters: ["id", "title"]
/// )
/// var $editItem: ActionRef { ActionRef("editItem") }
/// ```
public struct ActionMacro: PeerMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
            throw ActionMacroError.notAFunction
        }

        let name = funcDecl.name.text
        let paramNames = funcDecl.signature.parameterClause.parameters.map { $0.firstName.text }
        let jsBody = SwiftToJSTranslator.translateBody(funcDecl, parameterNames: Set(paramNames))

        var peers: [DeclSyntax] = []

        // ActionDescriptor peer
        if let jsBody, !jsBody.isEmpty {
            if paramNames.isEmpty {
                peers.append(
                    """
                    let _action_\(raw: name) = ActionDescriptor(name: \(literal: name), body: \(literal: jsBody))
                    """)
            } else {
                let paramsArray = paramNames.map { "\"\($0)\"" }.joined(separator: ", ")
                peers.append(
                    """
                    let _action_\(raw: name) = ActionDescriptor(name: \(literal: name), body: \(literal: jsBody), parameters: [\(raw: paramsArray)])
                    """)
            }
        } else {
            if paramNames.isEmpty {
                peers.append(
                    """
                    let _action_\(raw: name) = ActionDescriptor(name: \(literal: name))
                    """)
            } else {
                let paramsArray = paramNames.map { "\"\($0)\"" }.joined(separator: ", ")
                peers.append(
                    """
                    let _action_\(raw: name) = ActionDescriptor(name: \(literal: name), parameters: [\(raw: paramsArray)])
                    """)
            }
        }

        // ActionRef peer for $name syntax
        peers.append(
            """
            var $\(raw: name): ActionRef { ActionRef(\(literal: name)) }
            """)

        return peers
    }
}

/// Translates simple Swift function bodies into equivalent JavaScript
/// signal expressions.
///
/// Supported patterns:
/// - `property.toggle()` → `property.set(!property.get())`
/// - `property += value` → `property.set(property.get() + value)`
/// - `property -= value` → `property.set(property.get() - value)`
/// - `property = value` → `property.set(value)`
/// - `property = !property` → `property.set(!property.get())`
/// - `base.method(args)` → `base_method(args)` for known methods
/// - `base.reset()` → `base_reset()`
/// - `["key": value]` → `{key: value}` dictionary literals
///
/// When the function body contains statements that cannot be translated,
/// the translator returns `nil` and the action is emitted with an empty body.
struct SwiftToJSTranslator {

    static func translateBody(_ funcDecl: FunctionDeclSyntax, parameterNames: Set<String> = []) -> String? {
        guard let body = funcDecl.body else { return nil }
        let statements = body.statements
        guard !statements.isEmpty else { return nil }

        var jsStatements: [String] = []
        for item in statements {
            guard let js = translateStatement(item.item, parameterNames: parameterNames) else { return nil }
            jsStatements.append(js)
        }
        return jsStatements.joined(separator: "; ")
    }

    private static func translateStatement(_ stmt: CodeBlockItemSyntax.Item, parameterNames: Set<String> = []) -> String? {
        if let exprStmt = stmt.as(ExpressionStmtSyntax.self) {
            return translateMutatingExpression(exprStmt.expression, parameterNames: parameterNames)
        }
        if let expr = Syntax(stmt).as(ExprSyntax.self) {
            return translateMutatingExpression(expr, parameterNames: parameterNames)
        }
        return nil
    }

    private static func translateMutatingExpression(_ expr: ExprSyntax, parameterNames: Set<String> = []) -> String? {
        if let call = expr.as(FunctionCallExprSyntax.self) {
            return translateFunctionCall(call, parameterNames: parameterNames)
        }
        if let infix = expr.as(InfixOperatorExprSyntax.self) {
            return translateInfix(infix, parameterNames: parameterNames)
        }
        if let seq = expr.as(SequenceExprSyntax.self) {
            return translateSequence(seq, parameterNames: parameterNames)
        }
        return nil
    }

    static func translateValue(_ expr: ExprSyntax, parameterNames: Set<String> = []) -> String? {
        if let ident = expr.as(DeclReferenceExprSyntax.self) {
            let name = ident.baseName.text
            if parameterNames.contains(name) {
                return name
            }
            return "\(name).get()"
        }

        if let bool = expr.as(BooleanLiteralExprSyntax.self) {
            return bool.literal.text
        }

        if let int = expr.as(IntegerLiteralExprSyntax.self) {
            return int.literal.text
        }

        if let float = expr.as(FloatLiteralExprSyntax.self) {
            return float.literal.text
        }

        if let str = expr.as(StringLiteralExprSyntax.self) {
            let content = str.segments.compactMap {
                $0.as(StringSegmentSyntax.self)?.content.text
            }.joined()
            return "\"\(content)\""
        }

        if let prefix = expr.as(PrefixOperatorExprSyntax.self) {
            if let inner = translateValue(prefix.expression, parameterNames: parameterNames) {
                return "\(prefix.operator.text)\(inner)"
            }
        }

        if let ternary = expr.as(TernaryExprSyntax.self) {
            if let cond = translateValue(ternary.condition, parameterNames: parameterNames),
                let then = translateValue(ternary.thenExpression, parameterNames: parameterNames),
                let els = translateValue(ternary.elseExpression, parameterNames: parameterNames)
            {
                return "(\(cond) ? \(then) : \(els))"
            }
        }

        if let infix = expr.as(InfixOperatorExprSyntax.self) {
            let op = infix.operator.trimmedDescription
            if ["+", "-", "*", "/", "%", "==", "!=", "<", ">", "<=", ">=", "&&", "||"].contains(op) {
                if let lhs = translateValue(infix.leftOperand, parameterNames: parameterNames),
                    let rhs = translateValue(infix.rightOperand, parameterNames: parameterNames)
                {
                    return "\(lhs) \(op) \(rhs)"
                }
            }
        }

        if let paren = expr.as(TupleExprSyntax.self),
            paren.elements.count == 1,
            let element = paren.elements.first,
            let inner = translateValue(element.expression, parameterNames: parameterNames)
        {
            return "(\(inner))"
        }

        // Member access: base.field → base_field.get() or base.field for params
        if let member = expr.as(MemberAccessExprSyntax.self),
            let base = member.base,
            let baseName = base.as(DeclReferenceExprSyntax.self)?.baseName.text
        {
            let field = member.declName.baseName.text
            if parameterNames.contains(baseName) {
                return "\(baseName).\(field)"
            }
            return "\(baseName)_\(field).get()"
        }

        // Dictionary literal: ["key": value] → {key: value}
        if let dict = expr.as(DictionaryExprSyntax.self),
            case .elements(let elements) = dict.content
        {
            var pairs: [String] = []
            for element in elements {
                guard let key = element.key.as(StringLiteralExprSyntax.self) else { return nil }
                let keyText = key.segments.compactMap {
                    $0.as(StringSegmentSyntax.self)?.content.text
                }.joined()
                guard let val = translateValue(element.value, parameterNames: parameterNames) else { return nil }
                pairs.append("\(keyText): \(val)")
            }
            return "{\(pairs.joined(separator: ", "))}"
        }

        // Function call as value expression (e.g., within arguments)
        if let call = expr.as(FunctionCallExprSyntax.self),
            let member = call.calledExpression.as(MemberAccessExprSyntax.self),
            let base = member.base,
            let baseName = base.as(DeclReferenceExprSyntax.self)?.baseName.text
        {
            let method = member.declName.baseName.text
            let translatedArgs = call.arguments.compactMap { arg -> String? in
                translateValue(arg.expression, parameterNames: parameterNames)
            }
            guard translatedArgs.count == call.arguments.count else { return nil }
            return "\(baseName)_\(method)(\(translatedArgs.joined(separator: ", ")))"
        }

        if let seq = expr.as(SequenceExprSyntax.self),
            let folded = try? OperatorTable.standardOperators.foldSingle(seq),
            folded.syntaxNodeType != SequenceExprSyntax.self
        {
            return translateValue(folded, parameterNames: parameterNames)
        }

        return nil
    }

    private static func translateFunctionCall(_ call: FunctionCallExprSyntax, parameterNames: Set<String> = []) -> String? {
        guard let member = call.calledExpression.as(MemberAccessExprSyntax.self),
            let base = member.base,
            let baseName = base.as(DeclReferenceExprSyntax.self)?.baseName.text
        else { return nil }

        let method = member.declName.baseName.text

        // property.toggle()
        if method == "toggle" && call.arguments.isEmpty {
            return "\(baseName).set(!\(baseName).get())"
        }

        // Known methods: base.method(args) → base_method(args)
        let knownMethods: Set<String> = ["create", "read", "update", "delete", "fetch", "reset"]
        if knownMethods.contains(method) {
            let translatedArgs = call.arguments.compactMap { arg -> String? in
                translateValue(arg.expression, parameterNames: parameterNames)
            }
            guard translatedArgs.count == call.arguments.count else { return nil }
            return "\(baseName)_\(method)(\(translatedArgs.joined(separator: ", ")))"
        }

        return nil
    }

    private static func translateInfix(_ infix: InfixOperatorExprSyntax, parameterNames: Set<String> = []) -> String? {
        let op = infix.operator.trimmedDescription

        // Simple identifier LHS
        if let lhsName = infix.leftOperand.as(DeclReferenceExprSyntax.self)?.baseName.text {
            if op == "=" {
                if let rhs = translateValue(infix.rightOperand, parameterNames: parameterNames) {
                    return "\(lhsName).set(\(rhs))"
                }
            }

            if op == "+=" || op == "-=" {
                let jsOp = String(op.dropLast())
                if let rhs = translateValue(infix.rightOperand, parameterNames: parameterNames) {
                    return "\(lhsName).set(\(lhsName).get() \(jsOp) \(rhs))"
                }
            }
        }

        // Member access LHS: base.field = value → base_field.set(value)
        if let memberLHS = infix.leftOperand.as(MemberAccessExprSyntax.self),
            let base = memberLHS.base,
            let baseName = base.as(DeclReferenceExprSyntax.self)?.baseName.text
        {
            let field = memberLHS.declName.baseName.text
            if op == "=" {
                if let rhs = translateValue(infix.rightOperand, parameterNames: parameterNames) {
                    return "\(baseName)_\(field).set(\(rhs))"
                }
            }
        }

        return nil
    }

    private static func translateSequence(_ seq: SequenceExprSyntax, parameterNames: Set<String> = []) -> String? {
        let elements = Array(seq.elements)
        guard elements.count == 3 else { return nil }

        let rhs = ExprSyntax(elements[2])

        // Simple identifier LHS
        if let lhs = elements[0].as(DeclReferenceExprSyntax.self)?.baseName.text {

            // Handle assignment via AssignmentExprSyntax (e.g. `x = true`)
            if elements[1].is(AssignmentExprSyntax.self) {
                if let rhsJS = translateValue(rhs, parameterNames: parameterNames) {
                    return "\(lhs).set(\(rhsJS))"
                }
                return nil
            }

            guard let op = elements[1].as(BinaryOperatorExprSyntax.self)?.operator.text
            else { return nil }

            if op == "=" {
                if let rhsJS = translateValue(rhs, parameterNames: parameterNames) {
                    return "\(lhs).set(\(rhsJS))"
                }
            }

            if op == "+=" || op == "-=" {
                let jsOp = String(op.dropLast())
                if let rhsJS = translateValue(rhs, parameterNames: parameterNames) {
                    return "\(lhs).set(\(lhs).get() \(jsOp) \(rhsJS))"
                }
            }
        }

        // Member access LHS: base.field = value
        if let memberLHS = elements[0].as(MemberAccessExprSyntax.self),
            let base = memberLHS.base,
            let baseName = base.as(DeclReferenceExprSyntax.self)?.baseName.text
        {
            let field = memberLHS.declName.baseName.text

            if elements[1].is(AssignmentExprSyntax.self) {
                if let rhsJS = translateValue(rhs, parameterNames: parameterNames) {
                    return "\(baseName)_\(field).set(\(rhsJS))"
                }
                return nil
            }

            guard let op = elements[1].as(BinaryOperatorExprSyntax.self)?.operator.text
            else { return nil }

            if op == "=" {
                if let rhsJS = translateValue(rhs, parameterNames: parameterNames) {
                    return "\(baseName)_\(field).set(\(rhsJS))"
                }
            }
        }

        return nil
    }
}

enum ActionMacroError: Error, CustomStringConvertible {
    case notAFunction

    var description: String {
        switch self {
        case .notAFunction:
            return "@Action can only be applied to functions"
        }
    }
}
