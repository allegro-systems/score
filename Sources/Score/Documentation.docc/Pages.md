# Pages

Define URL-addressable views using the Page protocol.

## Overview

A page is a struct that conforms to the `Page` protocol. Each page maps to a URL path and declares its content through a `body` property.

## Defining a page

```swift
struct AboutPage: Page {
    static let path = "/about"

    var body: some Node {
        Heading(.one) { "About" }
        Paragraph { "Learn more about us." }
    }
}
```

The `path` property defines the URL where the page is served. The `body` property uses `@NodeBuilder` syntax to compose the page's content from nodes.

## Registering pages

Pages are registered in your `Application` struct using the `@PageBuilder`:

```swift
@main
struct MySite: Application {
    @PageBuilder
    var pages: [any Page] {
        HomePage()
        AboutPage()
        BlogPage()
    }
}
```

## Page metadata

Pages can override application-level metadata:

```swift
struct AboutPage: Page {
    static let path = "/about"

    var metadata: (any Metadata)? {
        SiteMetadata(
            title: "About Us",
            description: "Learn about our team and mission."
        )
    }

    var body: some Node {
        Heading(.one) { "About" }
    }
}
```

## Error pages

Define a custom error page by conforming to the `ErrorPage` protocol:

```swift
struct NotFoundPage: ErrorPage {
    var body: some Node {
        Section {
            Heading(.one) { "404" }
            Paragraph { "Page not found." }
        }
    }
}
```

Register it in your application:

```swift
var errorPage: (any ErrorPage.Type)? { NotFoundPage.self }
```

## Content pages

For pages generated from markdown content files, see <doc:Content>. Content pages let you generate multiple pages from a directory of markdown files without writing a `Page` struct for each one.
