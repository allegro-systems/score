# Content

Generate pages from Markdown files with YAML front matter.

## Overview

Score's content system lets you generate pages from Markdown files with YAML front matter. It's designed for blogs, documentation, and any structured content that benefits from file-based authoring.

## Content directory

Place Markdown files in a `Content/` directory within your project:

```
Content/
├── posts/
│   ├── hello-world.md
│   └── getting-started.md
└── docs/
    └── score/
        ├── index.md
        └── pages.md
```

Each `.md` file becomes a content item. The filename (without extension) becomes the URL slug.

## Front matter

Content files support YAML-style front matter delimited by `---`:

```
---
title: Hello World
date: 2026-01-15
category: Engineering
tags: swift, score
draft: false
---

Your markdown content goes here.
```

Access front matter values in your templates:

```swift
item.frontMatter?.string("title")    // "Hello World"
item.frontMatter?.string("date")     // "2026-01-15"
item.frontMatter?.bool("draft")      // false
item.frontMatter?.list("tags")       // ["swift", "score"]
item.frontMatter?.integer("order")   // nil (not set)
```

## ContentPage protocol

Define a `ContentPage` to generate one page per Markdown file:

```swift
struct BlogPosts: ContentPage {
    static let content = "Content/posts"
    static let prefix = "/blog"

    var item: ContentCollection.Item

    var body: some Node {
        Layout {
            Heading(.one) { item.frontMatter?.string("title") ?? "" }
            MarkdownNode(item.body)
        }
    }
}
```

Register it in your application alongside regular pages:

```swift
@PageBuilder
var pages: [any Page] {
    HomePage()
    BlogPage()
    BlogPosts()
}
```

A file at `Content/posts/hello-world.md` generates a page at `/blog/hello-world`. A file named `index.md` maps to the prefix itself (`/blog`).

## ContentCollection

Load and query content collections directly for listing pages or custom layouts:

```swift
let posts = ContentCollection(loading: "Content/posts")

// Sort by date, newest first
let sorted = posts.sorted(by: "date", ascending: false)

// Filter by category
let engineering = posts.filter { $0?.string("category") == "Engineering" }

// Get unique categories
let categories = posts.uniqueValues(for: "category")

// Get unique tags (comma-separated values)
let tags = posts.uniqueTags(for: "tags")

// Look up by slug
let post = posts.item(slug: "hello-world")
```

## MarkdownNode

Render Markdown content as Score nodes:

```swift
MarkdownNode(item.body)
```

`MarkdownNode` supports:

- Headings (h1–h6)
- Paragraphs with inline formatting (bold, italic, code, links)
- Code blocks with syntax highlighting (Swift, HTML, CSS, JavaScript)
- Blockquotes
- Ordered and unordered lists
- Tables
- Images
- Horizontal rules
- Raw HTML blocks

## Code blocks

Fenced code blocks with a language identifier get syntax highlighting:

````
```swift
struct MyPage: Page {
    static let path = "/"
    var body: some Node { Text { "Hello" } }
}
```
````

Consecutive code blocks with `tab` in the info string are grouped into a tabbed interface:

````
```swift tab
let x = 42
```

```html tab
<div>42</div>
```
````

## Math expressions

Code blocks with the `math` info string render LaTeX as MathML:

````
```math
\frac{a}{b} + \sqrt{c}
```
````
