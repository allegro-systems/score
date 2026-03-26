# Dev Tools

Inspect components, debug state, and live-edit content during development.

## Overview

Score includes built-in development tools that activate automatically when running in development mode via `swift run score dev`. The dev tools provide component inspection, state debugging, and live editing capabilities.

## Inspector

Click the **Inspect** button on the dev tools pill (bottom-centre of the page) to enter inspect mode. Hover over any element to see a tooltip with:

- **Top section** — The component name, HTML tag, and breadcrumb path through the component tree.
- **Styles** — Human-readable CSS properties applied to the element. Default styles are listed first, followed by breakpoint-specific overrides grouped by breakpoint name (compact, tablet, desktop, etc.).
- **Attributes** — HTML attributes on the element.
- **Bindings** — Reactive bindings including `@State` and `@Computed` values with their current state, scope, and text/visibility bindings.
- **Actions** — Event handlers and `@Action` declarations with descriptions of what they do when triggered.

Click an element to select it and reveal its position in the Components panel.

## Panel

The expandable panel has two tabs:

- **Components** — A tree view of all Score components on the page. Stateful components are highlighted. Click a component to highlight it on the page. Source file links open your editor (configured via the `SCORE_EDITOR` environment variable).
- **State** — Lists all `@State`, `@Computed`, and `@Action` declarations across the page with live values, scopes, and persistence keys.

## Live editing

In development mode, text elements with source location metadata support inline editing. Double-click a text element to edit its content directly in the browser. Changes are written back to the Swift source file and the dev server triggers a rebuild automatically.

The edit API also supports style property changes. The dev tools post edits to `/_dev/edit` which modifies the source file at the annotated location:

- **Text edits** — Replaces string literal content in the Swift source.
- **Style edits** — Updates modifier parameter values near the source line.

### Editor integration

Set the `SCORE_EDITOR` environment variable to configure which editor opens when you click source links in the dev tools:

```
SCORE_EDITOR=vscode swift run score dev   # VS Code (default)
SCORE_EDITOR=subl swift run score dev     # Sublime Text
SCORE_EDITOR=idea swift run score dev     # IntelliJ / WebStorm
```

## Content management (/_content)

Score projects that use the built-in content system (`ContentCollection`, `ContentPage`) and file-based storage can opt in to a web-based content editor at the `/_content` path.

When enabled, `/_content` serves a minimal CMS interface that allows editing of:

- **Text content** — Markdown body text and front matter fields for content items in the `Content/` directory.
- **Image assets** — Upload and replace images referenced by content pages, stored in the `Resources/` directory.

### How it works

The content editor reads directly from the project's `Content/` and `Resources/` directories. Changes are written back to the same files, which triggers a dev server rebuild. This means:

1. Edits are version-controlled — they modify the same files that are committed to git.
2. No external database or API is required — storage is the filesystem.
3. The editor is only available in development mode and only for projects using Score's built-in content and asset systems.

### When it applies

The `/_content` editor is designed for projects where content is stored in Score's own file-based formats:

- Markdown files with YAML front matter in `Content/`
- Static assets in `Resources/`
- Content loaded via `ContentCollection` or `ContentPage`

It does **not** apply to projects that fetch content from external databases, third-party CMSes, or remote APIs. If your content comes from an external source, the `/_content` path is not served.

### Opting in

The content editor is enabled by default when the dev server detects a `Content/` directory in the project root. To disable it:

```
swift run score dev --no-content-editor
```
