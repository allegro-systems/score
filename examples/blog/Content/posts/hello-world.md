---
title: Hello, World
date: 2026-01-15
tags: score, swift, introduction
summary: Welcome to the Score blog example. This post introduces the framework and shows how content collections work.
---

# Hello, World

Welcome to the **Score Blog** example. This project demonstrates how to build a content-driven site with Score using:

- **ContentCollection** for loading and indexing markdown files
- **FrontMatter** for structured metadata per post
- **MarkdownConverter** for rendering markdown to Score nodes
- **Metadata** for per-page SEO overrides

## Getting Started

Create markdown files in `Content/posts/` with YAML front matter at the top. Score's `ContentCollection` loads them automatically and gives you filtering, sorting, and tag extraction.

## Code Example

```swift
let posts = try ContentCollection(directory: "Content/posts")
let latest = posts.sorted(by: "date", ascending: false)
```

That's it. Each post becomes a `ContentCollection.Item` with its slug, front matter, and body text ready for rendering.
