import Foundation

/// A protocol describing a single validation rule that can be applied to a value.
///
/// Conforming types define a `validate` method that returns a ``ValidationResult``
/// indicating whether the value passes the rule.
///
/// ### Example
///
/// ```swift
/// struct MinLength: ValidationRule {
///     let minimum: Int
///     func validate(_ value: String) -> ValidationResult {
///         value.count >= minimum ? .valid : .invalid("Must be at least \(minimum) characters")
///     }
///     var clientScript: String? { "v => v.length >= \(minimum)" }
/// }
/// ```
public protocol ValidationRule: Sendable {

    /// The type of value this rule validates.
    associatedtype Value: Sendable

    /// Validates the given value against this rule.
    ///
    /// - Parameter value: The value to validate.
    /// - Returns: A result indicating whether the value passed validation.
    func validate(_ value: Value) -> ValidationResult

    /// An optional JavaScript expression for client-side validation.
    ///
    /// When non-nil, this is emitted as a data attribute on the associated
    /// form element so the Score runtime can enforce it in the browser.
    /// The expression should be an arrow function: `v => boolean`.
    var clientScript: String? { get }

    /// A human-readable description of this rule for error messages.
    var errorMessage: String { get }
}

extension ValidationRule {
    public var clientScript: String? { nil }
}

/// The result of applying a ``ValidationRule`` to a value.
public enum ValidationResult: Sendable, Equatable {

    /// The value passed validation.
    case valid

    /// The value failed validation with the given message.
    case invalid(String)

    /// Whether the value passed validation.
    public var isValid: Bool {
        if case .valid = self { return true }
        return false
    }

    /// The error message, or `nil` if the result is valid.
    public var errorMessage: String? {
        switch self {
        case .valid: return nil
        case .invalid(let message): return message
        }
    }
}

/// A collection of validation errors keyed by field name.
///
/// Use `ValidationErrors` to accumulate and inspect errors from
/// validating multiple fields on a form or request body.
public struct ValidationErrors: Sendable, Equatable {

    private var errors: [String: [String]]

    /// Creates an empty collection of validation errors.
    public init() {
        self.errors = [:]
    }

    /// Adds an error message for the given field.
    ///
    /// - Parameters:
    ///   - field: The field name.
    ///   - message: The error message.
    public mutating func add(field: String, message: String) {
        errors[field, default: []].append(message)
    }

    /// Returns all error messages for the given field.
    ///
    /// - Parameter field: The field name.
    /// - Returns: An array of error messages, empty if the field has no errors.
    public func messages(for field: String) -> [String] {
        errors[field] ?? []
    }

    /// Whether there are any validation errors.
    public var hasErrors: Bool {
        !errors.isEmpty
    }

    /// All field names that have errors.
    public var fieldNames: [String] {
        Array(errors.keys).sorted()
    }

    /// The total number of individual error messages across all fields.
    public var count: Int {
        errors.values.reduce(0) { $0 + $1.count }
    }
}

/// A type-safe property wrapper that attaches validation rules to a value.
///
/// `Validated` wraps a value and a set of rules. Call ``validate()`` to
/// check all rules and collect any failures.
///
/// ### Example
///
/// ```swift
/// @Validated(rules: [Required(), MinLength(minimum: 3)])
/// var username: String = ""
/// let errors = _username.validate()
/// ```
@propertyWrapper
public struct Validated<Value: Sendable>: Sendable {

    /// The underlying value being validated.
    public var wrappedValue: Value

    /// The validation rules applied to this value.
    public let rules: [any StringValidating]

    /// The field name used in error reporting.
    public let fieldName: String

    /// The projected value provides access to the `Validated` wrapper itself.
    public var projectedValue: Validated<Value> {
        get { self }
        set { self = newValue }
    }

    /// Creates a validated property.
    ///
    /// - Parameters:
    ///   - wrappedValue: The initial value.
    ///   - fieldName: The field name for error reporting.
    ///   - rules: The validation rules to apply.
    public init(
        wrappedValue: Value,
        fieldName: String = "",
        rules: [any StringValidating]
    ) {
        self.wrappedValue = wrappedValue
        self.fieldName = fieldName
        self.rules = rules
    }

    /// Runs all validation rules against the current value.
    ///
    /// - Returns: An array of ``ValidationResult`` values, one per rule.
    public func validate() -> [ValidationResult] where Value == String {
        rules.map { $0.validate(wrappedValue) }
    }

    /// Runs all validation rules and collects errors into a ``ValidationErrors`` collection.
    ///
    /// - Returns: A `ValidationErrors` with any failures keyed by ``fieldName``.
    public func validateWithErrors() -> ValidationErrors where Value == String {
        var validationErrors = ValidationErrors()
        for rule in rules {
            let result = rule.validate(wrappedValue)
            if case .invalid(let message) = result {
                validationErrors.add(field: fieldName, message: message)
            }
        }
        return validationErrors
    }
}

/// Type-erased protocol for string validation rules.
///
/// This protocol enables heterogeneous collections of validation rules
/// by erasing the associated type to `String`.
public protocol StringValidating: Sendable {

    /// Validates a string value.
    func validate(_ value: String) -> ValidationResult

    /// Optional client-side JavaScript expression.
    var clientScript: String? { get }

    /// The error message for this rule.
    var errorMessage: String { get }
}

/// Validates that a string is not empty.
public struct Required: ValidationRule, StringValidating {

    public let errorMessage: String

    /// Creates a required validation rule.
    ///
    /// - Parameter message: The error message. Defaults to "This field is required".
    public init(message: String = "This field is required") {
        self.errorMessage = message
    }

    public func validate(_ value: String) -> ValidationResult {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? .invalid(errorMessage)
            : .valid
    }

    public var clientScript: String? {
        "v => v.trim().length > 0"
    }
}

/// Validates that a string meets a minimum length.
public struct MinLength: ValidationRule, StringValidating {

    /// The minimum number of characters required.
    public let minimum: Int
    public let errorMessage: String

    /// Creates a minimum length validation rule.
    ///
    /// - Parameters:
    ///   - minimum: The minimum character count.
    ///   - message: The error message. Defaults to a description of the minimum.
    public init(_ minimum: Int, message: String? = nil) {
        self.minimum = minimum
        self.errorMessage = message ?? "Must be at least \(minimum) characters"
    }

    public func validate(_ value: String) -> ValidationResult {
        value.count >= minimum ? .valid : .invalid(errorMessage)
    }

    public var clientScript: String? {
        "v => v.length >= \(minimum)"
    }
}

/// Validates that a string does not exceed a maximum length.
public struct MaxLength: ValidationRule, StringValidating {

    /// The maximum number of characters allowed.
    public let maximum: Int
    public let errorMessage: String

    /// Creates a maximum length validation rule.
    ///
    /// - Parameters:
    ///   - maximum: The maximum character count.
    ///   - message: The error message.
    public init(_ maximum: Int, message: String? = nil) {
        self.maximum = maximum
        self.errorMessage = message ?? "Must be at most \(maximum) characters"
    }

    public func validate(_ value: String) -> ValidationResult {
        value.count <= maximum ? .valid : .invalid(errorMessage)
    }

    public var clientScript: String? {
        "v => v.length <= \(maximum)"
    }
}

/// Validates that a string matches a regular expression pattern.
public struct PatternRule: ValidationRule, StringValidating {

    /// The regular expression pattern to match.
    public let pattern: String
    public let errorMessage: String

    /// Creates a pattern validation rule.
    ///
    /// - Parameters:
    ///   - pattern: A regular expression pattern the value must match.
    ///   - message: The error message.
    public init(_ pattern: String, message: String = "Invalid format") {
        self.pattern = pattern
        self.errorMessage = message
    }

    public func validate(_ value: String) -> ValidationResult {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return .invalid("Invalid regex pattern")
        }
        let range = NSRange(value.startIndex..., in: value)
        return regex.firstMatch(in: value, range: range) != nil ? .valid : .invalid(errorMessage)
    }

    public var clientScript: String? {
        "v => /\(pattern)/.test(v)"
    }
}

/// Validates that a string is a well-formed email address.
public struct EmailRule: ValidationRule, StringValidating {

    public let errorMessage: String

    /// Creates an email validation rule.
    ///
    /// - Parameter message: The error message.
    public init(message: String = "Invalid email address") {
        self.errorMessage = message
    }

    public func validate(_ value: String) -> ValidationResult {
        let pattern = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return .invalid(errorMessage)
        }
        let range = NSRange(value.startIndex..., in: value)
        return regex.firstMatch(in: value, range: range) != nil ? .valid : .invalid(errorMessage)
    }

    public var clientScript: String? {
        "v => /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$/.test(v)"
    }
}

/// Validates a form-like collection of fields against their rules.
///
/// `FormValidator` takes a dictionary of field names to values and
/// a dictionary of field names to rules, then validates all of them.
public struct FormValidator: Sendable {

    private init() {}

    /// Validates all fields against their respective rules.
    ///
    /// - Parameters:
    ///   - fields: A dictionary of field names to string values.
    ///   - rules: A dictionary of field names to arrays of validation rules.
    /// - Returns: A ``ValidationErrors`` containing any failures.
    public static func validate(
        fields: [String: String],
        rules: [String: [any StringValidating]]
    ) -> ValidationErrors {
        var errors = ValidationErrors()
        for (fieldName, fieldRules) in rules {
            let value = fields[fieldName] ?? ""
            for rule in fieldRules {
                let result = rule.validate(value)
                if case .invalid(let message) = result {
                    errors.add(field: fieldName, message: message)
                }
            }
        }
        return errors
    }

    /// Emits data attributes for client-side validation as an HTML attribute string.
    ///
    /// - Parameters:
    ///   - fieldName: The field name.
    ///   - rules: The validation rules for the field.
    /// - Returns: An HTML attribute string containing `data-validate-*` attributes.
    public static func clientAttributes(
        fieldName: String,
        rules: [any StringValidating]
    ) -> String {
        var attributes: [String] = []
        for (index, rule) in rules.enumerated() {
            if let script = rule.clientScript {
                attributes.append("data-validate-\(index)=\"\(script)\"")
            }
            attributes.append("data-validate-msg-\(index)=\"\(rule.errorMessage)\"")
        }
        return attributes.joined(separator: " ")
    }
}
