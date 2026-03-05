import ScoreCore

/// A single locale option within a ``LocalePicker``.
///
/// ### Example
///
/// ```swift
/// LocaleOption(code: "en", label: "English")
/// LocaleOption(code: "fr", label: "Fran\u{00E7}ais")
/// ```
public struct LocaleOption: Sendable {

    /// The locale identifier (e.g. `"en"`, `"fr"`, `"ja"`).
    public let code: String

    /// The human-readable display name for this locale.
    public let label: String

    /// Creates a locale option.
    ///
    /// - Parameters:
    ///   - code: The locale identifier.
    ///   - label: The display name.
    public init(code: String, label: String) {
        self.code = code
        self.label = label
    }
}

/// A drop-down selector for choosing the active locale.
///
/// `LocalePicker` renders a `<select>` element pre-populated with
/// the provided locale options. It is typically placed in a site
/// header or footer to allow users to switch languages.
///
/// ### Example
///
/// ```swift
/// LocalePicker(
///     name: "locale",
///     selected: "en",
///     locales: [
///         LocaleOption(code: "en", label: "English"),
///         LocaleOption(code: "fr", label: "Fran\u{00E7}ais"),
///     ]
/// )
/// ```
public struct LocalePicker: Component {

    /// The form field name.
    public let name: String

    /// The currently selected locale code.
    public let selected: String?

    /// The available locale options.
    public let locales: [LocaleOption]

    /// Creates a locale picker.
    ///
    /// - Parameters:
    ///   - name: The form field name. Defaults to `"locale"`.
    ///   - selected: The currently selected locale code. Defaults to `nil`.
    ///   - locales: The available locale options.
    public init(
        name: String = "locale",
        selected: String? = nil,
        locales: [LocaleOption]
    ) {
        self.name = name
        self.selected = selected
        self.locales = locales
    }

    public var body: some Node {
        Stack {
            Label(for: "locale-picker") {
                Text(verbatim: "Language")
            }
            .htmlAttribute("data-part", "label")
            .font(weight: .medium, color: .text)
            Select(name: name, id: "locale-picker") {
                ForEachNode(locales) { locale in
                    Option(
                        value: locale.code,
                        selected: locale.code == selected
                    ) {
                        Text(verbatim: locale.label)
                    }
                }
            }
            .htmlAttribute("data-part", "select")
        }
        .htmlAttribute("data-component", "locale-picker")
        .accessibility(label: "Language selector")
    }
}
