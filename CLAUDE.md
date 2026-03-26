# Score Framework

Score is a **server-rendered Swift web framework** with a reactive signal system for client-side interactivity. It follows a **zero-JS-by-default** philosophy — all styling is done through Swift modifiers that emit CSS, and interactivity uses `@State`/`@Action` macros that emit minimal JavaScript signals.

## Architecture

- **ScoreUI** — HTML elements, modifiers, components, theming
- **ScoreRuntime** — HTTP server, request handling, middleware, page rendering
- **ScoreCLI** — `score dev`, `score build`, `score init` commands
- **ScoreMacros** — `@Component`, `@State`, `@Action`, `@Computed` macro implementations
- **ScoreAssets** — Asset pipeline, optimization, compression
- **ScoreData** — Key-value store abstraction
- **ScoreTesting** — Test renderer for component snapshot testing

## Modifier Naming Convention

Every Score modifier follows a **one modifier per CSS concept** rule:

```swift
.flex(.row, gap: 12)           // flex container
.flex(grow: 1)                 // flex item (same name, different params)
.grid(columns: 3, gap: 16)    // grid container
.grid(column: .span(2))       // grid item
.font(.sans, size: 14)        // all typography in one modifier
.border(width: 1, color: .border, style: .solid)
.size(width: 200, height: 100)
.position(.absolute, top: 0)
.overflow(vertical: .auto)     // use horizontal/vertical, never x/y
.radius(8)
```

**Rules:**
- **One modifier per concept** — never create `.flexItem()`, `.gridPlacement()`, `.fontSize()`, etc.
- **Use `horizontal`/`vertical`** — never `x`/`y` for axis parameters.
- **New CSS properties** go into the appropriate existing modifier.

## Never Use htmlAttribute for Styles or Events

`htmlAttribute("style", ...)` and `htmlAttribute("onclick", ...)` are **forbidden**. If a CSS property has no Score modifier yet, **add it to the framework** in the appropriate modifier. `htmlAttribute` is only acceptable for non-style HTML attributes (`id`, `title`, `aria-*`, `data-*`).

## Component Naming

All Score components must be `UpperCamelCase` and defined as `@Component struct`. Never create lowercase helper functions that return `some Node`.

## Development

```bash
swift build          # Build the framework
swift test           # Run tests
swift run score dev  # Run dev server (for example apps)
```

## Tooling

- Swift 6.3, `swift format` with shared `.swift-format` config
- `hk.pkl` pre-commit hooks: format, build, test
- `mise.toml` for task definitions
- Commit messages: `feat:`, `fix:`, `refactor:`, `chore:`, `test:`
