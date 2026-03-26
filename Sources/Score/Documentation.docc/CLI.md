# CLI

Build, develop, and deploy Score projects from the command line.

## Overview

The Score CLI provides commands for creating, developing, building, and deploying Score projects.

## Commands

### score init

Create a new Score project from a template:

```
swift run score init my-site
```

Scaffolds a complete project structure with `Package.swift`, a theme, a home page, and example components.

### score dev

Start a development server with hot reload:

```
swift run score dev --port 8080
```

The dev server:

- Compiles your project in debug mode
- Starts a local HTTP server
- Watches `Sources/` and `Resources/` for file changes
- Rebuilds and restarts automatically on change
- Injects dev tools for component inspection and state debugging

Options:

- `--port <port>` — Server port (default: 8080)
- `--no-devtools` — Disable dev tools injection

### score build

Build the site for production:

```
swift run score build
```

This compiles in release mode and emits static output to the `.score` directory:

```
.score/
├── index.html
├── about/index.html
├── global.css
├── styles/
│   ├── shared.css
│   └── home.css
├── scripts/
│   ├── score.js
│   └── shared.js
└── assets/
    └── images/
```

CSS and JavaScript are chunked per-page with shared styles extracted automatically. Assets are fingerprinted for cache busting.

### score deploy

Deploy the built site to Stage:

```
swift run score deploy
```

Runs the build step if needed, then uploads the `.score` directory to Stage's global CDN. Deployments are atomic — the new version goes live only after all assets are verified.

## Using with mise

A typical `mise.toml` configuration:

```toml
[tools]
swift = "6.3"

[tasks.dev]
run = 'swift run score dev --port "${usage_port?}"'

[tasks.build]
run = 'swift run score build'

[tasks.clean]
run = '''
swift package clean
rm -rf .score
'''
```

Then run tasks with:

```
mise run dev --port 3000
mise run build
mise run clean
```
