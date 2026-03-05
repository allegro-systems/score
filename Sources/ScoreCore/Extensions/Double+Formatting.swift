extension Double {

    /// Formats as a string, omitting the decimal point for whole numbers.
    ///
    /// Used by both the HTML and CSS rendering modules to produce clean numeric
    /// attribute and property values without spurious `.0` suffixes.
    ///
    /// ```swift
    /// (16.0).cleanValue  // "16"
    /// (1.5).cleanValue   // "1.5"
    /// ```
    public var cleanValue: String {
        guard !isNaN && !isInfinite else { return String(self) }
        guard self == rounded(),
            self >= Double(Int.min),
            self <= Double(Int.max)
        else { return String(self) }
        return String(Int(self))
    }
}
