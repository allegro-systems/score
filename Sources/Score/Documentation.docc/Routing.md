# Routing

Map URLs to pages and API endpoints.

## Overview

Score uses a file-based routing model where each `Page` declares its own URL path. For dynamic server-side routes, `Controller` provides HTTP method handlers.

## Page routing

Every page has a static `path` property:

```swift
struct AboutPage: Page {
    static let path = "/about"
    var body: some Node { /* ... */ }
}
```

Pages handle `GET` requests and produce HTML responses. The route table is built automatically from registered pages.

## Content page routing

`ContentPage` types generate routes from a directory of Markdown files:

```swift
struct DocsPages: ContentPage {
    static let content = "Content/docs"
    static let prefix = "/docs"
    var item: ContentCollection.Item
    var body: some Node { MarkdownNode(item.body) }
}
```

This generates `/docs/{slug}` for each file. An `index.md` file maps to `/docs` directly.

## Controllers

For non-GET routes and API endpoints, use the `Controller` protocol:

```swift
struct UserController: Controller {
    static let path = "/api/users"

    var routes: [Route] {
        Route(.get) { request in
            // Return user list
        }
        Route(.post) { request in
            // Create user
        }
    }
}
```

Register controllers in your application:

```swift
var controllers: [any Controller] {
    [UserController(), PostController()]
}
```

## Path parameters

Both pages and controllers support path parameters with the `:param` syntax:

```swift
static let path = "/users/:id"
```

## Route priority

Routes are resolved in order:

1. **Exact page matches** — static paths checked first
2. **Parameterized pages** — paths with `:param` segments
3. **Controller routes** — matched by path and HTTP method
4. **Error page** — if no route matches

The route table uses a trie data structure for efficient O(path-length) lookup.
