import Score

struct LocaleAwareBanner: Component {
    let locale: String

    var body: some Node {
        Alert(.info) {
            AlertTitle {
                Text { greetingForLocale(locale) }
            }
            AlertDescription {
                Text { "You are viewing this page in \(displayName(for: locale))." }
            }
        }
    }

    private func greetingForLocale(_ locale: String) -> String {
        switch locale {
        case "en": "Welcome"
        case "es": "Bienvenido"
        case "it": "Benvenuto"
        case "de": "Willkommen"
        case "ru": "Добро пожаловать"
        default: "Welcome"
        }
    }

    private func displayName(for locale: String) -> String {
        switch locale {
        case "en": "English"
        case "es": "Español"
        case "it": "Italiano"
        case "de": "Deutsch"
        case "ru": "Русский"
        default: locale
        }
    }
}
