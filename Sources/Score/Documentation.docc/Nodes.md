# Nodes

The fundamental building blocks of every Score page.

## Overview

Nodes are the fundamental building blocks of every Score page. Every element you see on a page — text, headings, images, containers — is a node.

## Content nodes

### Heading

```swift
Heading(.one) { "Page Title" }
Heading(.two) { "Section Title" }
Heading(.three) { "Subsection" }
```

Supports levels `.one` through `.six`, mapping to `<h1>` through `<h6>`.

### Paragraph

```swift
Paragraph { "Body text goes here." }
```

### Text and InlineText

```swift
Text { "A span of text." }
```

`Text` renders as a `<span>`. Use it for inline content within other elements.

### Lists

```swift
UnorderedList {
    ListItem { "First item" }
    ListItem { "Second item" }
}

OrderedList {
    ListItem { "Step one" }
    ListItem { "Step two" }
}
```

## Container nodes

### Stack

The primary layout container. Combine with `.flex()` or `.grid()` modifiers:

```swift
Stack {
    Heading(.two) { "Title" }
    Paragraph { "Content" }
}
.flex(.column, gap: 16)
```

### Section, Article, Aside, Nav

Semantic containers that map directly to their HTML counterparts:

```swift
Section {
    // Page section content
}

Article {
    // Self-contained content
}

Aside {
    // Sidebar or supplementary content
}
```

### Main, Header, Footer

Document structure elements:

```swift
Main {
    // Primary page content
}
```

## Interactive nodes

### Link

```swift
Link(to: "/about") { "About us" }
Link(to: "https://github.com", external: true) { "GitHub" }
```

### Button

```swift
Button(.click, $handler) { "Click me" }
```

### Form elements

```swift
Form {
    Label(for: "email") { "Email" }
    Input(type: .email, name: "email", placeholder: "you@example.com")
    Textarea(name: "message", placeholder: "Your message...")
    Select(name: "topic") {
        Option(value: "general") { "General" }
        Option(value: "support") { "Support" }
    }
}
```

## Media nodes

### Image

```swift
Image(src: "/assets/hero.jpg", alt: "Hero image")
    .size(width: .percent(100))
```

Images use lazy loading by default.

### Figure

```swift
Figure {
    Image(src: "/assets/diagram.svg", alt: "Architecture diagram")
    Figcaption { "System architecture overview" }
}
```

## Utility nodes

### EmptyNode

Renders nothing. Useful in conditional expressions:

```swift
if showBanner {
    Banner()
} else {
    EmptyNode()
}
```

### ForEachNode

Iterates over a collection to produce nodes:

```swift
ForEachNode(products) { product in
    ProductCard(product: product)
}
```

### HorizontalRule

```swift
HorizontalRule()
```

## Composition with @NodeBuilder

The `@NodeBuilder` result builder allows composing multiple nodes in a block:

```swift
var body: some Node {
    Heading(.one) { "Title" }
    Paragraph { "First paragraph." }
    Paragraph { "Second paragraph." }
}
```

Supports `if`/`else` conditions, `for` loops, and optional expressions.
