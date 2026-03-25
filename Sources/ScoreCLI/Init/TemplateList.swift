enum Template: String, CaseIterable, Sendable, Equatable, CustomStringConvertible {
    case minimal
    case `static`
    case calculator
    case blog
    case marketing
    case docs
    case saas
    case social
    case localised
    case plugin

    var description: String {
        "\(rawValue) — \(summary)"
    }

    var summary: String {
        switch self {
        case .minimal: "1 page, 1 component, 1 API controller — blank canvas"
        case .static: "Pure HTML/CSS, no JS, no data — the floor"
        case .calculator: "Mortgage calculator — multi-state derived UI, zero backend"
        case .blog: "Content + routes + feeds + SEO metadata"
        case .marketing: "Landing pages, forms, progressive enhancement + ScoreAnalyticsVendor"
        case .docs: "Documentation site — navigation, search, code blocks, 4 themes"
        case .saas: "Auth, CRUD, durability defaults + Stripe integration"
        case .social: "Local-first data, sync, conflict resolution, feeds"
        case .localised: "5 locales (en, es, it, de, ru), locale picker, localised formatting"
        case .plugin: "Score plugin — library target, tests, mise CI, ready for publishing"
        }
    }

    var directoryName: String { rawValue }

    /// Whether this template produces a plugin (library) rather than an app (executable).
    var isPlugin: Bool { self == .plugin }
}
