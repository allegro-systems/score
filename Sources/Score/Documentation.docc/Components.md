# Components

Build reusable, stateful UI elements with the Component protocol.

## Overview

Components are reusable building blocks that conform to the `Component` protocol. They encapsulate a piece of UI with its own properties and body.

## Defining a component

```swift
struct FeatureCard: Component {
    let title: String
    let description: String

    var body: some Node {
        Article {
            Heading(.three) { title }
                .font(.serif, size: 20, weight: .medium, color: .text)
            Paragraph { description }
                .font(.mono, size: 14, color: .muted)
        }
        .padding(24, at: .all)
        .background(.elevated)
        .radius(8)
    }
}
```

## Using components

Components are used inside `@NodeBuilder` blocks like any other node:

```swift
struct FeaturesPage: Page {
    static let path = "/features"

    var body: some Node {
        Section {
            FeatureCard(title: "Fast", description: "Pre-rendered at build time.")
            FeatureCard(title: "Safe", description: "Type-checked by the compiler.")
        }
        .flex(.column, gap: 24)
    }
}
```

## Stateful components

Add reactivity to a component with the `@State` macro. Only components that use `@State` ship client-side JavaScript — everything else is pure static HTML.

```swift
struct Counter: Component {
    @State var count = 0

    var body: some Node {
        Button(.click, $count.increment()) {
            Text { "Count: \($count)" }
        }
    }
}
```

The `@State` macro creates a reactive signal. When the state changes, only the affected DOM nodes update — no full-page re-render.

## Computed properties

Use `@Computed` for derived values that update automatically when their dependencies change:

```swift
struct TemperatureConverter: Component {
    @State var celsius: Double = 0

    @Computed var fahrenheit: Double {
        celsius * 9 / 5 + 32
    }

    var body: some Node {
        Stack {
            Text { "Celsius: \($celsius)" }
            Text { "Fahrenheit: \($fahrenheit)" }
        }
    }
}
```

## Actions

Use `@Action` for event handlers that modify state:

```swift
struct TodoItem: Component {
    @State var completed = false

    @Action func toggle() {
        completed.toggle()
    }

    var body: some Node {
        Button(.click, $toggle) {
            Text { completed ? "Done" : "Pending" }
        }
    }
}
```

## Component vs Node

The key difference between `Component` and `Node`:

- **Node** is the fundamental rendering unit. All elements are nodes.
- **Component** is a node with its own scope for state and styling. Use it when you need reusable UI with encapsulated behavior.

For simple, stateless pieces of content, a plain `Node` is sufficient. Reach for `Component` when you need state, reusable styling, or a clear compositional boundary.
