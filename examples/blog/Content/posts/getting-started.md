---
title: Getting Started with Score
date: 2026-01-20
tags: score, tutorial, guide
summary: A step-by-step guide to creating your first Score application from scratch.
---

# Getting Started with Score

This guide walks you through creating a Score application from scratch.

## Prerequisites

- Swift 6.2 or later
- macOS 14+

## Step 1: Create the Project

```bash
score init MyApp --template minimal
cd MyApp
```

## Step 2: Define a Page

Every route in a Score application is a `Page`:

```swift
struct Home: Page {
    static let path = "/"

    var body: some Node {
        Heading(.one) { Text { "Hello, Score!" } }
    }
}
```

## Step 3: Register and Run

Add your pages to the `Application` and run:

```swift
@main
struct MyApp: Application {
    var pages: [any Page] { [Home()] }

    static func main() async throws {
        try await MyApp().run()
    }
}
```

Run with `swift run` and visit `http://localhost:8080`.
