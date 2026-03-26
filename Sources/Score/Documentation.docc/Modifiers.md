# Modifiers

Style and configure nodes with composable CSS-emitting modifiers.

## Overview

Modifiers are composable transformations that style and configure nodes. They chain naturally and emit scoped CSS at build time.

## Layout modifiers

### Flex

```swift
Stack {
    Text { "Left" }
    Text { "Right" }
}
.flex(.row, gap: 16, align: .center)
```

Options: `.row`, `.column`, `.rowReverse`, `.columnReverse`. Parameters include `gap`, `align`, `justify`, and `wraps`.

### Grid

```swift
Stack {
    for item in items {
        Card(item: item)
    }
}
.grid(columns: 3, gap: 20)
```

### Display and position

```swift
.display(.block)
.display(.none)
.position(.relative)
.position(.absolute, top: 0, right: 0)
```

## Sizing modifiers

```swift
.size(width: 300, height: 200)
.size(maxWidth: 720)
.size(minHeight: .percent(100))
```

## Box model

### Padding

```swift
.padding(24, at: .all)
.padding(16, at: .horizontal)
.padding(40, at: .top)
```

### Margin

```swift
.margin(0, at: .horizontal)  // Center a block element
.margin(24, at: .bottom)
```

### Border

```swift
.border(width: 1, color: .border, style: .solid)
.border(width: 1, color: .border, style: .solid, at: .bottom)
```

### Radius

```swift
.radius(8)
.radius(9999)  // Fully rounded (pill shape)
```

## Typography

```swift
.font(.sans, size: 16, weight: .regular, lineHeight: 1.6, color: .text)
.font(.mono, size: 13, weight: .medium, tracking: 1, color: .muted)
.font(.serif, size: 32, weight: .light, lineHeight: 1.15, color: .text, align: .center)
```

Additional text options: `wrap: .balance`, `decoration: .underline`, `transform: .uppercase`.

## Visual modifiers

### Background

```swift
.background(.surface)
.background(.elevated)
.backgroundGradient(.radial(color: .accent, opacity: 0.04, width: 100, height: 60, at: .top))
```

### Shadow

```swift
.shadow(x: 0, y: 2, blur: 8, color: .border)
```

### Opacity

```swift
.opacity(0.5)
```

## Responsive modifiers

Score provides breakpoint modifiers for responsive design:

```swift
Heading(.one) { "Welcome" }
    .font(.serif, size: 56, weight: .light)
    .tablet { $0.font(size: 44) }
    .compact { $0.font(size: 32) }
```

- `.compact { }` — small screens (mobile)
- `.tablet { }` — medium screens
- `.desktop { }` — large screens

Each breakpoint modifier receives the current node and returns a modified version. Styles cascade from the base to each breakpoint.

## Interaction modifiers

### Hover

```swift
.hover { $0.background(.accent).color(.surface) }
```

### Events

```swift
Button(.click, $handler) { "Click me" }
```

### Transitions

```swift
.transition(.all, duration: 0.2)
```

## Overflow

```swift
.overflow(x: .auto)
.overflow(y: .scroll)
```

## Chaining

Modifiers chain left to right. Each modifier wraps the previous node, and CSS is collected in order:

```swift
Text { "Hello" }
    .font(.mono, size: 14, color: .accent)
    .padding(8, at: .horizontal)
    .padding(4, at: .vertical)
    .background(.elevated)
    .radius(4)
    .hover { $0.background(.accent).color(.surface) }
    .transition(.all, duration: 0.15)
```
