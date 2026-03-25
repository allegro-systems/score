import ScoreCSS
import ScoreCore
import ScoreHTML
import ScoreRuntime

/// The display format for a ``DateTime`` node.
///
/// Controls how the date and/or time is presented both in the server-rendered
/// fallback text and in the client-side Temporal API formatting.
public enum DateTimeFormat: Sendable, Hashable {
    /// Displays only the date (e.g. "March 16, 2026").
    case date

    /// Displays only the time (e.g. "2:30 PM").
    case time

    /// Displays both date and time (e.g. "March 16, 2026, 2:30 PM").
    case dateTime

    /// Displays a relative time description (e.g. "3 hours ago", "in 2 days").
    ///
    /// Falls back to the full date when the Temporal API is not available.
    case relative

    /// A custom format using Temporal API options.
    ///
    /// The dictionary keys map to `Intl.DateTimeFormat` options such as
    /// `"year"`, `"month"`, `"day"`, `"hour"`, `"minute"`, `"weekday"`, etc.
    ///
    /// ```swift
    /// DateTime(date, format: .custom([
    ///     "weekday": "short",
    ///     "month": "short",
    ///     "day": "numeric",
    /// ]))
    /// ```
    case custom([String: String])
}

/// A node that renders a `<time>` element with Temporal API–powered
/// client-side formatting.
///
/// `DateTime` provides a progressive enhancement approach to date/time
/// display. The server renders a human-readable fallback string in the
/// `<time>` element, and a small inline script upgrades it on the client
/// using the TC39 Temporal API for locale-aware, timezone-correct formatting.
///
/// The `datetime` HTML attribute always contains the ISO 8601 representation,
/// ensuring machine readability regardless of the displayed format.
///
/// ### Example — basic date
///
/// ```swift
/// DateTime(year: 2026, month: 3, day: 16)
/// ```
///
/// ### Example — full date-time with timezone
///
/// ```swift
/// DateTime(
///     year: 2026, month: 3, day: 16,
///     hour: 14, minute: 30,
///     timeZone: "America/New_York",
///     format: .dateTime
/// )
/// ```
///
/// ### Example — relative time
///
/// ```swift
/// DateTime(year: 2026, month: 3, day: 14, format: .relative)
/// // Renders "2 days ago" on the client
/// ```
public struct DateTime: Node, SourceLocatable {

    /// The year component.
    public let year: Int

    /// The month component (1–12).
    public let month: Int

    /// The day component (1–31).
    public let day: Int

    /// The hour component (0–23). `nil` for date-only values.
    public let hour: Int?

    /// The minute component (0–59). `nil` for date-only values.
    public let minute: Int?

    /// The second component (0–59). `nil` when not specified.
    public let second: Int?

    /// The IANA timezone identifier (e.g. `"America/New_York"`, `"UTC"`).
    ///
    /// When `nil`, the client-side script uses the browser's local timezone.
    public let timeZone: String?

    /// The display format for the rendered output.
    public let format: DateTimeFormat

    public let sourceLocation: SourceLocation

    /// Creates a date-time node.
    ///
    /// - Parameters:
    ///   - year: The year.
    ///   - month: The month (1–12).
    ///   - day: The day of month (1–31).
    ///   - hour: The hour (0–23). Defaults to `nil`.
    ///   - minute: The minute (0–59). Defaults to `nil`.
    ///   - second: The second (0–59). Defaults to `nil`.
    ///   - timeZone: An IANA timezone identifier. Defaults to `nil`.
    ///   - format: The display format. Defaults to `.date`.
    ///   - file: The source file (supplied automatically by the compiler).
    ///   - filePath: The full source path (supplied automatically by the compiler).
    ///   - line: The source line (supplied automatically by the compiler).
    ///   - column: The source column (supplied automatically by the compiler).
    public init(
        year: Int,
        month: Int,
        day: Int,
        hour: Int? = nil,
        minute: Int? = nil,
        second: Int? = nil,
        timeZone: String? = nil,
        format: DateTimeFormat = .date,
        file: String = #fileID,
        filePath: String = #filePath,
        line: Int = #line,
        column: Int = #column
    ) {
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
        self.minute = minute
        self.second = second
        self.timeZone = timeZone
        self.format = format
        self.sourceLocation = SourceLocation(
            fileID: file, filePath: filePath, line: line, column: column
        )
    }

    public var body: Never { fatalError() }

    // MARK: - Internal Helpers

    /// The ISO 8601 string for the `datetime` attribute.
    var isoValue: String {
        let datePart = String(format: "%04d-%02d-%02d", year, month, day)
        guard let h = hour, let m = minute else {
            return datePart
        }
        let s = second ?? 0
        let timePart = String(format: "%02d:%02d:%02d", h, m, s)
        if let tz = timeZone, tz == "UTC" {
            return "\(datePart)T\(timePart)Z"
        }
        return "\(datePart)T\(timePart)"
    }

    /// The server-rendered fallback display text.
    var fallbackText: String {
        let monthNames = [
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December",
        ]
        let monthName = (1...12).contains(month) ? monthNames[month - 1] : "Unknown"

        switch format {
        case .date, .relative:
            return "\(monthName) \(day), \(year)"
        case .time:
            let h = hour ?? 0
            let m = minute ?? 0
            let period = h >= 12 ? "PM" : "AM"
            let displayHour = h == 0 ? 12 : (h > 12 ? h - 12 : h)
            return String(format: "%d:%02d %@", displayHour, m, period)
        case .dateTime:
            let h = hour ?? 0
            let m = minute ?? 0
            let period = h >= 12 ? "PM" : "AM"
            let displayHour = h == 0 ? 12 : (h > 12 ? h - 12 : h)
            return "\(monthName) \(day), \(year), \(String(format: "%d:%02d %@", displayHour, m, period))"
        case .custom:
            return "\(monthName) \(day), \(year)"
        }
    }

    /// The inline JavaScript that upgrades the `<time>` element using the
    /// Temporal API.
    var clientScript: String {
        let isoStr = isoValue
        let tzArg: String
        if let tz = timeZone {
            tzArg = "\"\(tz)\""
        } else {
            tzArg = "Temporal.Now.timeZoneId()"
        }

        switch format {
        case .date:
            return """
                (function(){try{var e=document.currentScript.previousElementSibling;\
                var d=Temporal.PlainDate.from(\"\(isoStr)\");\
                var fmt=new Intl.DateTimeFormat(undefined,{year:\"numeric\",month:\"long\",day:\"numeric\"});\
                e.textContent=fmt.format(d)}catch(x){}})()
                """
        case .time:
            return """
                (function(){try{var e=document.currentScript.previousElementSibling;\
                var t=Temporal.PlainTime.from(\"\(isoStr)\");\
                var fmt=new Intl.DateTimeFormat(undefined,{hour:\"numeric\",minute:\"2-digit\"});\
                e.textContent=fmt.format(t)}catch(x){}})()
                """
        case .dateTime:
            return """
                (function(){try{var e=document.currentScript.previousElementSibling;\
                var tz=\(tzArg);\
                var zdt=Temporal.PlainDateTime.from(\"\(isoStr)\").toZonedDateTime(tz);\
                var fmt=new Intl.DateTimeFormat(undefined,{year:\"numeric\",month:\"long\",day:\"numeric\",hour:\"numeric\",minute:\"2-digit\",timeZoneName:\"short\",timeZone:tz});\
                e.textContent=fmt.format(zdt.toInstant())}catch(x){}})()
                """
        case .relative:
            return """
                (function(){try{var e=document.currentScript.previousElementSibling;\
                var d=Temporal.PlainDate.from(\"\(isoStr)\");\
                var now=Temporal.Now.plainDateISO();\
                var dur=now.until(d,{largestUnit:\"day\"});\
                var days=dur.days;\
                var rtf=new Intl.RelativeTimeFormat(undefined,{numeric:\"auto\"});\
                if(Math.abs(days)<1){e.textContent=rtf.format(0,\"day\")}\
                else if(Math.abs(days)<7){e.textContent=rtf.format(days,\"day\")}\
                else if(Math.abs(days)<30){e.textContent=rtf.format(Math.trunc(days/7),\"week\")}\
                else if(Math.abs(days)<365){e.textContent=rtf.format(Math.trunc(days/30),\"month\")}\
                else{e.textContent=rtf.format(Math.trunc(days/365),\"year\")}}catch(x){}})()
                """
        case .custom(let options):
            let optionPairs = options.sorted(by: { $0.key < $1.key })
                .map { "\($0.key):\"\($0.value)\"" }
                .joined(separator: ",")
            return """
                (function(){try{var e=document.currentScript.previousElementSibling;\
                var d=Temporal.PlainDate.from(\"\(isoStr)\");\
                var fmt=new Intl.DateTimeFormat(undefined,{\(optionPairs)});\
                e.textContent=fmt.format(d)}catch(x){}})()
                """
        }
    }
}

// MARK: - HTML Rendering

extension DateTime: HTMLRenderable {
    package func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        renderHTML(merging: [], into: &output, renderer: renderer)
    }
}

extension DateTime: HTMLAttributeInjectable {
    package func renderHTML(
        merging extraAttributes: [(String, String)],
        into output: inout String,
        renderer: HTMLRenderer
    ) {
        var attrs: [(String, String)] = [
            ("datetime", isoValue),
            ("data-score-dt", ""),
        ]
        for (name, value) in extraAttributes {
            if name == "class", let index = attrs.firstIndex(where: { $0.0 == "class" }) {
                attrs[index].1 += " \(value)"
            } else {
                attrs.append((name, value))
            }
        }
        if renderer.isDevMode {
            attrs.append(("data-source", "\(sourceLocation.fileID):\(sourceLocation.line):\(sourceLocation.column)"))
            attrs.append(("data-source-path", "\(sourceLocation.filePath):\(sourceLocation.line):\(sourceLocation.column)"))
        }

        output.append("<time")
        for (name, value) in attrs {
            output.append(" \(name)=\"\(value)\"")
        }
        output.append(">\(fallbackText)</time>")
        output.append("<script>\(clientScript)</script>")
    }
}

// MARK: - CSS Walking

extension DateTime: CSSWalkable {
    package var htmlTag: String? { "time" }

    package func walkChildren(collector: inout CSSCollector) {
        // No children to walk.
    }
}
