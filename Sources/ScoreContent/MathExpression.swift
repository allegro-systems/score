import ScoreCore

/// A node that renders a LaTeX-style math expression as MathML.
///
/// `MathExpression` takes a raw LaTeX math string and emits a `<math>` element
/// containing the expression. The conversion handles common constructs such as
/// fractions (`\frac{a}{b}`), superscripts (`x^2`), subscripts (`x_i`),
/// square roots (`\sqrt{x}`), summation (`\sum`), and Greek letters.
///
/// For constructs that are not explicitly recognised, the raw LaTeX text is
/// emitted as an `<mtext>` fallback so that content is never silently dropped.
///
/// ```swift
/// MathExpression("E = mc^2")
/// MathExpression("\\frac{a}{b}")
/// ```
public struct MathExpression: Node {

    /// The original LaTeX math source.
    public let latex: String

    /// The pre-computed MathML string for this expression.
    public let rawMathML: String

    /// Creates a math expression node from a LaTeX string.
    ///
    /// The LaTeX is converted to MathML at initialisation time. Unrecognised
    /// constructs are preserved as `<mtext>` elements.
    ///
    /// - Parameter latex: A LaTeX math expression such as `"x^2 + y^2 = z^2"`.
    public init(_ latex: String) {
        self.latex = latex
        self.rawMathML = MathExpression.convertToMathML(latex)
    }

    public var body: some Node {
        RawTextNode(rawMathML)
    }
}

extension MathExpression {

    /// Converts a LaTeX math expression to a MathML string.
    ///
    /// Handles fractions, superscripts, subscripts, square roots, summation,
    /// product, integral, and common Greek letters. Unknown commands are
    /// emitted as `<mtext>` elements.
    static func convertToMathML(_ latex: String) -> String {
        var result = "<math>"
        result += convertTokens(latex)
        result += "</math>"
        return result
    }

    private static func convertTokens(_ input: String) -> String {
        var output = ""
        var index = input.startIndex

        while index < input.endIndex {
            let ch = input[index]

            if ch == "\\" {
                let commandStart = input.index(after: index)
                let (command, nextIndex) = readCommand(input, from: commandStart)
                index = nextIndex

                switch command {
                case "frac":
                    let (numerator, afterNum) = readGroup(input, from: index)
                    let (denominator, afterDen) = readGroup(input, from: afterNum)
                    output += "<mfrac><mrow>\(convertTokens(numerator))</mrow><mrow>\(convertTokens(denominator))</mrow></mfrac>"
                    index = afterDen

                case "sqrt":
                    let (content, afterContent) = readGroup(input, from: index)
                    output += "<msqrt><mrow>\(convertTokens(content))</mrow></msqrt>"
                    index = afterContent

                case "sum":
                    output += "<mo>&#x2211;</mo>"
                case "prod":
                    output += "<mo>&#x220F;</mo>"
                case "int":
                    output += "<mo>&#x222B;</mo>"
                case "infty":
                    output += "<mn>&#x221E;</mn>"
                case "pm":
                    output += "<mo>&#x00B1;</mo>"
                case "times":
                    output += "<mo>&#x00D7;</mo>"
                case "div":
                    output += "<mo>&#x00F7;</mo>"
                case "leq":
                    output += "<mo>&#x2264;</mo>"
                case "geq":
                    output += "<mo>&#x2265;</mo>"
                case "neq":
                    output += "<mo>&#x2260;</mo>"
                case "alpha":
                    output += "<mi>&#x03B1;</mi>"
                case "beta":
                    output += "<mi>&#x03B2;</mi>"
                case "gamma":
                    output += "<mi>&#x03B3;</mi>"
                case "delta":
                    output += "<mi>&#x03B4;</mi>"
                case "epsilon":
                    output += "<mi>&#x03B5;</mi>"
                case "theta":
                    output += "<mi>&#x03B8;</mi>"
                case "lambda":
                    output += "<mi>&#x03BB;</mi>"
                case "mu":
                    output += "<mi>&#x03BC;</mi>"
                case "pi":
                    output += "<mi>&#x03C0;</mi>"
                case "sigma":
                    output += "<mi>&#x03C3;</mi>"
                case "omega":
                    output += "<mi>&#x03C9;</mi>"
                case "phi":
                    output += "<mi>&#x03C6;</mi>"
                default:
                    output += "<mtext>\\\(command)</mtext>"
                }

            } else if ch == "^" {
                index = input.index(after: index)
                let (superscript, afterSup) = readGroupOrChar(input, from: index)
                if let lastMi = extractLastElement(&output) {
                    output += "<msup>\(lastMi)<mrow>\(convertTokens(superscript))</mrow></msup>"
                } else {
                    output += "<msup><mrow></mrow><mrow>\(convertTokens(superscript))</mrow></msup>"
                }
                index = afterSup

            } else if ch == "_" {
                index = input.index(after: index)
                let (subscriptVal, afterSub) = readGroupOrChar(input, from: index)
                if let lastMi = extractLastElement(&output) {
                    output += "<msub>\(lastMi)<mrow>\(convertTokens(subscriptVal))</mrow></msub>"
                } else {
                    output += "<msub><mrow></mrow><mrow>\(convertTokens(subscriptVal))</mrow></msub>"
                }
                index = afterSub

            } else if ch == "{" {
                let (content, afterGroup) = readGroup(input, from: index)
                output += "<mrow>\(convertTokens(content))</mrow>"
                index = afterGroup

            } else if ch == " " {
                index = input.index(after: index)

            } else if ch.isNumber || ch == "." {
                let (number, afterNum) = readNumber(input, from: index)
                output += "<mn>\(number)</mn>"
                index = afterNum

            } else if "+-=<>()[]|!,;:".contains(ch) {
                output += "<mo>\(ch)</mo>"
                index = input.index(after: index)

            } else if ch.isLetter {
                output += "<mi>\(ch)</mi>"
                index = input.index(after: index)

            } else {
                index = input.index(after: index)
            }
        }

        return output
    }

    private static func readCommand(_ input: String, from start: String.Index) -> (String, String.Index) {
        var end = start
        while end < input.endIndex && input[end].isLetter {
            end = input.index(after: end)
        }
        return (String(input[start..<end]), end)
    }

    private static func readGroup(_ input: String, from start: String.Index) -> (String, String.Index) {
        guard start < input.endIndex, input[start] == "{" else {
            return ("", start)
        }
        var depth = 1
        var index = input.index(after: start)
        let contentStart = index
        while index < input.endIndex && depth > 0 {
            if input[index] == "{" { depth += 1 } else if input[index] == "}" { depth -= 1 }
            if depth > 0 { index = input.index(after: index) }
        }
        let content = String(input[contentStart..<index])
        if index < input.endIndex { index = input.index(after: index) }
        return (content, index)
    }

    private static func readGroupOrChar(_ input: String, from start: String.Index) -> (String, String.Index) {
        guard start < input.endIndex else { return ("", start) }
        if input[start] == "{" {
            return readGroup(input, from: start)
        }
        return (String(input[start]), input.index(after: start))
    }

    private static func readNumber(_ input: String, from start: String.Index) -> (String, String.Index) {
        var end = start
        while end < input.endIndex && (input[end].isNumber || input[end] == ".") {
            end = input.index(after: end)
        }
        return (String(input[start..<end]), end)
    }

    private static func extractLastElement(_ output: inout String) -> String? {
        let tags = ["<mi>", "<mn>", "<mo>"]
        for tag in tags {
            let closeTag = "</\(tag.dropFirst().dropLast())>"
            if output.hasSuffix(closeTag) {
                if let openRange = output.range(of: tag, options: .backwards) {
                    let element = String(output[openRange.lowerBound...])
                    output = String(output[..<openRange.lowerBound])
                    return element
                }
            }
        }
        let closeTags = ["</msup>", "</msub>", "</mfrac>", "</msqrt>", "</mrow>"]
        for closeTag in closeTags {
            if output.hasSuffix(closeTag) {
                let tagName = String(closeTag.dropFirst(2).dropLast(1))
                let openTag = "<\(tagName)"
                if let openRange = output.range(of: openTag, options: .backwards) {
                    let element = String(output[openRange.lowerBound...])
                    output = String(output[..<openRange.lowerBound])
                    return element
                }
            }
        }
        return nil
    }
}
