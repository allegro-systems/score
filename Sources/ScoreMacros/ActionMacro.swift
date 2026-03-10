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
/// The macro auto-generates a peer `ActionDescriptor` with JavaScript
/// translated from the Swift function body:
/// ```swift
/// let _action_toggle = ActionDescriptor(
///     name: "toggle",
///     body: "liked.set(!liked.get()); count.set(count.get() + (liked.get() ? 1 : -1))"
/// )
/// ```
///
/// The `JSEmitter` discovers these descriptors via Mirror reflection
/// to emit client-side JavaScript action functions.
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
        let jsBody = SwiftToJSTranslator.translateBody(funcDecl)

        let descriptor: DeclSyntax
        if let jsBody, !jsBody.isEmpty {
            descriptor = """
                let _action_\(raw: name) = ActionDescriptor(name: \(literal: name), body: \(literal: jsBody))
                """
        } else {
            descriptor = """
                let _action_\(raw: name) = ActionDescriptor(name: \(literal: name))
                """
        }

        return [descriptor]
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
///
/// When the function body contains statements that cannot be translated,
/// the translator returns `nil` and the action is emitted with an empty body.
struct SwiftToJSTranslator {

    static func translateBody(_ funcDecl: FunctionDeclSyntax) -> String? {
        guard let body = funcDecl.body else { return nil }
        let statements = body.statements
        guard !statements.isEmpty else { return nil }

        var jsStatements: [String] = []
        for item in statements {
            guard let js = translateStatement(item.item) else { return nil }
            jsStatements.append(js)
        }
        return jsStatements.joined(separator: "; ")
    }

    private static func translateStatement(_ stmt: CodeBlockItemSyntax.Item) -> String? {
        if let exprStmt = stmt.as(ExpressionStmtSyntax.self) {
            return translateMutatingExpression(exprStmt.expression)
        }
        if let expr = Syntax(stmt).as(ExprSyntax.self) {
            return translateMutatingExpression(expr)
        }
        return nil
    }

    private static func translateMutatingExpression(_ expr: ExprSyntax) -> String? {
        if let call = expr.as(FunctionCallExprSyntax.self) {
            return translateFunctionCall(call)
        }
        if let infix = expr.as(InfixOperatorExprSyntax.self) {
            return translateInfix(infix)
        }
        if let seq = expr.as(SequenceExprSyntax.self) {
            return translateSequence(seq)
        }
        return nil
    }

    static func translateValue(_ expr: ExprSyntax) -> String? {
        if let ident = expr.as(DeclReferenceExprSyntax.self) {
            return "\(ident.baseName.text).get()"
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
            if let inner = translateValue(prefix.expression) {
                return "\(prefix.operator.text)\(inner)"
            }
        }

        if let ternary = expr.as(TernaryExprSyntax.self) {
            if let cond = translateValue(ternary.condition),
                let then = translateValue(ternary.thenExpression),
                let els = translateValue(ternary.elseExpression)
            {
                return "(\(cond) ? \(then) : \(els))"
            }
        }

        if let infix = expr.as(InfixOperatorExprSyntax.self) {
            let op = infix.operator.trimmedDescription
            if ["+", "-", "*", "/", "%", "==", "!=", "<", ">", "<=", ">=", "&&", "||"].contains(op) {
                if let lhs = translateValue(infix.leftOperand),
                    let rhs = translateValue(infix.rightOperand)
                {
                    return "\(lhs) \(op) \(rhs)"
                }
            }
        }

        if let paren = expr.as(TupleExprSyntax.self),
            paren.elements.count == 1,
            let element = paren.elements.first,
            let inner = translateValue(element.expression)
        {
            return "(\(inner))"
        }

        if let seq = expr.as(SequenceExprSyntax.self),
            let folded = try? OperatorTable.standardOperators.foldSingle(seq),
            folded.syntaxNodeType != SequenceExprSyntax.self
        {
            return translateValue(folded)
        }

        return nil
    }

    private static func translateFunctionCall(_ call: FunctionCallExprSyntax) -> String? {
        guard let member = call.calledExpression.as(MemberAccessExprSyntax.self),
            let base = member.base,
            let name = base.as(DeclReferenceExprSyntax.self)?.baseName.text
        else { return nil }

        let method = member.declName.baseName.text

        if method == "toggle" && call.arguments.isEmpty {
            return "\(name).set(!\(name).get())"
        }

        return nil
    }

    private static func translateInfix(_ infix: InfixOperatorExprSyntax) -> String? {
        let op = infix.operator.trimmedDescription
        guard let lhs = infix.leftOperand.as(DeclReferenceExprSyntax.self)?.baseName.text else {
            return nil
        }

        if op == "=" {
            if let rhs = translateValue(infix.rightOperand) {
                return "\(lhs).set(\(rhs))"
            }
        }

        if op == "+=" || op == "-=" {
            let jsOp = String(op.dropLast())
            if let rhs = translateValue(infix.rightOperand) {
                return "\(lhs).set(\(lhs).get() \(jsOp) \(rhs))"
            }
        }

        return nil
    }

    private static func translateSequence(_ seq: SequenceExprSyntax) -> String? {
        let elements = Array(seq.elements)
        guard elements.count == 3 else { return nil }

        guard let lhs = elements[0].as(DeclReferenceExprSyntax.self)?.baseName.text,
            let op = elements[1].as(BinaryOperatorExprSyntax.self)?.operator.text
        else { return nil }

        let rhs = ExprSyntax(elements[2])

        if op == "=" {
            if let rhsJS = translateValue(rhs) {
                return "\(lhs).set(\(rhsJS))"
            }
        }

        if op == "+=" || op == "-=" {
            let jsOp = String(op.dropLast())
            if let rhsJS = translateValue(rhs) {
                return "\(lhs).set(\(lhs).get() \(jsOp) \(rhsJS))"
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
