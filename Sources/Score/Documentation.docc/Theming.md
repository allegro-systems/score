# Theming

Centralize your design tokens with Score's theme system.

## Overview

Score's theme system centralizes your design tokens — colors, typography, spacing, and borders — in a single `Theme` conformance. Every page and component in your site inherits these values.

## Defining a theme

```swift
struct MyTheme: Theme {
    var name: String { "default" }

    var colors: ColorSet {
        ColorSet {
            ColorRole(.surface, light: .oklch(l: 0.99, c: 0.0, h: 0))
            ColorRole(.text, light: .oklch(l: 0.15, c: 0.0, h: 0))
            ColorRole(.accent, light: .oklch(l: 0.55, c: 0.15, h: 250))
            ColorRole(.border, light: .oklch(l: 0.90, c: 0.01, h: 250))
            ColorRole(.muted, light: .oklch(l: 0.55, c: 0.02, h: 250))
        }
    }

    var fonts: FontSet {
        FontSet {
            FontFamily(.sans, name: "Inter", source: .google)
            FontFamily(.mono, name: "JetBrains Mono", source: .google)
        }
    }

    var typeScaleBase: Int { 16 }
    var spacingUnit: Int { 4 }
    var radiusBase: Int { 8 }
}
```

## Color tokens

Colors are defined using semantic roles. The built-in roles include:

- `.surface` — page background
- `.text` — primary text
- `.accent` — interactive elements and highlights
- `.border` — borders and dividers
- `.muted` — secondary text
- `.destructive` — error states
- `.success` — success states

You can also define custom named colors:

```swift
ColorRole(.named("score"), light: .oklch(l: 0.65, c: 0.18, h: 145))
ColorRole(.named("stage"), light: .oklch(l: 0.65, c: 0.18, h: 280))
```

To use custom colors as static properties (e.g. `.score` instead of `ColorToken("score")`), use the `#colorTokens` macro:

```swift
extension ColorToken {
    #colorTokens("score", "stage", "brand")
}
```

This generates a `ColorToken` extension with a static property for each name, so you can reference them directly in your modifiers:

```swift
.font(color: .score)
.background(.stage)
```

## OKLCH color space

Score uses OKLCH as its primary color space. OKLCH provides perceptually uniform lightness, which means colors at the same L value appear equally bright to the human eye — making it ideal for building consistent color palettes.

```swift
// OKLCH: Lightness (0-1), Chroma (0-0.4), Hue (0-360)
Color.oklch(l: 0.65, c: 0.15, h: 250)
```

## Dark mode

Add dark mode support with a `ThemePatch`:

```swift
struct DarkPatch: ThemePatch {
    var colors: ColorSet {
        ColorSet {
            ColorRole(.surface, light: .oklch(l: 0.12, c: 0.01, h: 250))
            ColorRole(.text, light: .oklch(l: 0.93, c: 0.01, h: 250))
        }
    }
}
```

Register the patch in your theme:

```swift
var darkPatch: (any ThemePatch)? { DarkPatch() }
```

Score automatically generates `prefers-color-scheme: dark` media queries for overridden values.

## Typography

Font families map to logical roles used throughout your modifiers:

```swift
.font(.sans, size: 16)   // Uses the sans-serif family from your theme
.font(.mono, size: 14)   // Uses the monospace family
.font(.serif, size: 24)  // Uses the serif family
```

Score handles `@font-face` declarations and Google Fonts loading automatically based on your `FontSet` configuration.

## Spacing and radius

The `spacingUnit` and `radiusBase` values establish the grid for padding, margin, gap, and border-radius throughout your site. Modifier values are typically multiples of the spacing unit:

```swift
.padding(24, at: .vertical)  // 24px = 6 spacing units (if unit = 4)
.border(radius: 8)                    // Uses the radius base
```
