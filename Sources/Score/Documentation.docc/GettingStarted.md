# Getting Started

Set up your first Score project and build a website in Swift.

## Overview

Score is a Swift framework for building websites using a declarative, type-safe DSL. It compiles to static HTML, CSS, and minimal JavaScript — no virtual DOM, no runtime framework, no hydration step.

## Installation

Add Score to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/allegro-systems/score", from: "0.1.0")
]
```

Then add it as a dependency of your executable target:

```swift
.executableTarget(
    name: "MySite",
    dependencies: ["Score"]
)
```

## Your first site

Create an `App.swift` file with your application entry point:

```swift
import Score

@main
struct MySite: Application {
    var theme: (any Theme)? { nil }
    var metadata: (any Metadata)? { nil }

    @PageBuilder
    var pages: [any Page] {
        HomePage()
    }

    var errorPage: (any ErrorPage.Type)? { nil }
}
```

Then define your first page:

```swift
import Score

struct HomePage: Page {
    static let path = "/"

    var body: some Node {
        Section {
            Heading(.one) { "Hello, Score" }
            Paragraph { "Your first page." }
        }
        .padding(40, at: .vertical)
    }
}
```

## Build and preview

Use the Score CLI to build and preview your site:

```
swift run score build    # Build for production → .score/
swift run score dev      # Start dev server with hot reload
```

The build command compiles your Swift code and emits static HTML, CSS, and JavaScript to the `.score` directory. The dev command watches for file changes and rebuilds automatically.

## Project structure

A typical Score project looks like this:

```
MySite/
├── Package.swift
├── Sources/
│   ├── App.swift
│   ├── Pages/
│   │   ├── HomePage.swift
│   │   └── AboutPage.swift
│   └── Components/
│       └── Header.swift
├── Content/           # Markdown content (optional)
│   └── posts/
└── Resources/         # Static assets (optional)
    └── images/
```

## Requirements

- Swift 6.3 or later
- macOS 14 or later
