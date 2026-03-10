/// A colour value in the OKLCH perceptual colour space, used for syntax
/// theme tokens.
///
/// ```swift
/// let blue = ColorValue.oklch(0.62, 0.19, 250)
/// ```
public struct ColorValue: Sendable, Hashable {

    /// Perceptual lightness, from 0 (black) to 1 (white).
    public let lightness: Double

    /// Chroma (colourfulness), from 0 to approximately 0.4.
    public let chroma: Double

    /// Hue angle in degrees, from 0 to 360.
    public let hue: Double

    /// Creates an OKLCH colour value.
    ///
    /// - Parameters:
    ///   - l: Lightness, from 0 (black) to 1 (white).
    ///   - c: Chroma (colourfulness), from 0 to approximately 0.4.
    ///   - h: Hue angle in degrees, from 0 to 360.
    /// - Returns: A colour value in the OKLCH colour space.
    public static func oklch(_ l: Double, _ c: Double, _ h: Double) -> ColorValue {
        ColorValue(lightness: l, chroma: c, hue: h)
    }

    /// The CSS representation of this colour.
    ///
    /// Returns an `oklch()` function call suitable for direct embedding in
    /// CSS stylesheets.
    public var cssValue: String {
        "oklch(\(lightness) \(chroma) \(hue))"
    }
}

/// A mapping of syntax token categories to OKLCH colours for code highlighting.
///
/// `SyntaxTheme` defines the visual presentation of syntax-highlighted code
/// blocks. Each property corresponds to a category of language token, and the
/// associated ``ColorValue`` determines how that category is rendered.
///
/// Score ships with 11 built-in themes accessible as static properties.
///
/// ```swift
/// let theme = SyntaxTheme.rosePine
/// let keywordColour = theme.keyword.cssValue
/// ```
public struct SyntaxTheme: Sendable, Hashable {

    /// The background colour of the code block.
    public var background: ColorValue

    /// The colour used for language keywords (e.g. `if`, `let`, `func`).
    public var keyword: ColorValue

    /// The colour used for string literals.
    public var string: ColorValue

    /// The colour used for comments.
    public var comment: ColorValue

    /// The colour used for numeric literals.
    public var number: ColorValue

    /// The colour used for type names and annotations.
    public var type: ColorValue

    /// The colour used for function and method names.
    public var function: ColorValue

    /// The colour used for operators (e.g. `+`, `=`, `->`, `??`).
    public var operatorColor: ColorValue

    /// The colour used for variable and parameter names.
    public var variable: ColorValue

    /// Creates a syntax theme with explicit colours for every token category.
    ///
    /// - Parameters:
    ///   - background: Background colour of the code block.
    ///   - keyword: Colour for language keywords.
    ///   - string: Colour for string literals.
    ///   - comment: Colour for comments.
    ///   - number: Colour for numeric literals.
    ///   - type: Colour for type names.
    ///   - function: Colour for function names.
    ///   - operatorColor: Colour for operators.
    ///   - variable: Colour for variables and parameters.
    public init(
        background: ColorValue,
        keyword: ColorValue,
        string: ColorValue,
        comment: ColorValue,
        number: ColorValue,
        type: ColorValue,
        function: ColorValue,
        operatorColor: ColorValue,
        variable: ColorValue
    ) {
        self.background = background
        self.keyword = keyword
        self.string = string
        self.comment = comment
        self.number = number
        self.type = type
        self.function = function
        self.operatorColor = operatorColor
        self.variable = variable
    }
}

extension SyntaxTheme {

    /// The default Score syntax theme, matching the Allegro design handbook.
    ///
    /// Uses the OKLCH equivalents of the handbook's Syntax Highlighting
    /// colours for perceptual consistency across all Allegro properties.
    public static let scoreDefault = SyntaxTheme(
        background: .oklch(0.18, 0.01, 92),
        keyword: .oklch(0.65, 0.13, 348),
        string: .oklch(0.76, 0.12, 153),
        comment: .oklch(0.46, 0.02, 80),
        number: .oklch(0.71, 0.08, 58),
        type: .oklch(0.68, 0.08, 246),
        function: .oklch(0.66, 0.05, 84),
        operatorColor: .oklch(0.75, 0.08, 83),
        variable: .oklch(0.81, 0.03, 92)
    )

    /// A warm, minimal dark theme inspired by Vesper.
    public static let vesper = SyntaxTheme(
        background: .oklch(0.18, 0.01, 70),
        keyword: .oklch(0.75, 0.14, 55),
        string: .oklch(0.75, 0.14, 140),
        comment: .oklch(0.50, 0.02, 70),
        number: .oklch(0.75, 0.14, 55),
        type: .oklch(0.78, 0.10, 200),
        function: .oklch(0.82, 0.04, 70),
        operatorColor: .oklch(0.70, 0.04, 70),
        variable: .oklch(0.82, 0.04, 70)
    )

    /// The main Rosé Pine theme with muted rose and gold accents on a dark base.
    public static let rosePine = SyntaxTheme(
        background: .oklch(0.22, 0.02, 290),
        keyword: .oklch(0.68, 0.16, 320),
        string: .oklch(0.72, 0.12, 160),
        comment: .oklch(0.52, 0.06, 290),
        number: .oklch(0.72, 0.12, 70),
        type: .oklch(0.72, 0.12, 200),
        function: .oklch(0.75, 0.10, 50),
        operatorColor: .oklch(0.68, 0.08, 290),
        variable: .oklch(0.80, 0.06, 290)
    )

    /// The Rosé Pine Moon variant with slightly lighter background tones.
    public static let rosePineMoon = SyntaxTheme(
        background: .oklch(0.26, 0.03, 290),
        keyword: .oklch(0.70, 0.16, 320),
        string: .oklch(0.74, 0.12, 160),
        comment: .oklch(0.54, 0.06, 290),
        number: .oklch(0.74, 0.12, 70),
        type: .oklch(0.74, 0.12, 200),
        function: .oklch(0.77, 0.10, 50),
        operatorColor: .oklch(0.70, 0.08, 290),
        variable: .oklch(0.82, 0.06, 290)
    )

    /// The Rosé Pine Dawn variant with a light warm background.
    public static let rosePineDawn = SyntaxTheme(
        background: .oklch(0.95, 0.01, 60),
        keyword: .oklch(0.55, 0.16, 320),
        string: .oklch(0.50, 0.12, 160),
        comment: .oklch(0.62, 0.06, 290),
        number: .oklch(0.50, 0.12, 70),
        type: .oklch(0.50, 0.12, 200),
        function: .oklch(0.52, 0.10, 50),
        operatorColor: .oklch(0.55, 0.08, 290),
        variable: .oklch(0.35, 0.06, 290)
    )

    /// The Catppuccin Latte light theme with pastel accents.
    public static let catppuccinLatte = SyntaxTheme(
        background: .oklch(0.96, 0.01, 240),
        keyword: .oklch(0.55, 0.18, 300),
        string: .oklch(0.55, 0.14, 150),
        comment: .oklch(0.62, 0.04, 240),
        number: .oklch(0.60, 0.16, 40),
        type: .oklch(0.58, 0.14, 210),
        function: .oklch(0.55, 0.14, 250),
        operatorColor: .oklch(0.58, 0.12, 200),
        variable: .oklch(0.40, 0.04, 240)
    )

    /// The Catppuccin Frappe mid-dark theme.
    public static let catppuccinFrappe = SyntaxTheme(
        background: .oklch(0.28, 0.02, 240),
        keyword: .oklch(0.72, 0.16, 300),
        string: .oklch(0.72, 0.12, 150),
        comment: .oklch(0.55, 0.04, 240),
        number: .oklch(0.75, 0.14, 40),
        type: .oklch(0.74, 0.12, 210),
        function: .oklch(0.72, 0.12, 250),
        operatorColor: .oklch(0.74, 0.10, 200),
        variable: .oklch(0.82, 0.04, 240)
    )

    /// The Catppuccin Macchiato theme with warm dark tones.
    public static let catppuccinMacchiato = SyntaxTheme(
        background: .oklch(0.24, 0.02, 240),
        keyword: .oklch(0.74, 0.16, 300),
        string: .oklch(0.74, 0.12, 150),
        comment: .oklch(0.52, 0.04, 240),
        number: .oklch(0.77, 0.14, 40),
        type: .oklch(0.76, 0.12, 210),
        function: .oklch(0.74, 0.12, 250),
        operatorColor: .oklch(0.76, 0.10, 200),
        variable: .oklch(0.84, 0.04, 240)
    )

    /// The Catppuccin Mocha dark theme with deep warm tones.
    public static let catppuccinMocha = SyntaxTheme(
        background: .oklch(0.21, 0.02, 240),
        keyword: .oklch(0.76, 0.16, 300),
        string: .oklch(0.76, 0.12, 150),
        comment: .oklch(0.50, 0.04, 240),
        number: .oklch(0.79, 0.14, 40),
        type: .oklch(0.78, 0.12, 210),
        function: .oklch(0.76, 0.12, 250),
        operatorColor: .oklch(0.78, 0.10, 200),
        variable: .oklch(0.86, 0.04, 240)
    )

    /// The Nord theme with cool arctic blues.
    public static let nord = SyntaxTheme(
        background: .oklch(0.25, 0.03, 230),
        keyword: .oklch(0.68, 0.12, 250),
        string: .oklch(0.72, 0.10, 150),
        comment: .oklch(0.52, 0.04, 220),
        number: .oklch(0.72, 0.12, 310),
        type: .oklch(0.70, 0.08, 190),
        function: .oklch(0.75, 0.10, 210),
        operatorColor: .oklch(0.68, 0.08, 250),
        variable: .oklch(0.82, 0.04, 220)
    )

    /// The Tokyo Night theme with deep blue-purple tones.
    public static let tokyoNight = SyntaxTheme(
        background: .oklch(0.22, 0.03, 260),
        keyword: .oklch(0.68, 0.18, 280),
        string: .oklch(0.72, 0.12, 160),
        comment: .oklch(0.50, 0.04, 240),
        number: .oklch(0.75, 0.14, 60),
        type: .oklch(0.72, 0.12, 200),
        function: .oklch(0.76, 0.14, 250),
        operatorColor: .oklch(0.68, 0.10, 280),
        variable: .oklch(0.82, 0.06, 220)
    )

    /// The GitHub Light theme with a clean white background.
    public static let githubLight = SyntaxTheme(
        background: .oklch(0.99, 0.00, 0),
        keyword: .oklch(0.50, 0.18, 350),
        string: .oklch(0.48, 0.10, 230),
        comment: .oklch(0.58, 0.04, 110),
        number: .oklch(0.48, 0.14, 230),
        type: .oklch(0.50, 0.14, 50),
        function: .oklch(0.48, 0.16, 290),
        operatorColor: .oklch(0.50, 0.12, 350),
        variable: .oklch(0.35, 0.04, 250)
    )
}
