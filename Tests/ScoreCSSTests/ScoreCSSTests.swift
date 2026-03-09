import Testing

@testable import ScoreCSS

// MARK: - CSSDeclaration

@Test func declarationRendersPropertyAndValue() {
    let decl = CSSDeclaration(property: "color", value: "red")
    #expect(decl.render() == "color: red")
}

@Test func declarationHashableEquality() {
    let a = CSSDeclaration(property: "color", value: "red")
    let b = CSSDeclaration(property: "color", value: "red")
    let c = CSSDeclaration(property: "color", value: "blue")
    #expect(a == b)
    #expect(a != c)
}

// MARK: - ColorToken → CSS

@Test func semanticColorTokenProducesVar() {
    #expect(ColorToken.surface.cssValue == "var(--color-surface)")
    #expect(ColorToken.text.cssValue == "var(--color-text)")
    #expect(ColorToken.accent.cssValue == "var(--color-accent)")
}

@Test func paletteColorTokenProducesVar() {
    #expect(ColorToken.blue(500).cssValue == "var(--color-blue-500)")
    #expect(ColorToken.neutral(100).cssValue == "var(--color-neutral-100)")
}

@Test func oklchColorTokenProducesValue() {
    let value = ColorToken.oklch(0.5, 0.1, 120).cssValue
    #expect(value.hasPrefix("oklch("))
}

// MARK: - CSSEmitter: spacing

@Test func paddingEmitterProducesShorthand() {
    let decls = CSSEmitter.declarations(for: PaddingModifier(16))
    #expect(decls.count == 1)
    #expect(decls[0].property == "padding")
    #expect(decls[0].value == "16px")
}

@Test func paddingEmitterProducesEdgeDeclarations() {
    let decls = CSSEmitter.declarations(for: PaddingModifier(8, edges: [.top, .bottom]))
    #expect(decls.count == 2)
    let props = Set(decls.map(\.property))
    #expect(props.contains("padding-top"))
    #expect(props.contains("padding-bottom"))
}

@Test func marginEmitterProducesShorthand() {
    let decls = CSSEmitter.declarations(for: MarginModifier(0))
    #expect(decls.count == 1)
    #expect(decls[0].property == "margin")
    #expect(decls[0].value == "0px")
}

// MARK: - CSSEmitter: visual

@Test func backgroundColorEmitter() {
    let decls = CSSEmitter.declarations(for: BackgroundModifier(.surface))
    #expect(decls.count == 1)
    #expect(decls[0].property == "background-color")
    #expect(decls[0].value == "var(--color-surface)")
}

@Test func opacityEmitter() {
    let decls = CSSEmitter.declarations(for: OpacityModifier(0.5))
    #expect(decls.count == 1)
    #expect(decls[0].property == "opacity")
    #expect(decls[0].value == "0.5")
}

@Test func radiusEmitter() {
    let decls = CSSEmitter.declarations(for: RadiusModifier(8))
    #expect(decls.count == 1)
    #expect(decls[0].property == "border-radius")
    #expect(decls[0].value == "8px")
}

@Test func shadowEmitter() {
    let decls = CSSEmitter.declarations(for: ShadowModifier(x: 0, y: 4, blur: 12, spread: 0, color: .text))
    #expect(decls.count == 1)
    #expect(decls[0].property == "box-shadow")
    #expect(decls[0].value.contains("4px"))
    #expect(decls[0].value.contains("12px"))
}

// MARK: - CSSEmitter: sizing

@Test func sizeEmitterWidth() {
    let decls = CSSEmitter.declarations(for: SizeModifier(width: 320))
    let widthDecl = decls.first { $0.property == "width" }
    #expect(widthDecl?.value == "320px")
}

@Test func sizeEmitterMinMax() {
    let decls = CSSEmitter.declarations(for: SizeModifier(minWidth: 200, maxWidth: 800))
    let props = Set(decls.map(\.property))
    #expect(props.contains("min-width"))
    #expect(props.contains("max-width"))
    #expect(!props.contains("width"))
}

@Test func aspectRatioEmitter() {
    let decls = CSSEmitter.declarations(for: AspectRatioModifier(1.0))
    #expect(decls.count == 1)
    #expect(decls[0].property == "aspect-ratio")
    #expect(decls[0].value == "1")
}

// MARK: - CSSEmitter: layout

@Test func flexEmitterProducesDisplayAndDirection() {
    let decls = CSSEmitter.declarations(for: FlexModifier(.row))
    let props = decls.map(\.property)
    #expect(props.contains("display"))
    #expect(props.contains("flex-direction"))
    #expect(props.contains("flex-wrap"))
    let display = decls.first { $0.property == "display" }?.value
    #expect(display == "flex")
}

@Test func flexEmitterGap() {
    let decls = CSSEmitter.declarations(for: FlexModifier(.column, gap: 16))
    let gap = decls.first { $0.property == "gap" }
    #expect(gap?.value == "16px")
}

@Test func gridEmitterProducesTemplateColumns() {
    let decls = CSSEmitter.declarations(for: GridModifier(columns: 3))
    let cols = decls.first { $0.property == "grid-template-columns" }
    #expect(cols?.value == "repeat(3, 1fr)")
}

@Test func hiddenEmitterProducesDisplayNone() {
    let decls = CSSEmitter.declarations(for: HiddenModifier())
    #expect(decls.count == 1)
    #expect(decls[0].property == "display")
    #expect(decls[0].value == "none")
}

@Test func positionEmitterProducesMode() {
    let decls = CSSEmitter.declarations(for: PositionModifier(.absolute, top: 0, leading: 0))
    let pos = decls.first { $0.property == "position" }
    #expect(pos?.value == "absolute")
    let top = decls.first { $0.property == "top" }
    #expect(top?.value == "0px")
}

// MARK: - CSSEmitter: typography

@Test func fontEmitterSize() {
    let decls = CSSEmitter.declarations(for: FontModifier(size: 16))
    let size = decls.first { $0.property == "font-size" }
    #expect(size?.value == "16px")
}

@Test func fontEmitterColor() {
    let decls = CSSEmitter.declarations(for: FontModifier(color: .accent))
    let color = decls.first { $0.property == "color" }
    #expect(color?.value == "var(--color-accent)")
}

// MARK: - CSSEmitter: transitions and animations

@Test func transitionEmitterProducesDuration() {
    let decls = CSSEmitter.declarations(for: TransitionModifier(property: "opacity", duration: 0.3))
    let dur = decls.first { $0.property == "transition-duration" }
    #expect(dur?.value == "0.3s")
}

@Test func transitionEmitterWithTiming() {
    let decls = CSSEmitter.declarations(for: TransitionModifier(property: "color", duration: 0.2, timing: "ease-in-out"))
    let timing = decls.first { $0.property == "transition-timing-function" }
    #expect(timing?.value == "ease-in-out")
}

@Test func animationEmitterProducesShorthand() {
    let decls = CSSEmitter.declarations(for: AnimationModifier(name: "spin", duration: 1.0, timing: "linear", iterationCount: "infinite"))
    #expect(decls.count == 1)
    #expect(decls[0].property == "animation")
    #expect(decls[0].value.contains("spin"))
    #expect(decls[0].value.contains("1s"))
    #expect(decls[0].value.contains("linear"))
    #expect(decls[0].value.contains("infinite"))
}

// MARK: - CSSEmitter: unknown modifier

@Test func unknownModifierReturnsEmpty() {
    struct UnknownMod: ModifierValue {}
    let decls = CSSEmitter.declarations(for: UnknownMod())
    #expect(decls.isEmpty)
}

// MARK: - CSSCollector: deduplication

@Test func collectorDeduplicatesIdenticalModifiers() {
    let node = Stack {
        Stack { TextNode("a") }.padding(16)
        Stack { TextNode("b") }.padding(16)
    }
    var collector = CSSCollector()
    collector.collect(from: node)
    let rules = collector.collectedRules()
    #expect(rules.count == 1)
}

@Test func collectorKeepsDifferentModifierSets() {
    let node = Stack {
        Stack { TextNode("a") }.padding(8)
        Stack { TextNode("b") }.padding(16)
    }
    var collector = CSSCollector()
    collector.collect(from: node)
    let rules = collector.collectedRules()
    #expect(rules.count == 2)
}

@Test func collectorRendersStylesheet() {
    let node = Stack { TextNode("hi") }.padding(12)
    var collector = CSSCollector()
    collector.collect(from: node)
    let css = collector.renderStylesheet()
    #expect(css.contains("padding: 12px"))
    #expect(css.contains(".s-"))
}

@Test func collectorWalksNestedNodes() {
    let node = Stack {
        Stack {
            TextNode("deep").padding(4)
        }
    }
    var collector = CSSCollector()
    collector.collect(from: node)
    let rules = collector.collectedRules()
    #expect(!rules.isEmpty)
    let hasDepth = rules.contains { rule in
        rule.declarations.contains { $0.property == "padding" && $0.value == "4px" }
    }
    #expect(hasDepth)
}

// MARK: - px helper

@Test func pxHelperOmitsDecimalForWholeNumbers() {
    let a = CSSEmitter.declarations(for: PaddingModifier(16))
    #expect(a[0].value == "16px")
    let b = CSSEmitter.declarations(for: PaddingModifier(16.5))
    #expect(b[0].value == "16.5px")
}

// MARK: - Additional emitter coverage

@Test func borderEmitterSupportsEdgesAndRadius() {
    let all = CSSEmitter.declarations(for: BorderModifier(width: 2, color: .accent, style: .dashed, radius: 6))
    #expect(all.contains(CSSDeclaration(property: "border", value: "2px dashed var(--color-accent)")))
    #expect(all.contains(CSSDeclaration(property: "border-radius", value: "6px")))

    let edges = CSSEmitter.declarations(for: BorderModifier(width: 1, color: .text, style: .solid, edges: [.top, .leading]))
    #expect(edges.contains(CSSDeclaration(property: "border-top", value: "1px solid var(--color-text)")))
    #expect(edges.contains(CSSDeclaration(property: "border-inline-start", value: "1px solid var(--color-text)")))
}

@Test func itemLayoutEmittersCoverAllProperties() {
    let flexItem = CSSEmitter.declarations(for: FlexItemModifier(grow: 1, shrink: 0, basis: 240, order: 2, alignSelf: .center))
    #expect(flexItem.contains(CSSDeclaration(property: "flex-grow", value: "1")))
    #expect(flexItem.contains(CSSDeclaration(property: "flex-shrink", value: "0")))
    #expect(flexItem.contains(CSSDeclaration(property: "flex-basis", value: "240px")))
    #expect(flexItem.contains(CSSDeclaration(property: "order", value: "2")))
    #expect(flexItem.contains(CSSDeclaration(property: "align-self", value: "center")))

    let gridPlacement = CSSEmitter.declarations(for: GridPlacementModifier(column: "1 / 3", row: "2", area: "hero", justifySelf: .center, placeSelf: "center end"))
    #expect(gridPlacement.contains(CSSDeclaration(property: "grid-column", value: "1 / 3")))
    #expect(gridPlacement.contains(CSSDeclaration(property: "grid-row", value: "2")))
    #expect(gridPlacement.contains(CSSDeclaration(property: "grid-area", value: "hero")))
    #expect(gridPlacement.contains(CSSDeclaration(property: "justify-self", value: "center")))
    #expect(gridPlacement.contains(CSSDeclaration(property: "place-self", value: "center end")))
}

@Test func structuredContentEmittersCoverAllProperties() {
    let list = CSSEmitter.declarations(for: ListStyleModifier(type: .disc, position: .inside, image: "url('/dot.svg')"))
    #expect(list.contains(CSSDeclaration(property: "list-style-type", value: "disc")))
    #expect(list.contains(CSSDeclaration(property: "list-style-position", value: "inside")))
    #expect(list.contains(CSSDeclaration(property: "list-style-image", value: "url('/dot.svg')")))

    let table = CSSEmitter.declarations(for: TableStyleModifier(layout: .fixed, borderCollapse: .collapse, borderSpacing: 4, captionSide: .bottom))
    #expect(table.contains(CSSDeclaration(property: "table-layout", value: "fixed")))
    #expect(table.contains(CSSDeclaration(property: "border-collapse", value: "collapse")))
    #expect(table.contains(CSSDeclaration(property: "border-spacing", value: "4px")))
    #expect(table.contains(CSSDeclaration(property: "caption-side", value: "bottom")))
}

@Test func displayFilterInteractionAndScrollEmittersCoverAllProperties() {
    let display = CSSEmitter.declarations(for: DisplayModifier(.inlineBlock))
    #expect(display == [CSSDeclaration(property: "display", value: "inline-block")])

    let overflow = CSSEmitter.declarations(for: OverflowModifier(x: .hidden, y: .auto))
    #expect(overflow.contains(CSSDeclaration(property: "overflow-x", value: "hidden")))
    #expect(overflow.contains(CSSDeclaration(property: "overflow-y", value: "auto")))

    let filter = CSSEmitter.declarations(for: FilterModifier("blur(4px)"))
    #expect(filter == [CSSDeclaration(property: "filter", value: "blur(4px)")])

    let backdrop = CSSEmitter.declarations(for: BackdropFilterModifier("saturate(150%)"))
    #expect(backdrop == [CSSDeclaration(property: "backdrop-filter", value: "saturate(150%)")])

    let blend = CSSEmitter.declarations(for: BlendModeModifier("multiply"))
    #expect(blend == [CSSDeclaration(property: "mix-blend-mode", value: "multiply")])

    let cursor = CSSEmitter.declarations(for: CursorModifier(.grab))
    #expect(cursor == [CSSDeclaration(property: "cursor", value: "grab")])

    let userSelect = CSSEmitter.declarations(for: UserSelectModifier(.none))
    #expect(userSelect == [CSSDeclaration(property: "user-select", value: "none")])

    let behavior = CSSEmitter.declarations(for: ScrollBehaviorModifier(.smooth))
    #expect(behavior == [CSSDeclaration(property: "scroll-behavior", value: "smooth")])

    let margin = CSSEmitter.declarations(for: ScrollMarginModifier(24))
    #expect(margin == [CSSDeclaration(property: "scroll-margin", value: "24px")])

    let padding = CSSEmitter.declarations(for: ScrollPaddingModifier(12))
    #expect(padding == [CSSDeclaration(property: "scroll-padding", value: "12px")])

    let snap = CSSEmitter.declarations(for: ScrollSnapModifier(type: .x, align: .center))
    #expect(snap.contains(CSSDeclaration(property: "scroll-snap-type", value: "x")))
    #expect(snap.contains(CSSDeclaration(property: "scroll-snap-align", value: "center")))
}

// MARK: - Additional collector traversal coverage

@Test func collectorWalksAcrossNodeFamiliesIncludingLeafNodes() {
    let node = Stack {
        Article {
            Header { TextNode("h").padding(1) }
            Section {
                Paragraph { TextNode("p").margin(2) }
                UnorderedList {
                    ListItem { TextNode("li").font(size: 12) }
                }
                DescriptionList {
                    DescriptionTerm { TextNode("dt") }
                    DescriptionDetails { TextNode("dd").opacity(0.8) }
                }
                Form(action: "/", method: .post) {
                    Label(for: "name") { TextNode("Name") }
                    Input(type: .text, name: "name")
                    Select(name: "country") {
                        Option(value: "uk") { TextNode("UK") }
                        OptionGroup(label: "Nordics") {
                            Option(value: "se") { TextNode("SE") }
                        }
                    }
                    TextArea(name: "bio")
                    Fieldset {
                        Legend { TextNode("Legend") }
                        Output(for: "name") { TextNode("ok") }
                    }
                    DataList(id: "langs") {
                        Option(value: "swift") { TextNode("Swift") }
                    }
                    Progress(value: 0.1, max: 1)
                    Meter(value: 0.6, min: 0, max: 1)
                }
                Figure {
                    Image(src: "/img.png", alt: "alt")
                    FigureCaption { TextNode("cap") }
                }
                Picture {
                    Source(src: "/a.webp", type: "image/webp")
                    Image(src: "/a.jpg", alt: "a")
                }
                Audio {
                    Source(src: "/track.mp3")
                    Track(src: "/track.vtt")
                }
                Video {
                    Source(src: "/v.mp4")
                }
                Canvas { TextNode("fallback").padding(3) }
                Table {
                    TableCaption { TextNode("caption") }
                    TableHead {
                        TableRow {
                            TableHeaderCell { TextNode("h") }
                        }
                    }
                    TableBody {
                        TableRow {
                            TableCell { TextNode("c") }
                        }
                    }
                    TableFooter {
                        TableRow {
                            TableCell { TextNode("f") }
                        }
                    }
                    TableColumnGroup {
                        TableColumn(span: 1)
                    }
                }
                Details(summary: { Summary { TextNode("sum") } }) {
                    Link(to: "/") { TextNode("go") }
                    Menu { TextNode("menu") }
                    Dialog { TextNode("dialog") }
                }
                HorizontalRule()
                LineBreak()
            }
            Footer { TextNode("f") }
            Aside { TextNode("a") }
            Navigation { TextNode("n") }
            Group { TextNode("g") }
        }
    }

    var collector = CSSCollector()
    collector.collect(from: node)
    let css = collector.renderStylesheet()
    #expect(css.contains("padding: 1px"))
    #expect(css.contains("margin: 2px"))
    #expect(css.contains("font-size: 12px"))
    #expect(css.contains("opacity: 0.8"))
    #expect(css.contains("padding: 3px"))
}

@Test func mediaAndOutlineEmittersProduceExpectedDeclarations() {
    let fit = CSSEmitter.declarations(for: ObjectFitModifier(.cover))
    #expect(fit == [CSSDeclaration(property: "object-fit", value: "cover")])

    let position = CSSEmitter.declarations(for: ObjectPositionModifier("center 20%"))
    #expect(position == [CSSDeclaration(property: "object-position", value: "center 20%")])

    let outline = CSSEmitter.declarations(for: OutlineModifier(width: 2, style: .dotted, color: .accent, offset: 3))
    #expect(outline.contains(CSSDeclaration(property: "outline", value: "2px dotted var(--color-accent)")))
    #expect(outline.contains(CSSDeclaration(property: "outline-offset", value: "3px")))
}

@Test func backgroundImageAndTypographyEmittersCoverAllBranches() {
    let bg = CSSEmitter.declarations(
        for: BackgroundImageModifier(
            image: "url('/bg.png')",
            size: "cover",
            position: "center",
            repeatMode: .noRepeat,
            clip: "text"
        )
    )
    #expect(bg.contains(CSSDeclaration(property: "background-image", value: "url('/bg.png')")))
    #expect(bg.contains(CSSDeclaration(property: "background-size", value: "cover")))
    #expect(bg.contains(CSSDeclaration(property: "background-position", value: "center")))
    #expect(bg.contains(CSSDeclaration(property: "background-repeat", value: "no-repeat")))
    #expect(bg.contains(CSSDeclaration(property: "background-clip", value: "text")))

    let font = CSSEmitter.declarations(
        for: FontModifier(
            .custom("Inter", fallback: .serif),
            size: 14,
            weight: .medium,
            tracking: 0.4,
            lineHeight: 1.25,
            color: .text
        )
    )
    #expect(font.contains(CSSDeclaration(property: "font-family", value: "\"Inter\", var(--font-serif)")))
    #expect(font.contains(CSSDeclaration(property: "font-size", value: "14px")))
    #expect(font.contains(CSSDeclaration(property: "font-weight", value: "500")))
    #expect(font.contains(CSSDeclaration(property: "letter-spacing", value: "0.4px")))
    #expect(font.contains(CSSDeclaration(property: "line-height", value: "1.25")))
    #expect(font.contains(CSSDeclaration(property: "color", value: "var(--color-text)")))

    let textStyle = CSSEmitter.declarations(
        for: FontModifier(
            align: .justify,
            transform: .uppercase,
            decoration: .underline,
            wrap: .balance,
            whiteSpace: .preWrap,
            overflow: .ellipsis,
            overflowWrap: .anywhere,
            wordBreak: .breakAll,
            hyphens: .auto,
            lineClamp: 2,
            indent: 10
        )
    )
    #expect(textStyle.contains(CSSDeclaration(property: "text-align", value: "justify")))
    #expect(textStyle.contains(CSSDeclaration(property: "text-transform", value: "uppercase")))
    #expect(textStyle.contains(CSSDeclaration(property: "text-decoration", value: "underline")))
    #expect(textStyle.contains(CSSDeclaration(property: "text-wrap", value: "balance")))
    #expect(textStyle.contains(CSSDeclaration(property: "white-space", value: "pre-wrap")))
    #expect(textStyle.contains(CSSDeclaration(property: "text-overflow", value: "ellipsis")))
    #expect(textStyle.contains(CSSDeclaration(property: "overflow-wrap", value: "anywhere")))
    #expect(textStyle.contains(CSSDeclaration(property: "word-break", value: "break-all")))
    #expect(textStyle.contains(CSSDeclaration(property: "hyphens", value: "auto")))
    #expect(textStyle.contains(CSSDeclaration(property: "display", value: "-webkit-box")))
    #expect(textStyle.contains(CSSDeclaration(property: "-webkit-box-orient", value: "vertical")))
    #expect(textStyle.contains(CSSDeclaration(property: "-webkit-line-clamp", value: "2")))
    #expect(textStyle.contains(CSSDeclaration(property: "overflow", value: "hidden")))
    #expect(textStyle.contains(CSSDeclaration(property: "text-indent", value: "10px")))
}

@Test func emitterUtilityMappingsCoverEdgeFontFamilyAndFontWeightCases() {
    let padded = CSSEmitter.declarations(for: PaddingModifier(8, edges: [.top, .bottom, .leading, .trailing, .horizontal, .vertical]))
    let props = Set(padded.map(\.property))
    #expect(props.contains("padding-top"))
    #expect(props.contains("padding-bottom"))
    #expect(props.contains("padding-inline-start"))
    #expect(props.contains("padding-inline-end"))
    #expect(props.contains("padding-inline"))
    #expect(props.contains("padding-block"))

    let families: [FontFamily] = [.system, .sans, .mono, .serif, .brand, .custom("Acme", fallback: .system)]
    let mappedFamilies = families.map { CSSEmitter.declarations(for: FontModifier($0)).first?.value ?? "" }
    #expect(mappedFamilies[0] == "system-ui, -apple-system, sans-serif")
    #expect(mappedFamilies[1] == "var(--font-sans)")
    #expect(mappedFamilies[2] == "var(--font-mono)")
    #expect(mappedFamilies[3] == "var(--font-serif)")
    #expect(mappedFamilies[4] == "var(--font-brand)")
    #expect(mappedFamilies[5] == "\"Acme\", system-ui, -apple-system, sans-serif")

    let weights: [FontWeight] = [.thin, .light, .regular, .medium, .semibold, .bold, .black]
    let mappedWeights = weights.map { CSSEmitter.declarations(for: FontModifier(weight: $0)).first?.value ?? "" }
    #expect(mappedWeights == ["100", "300", "400", "500", "600", "700", "900"])
}

@Test func collectorCoversBuilderNodeVariants() {
    var collector = CSSCollector()

    collector.collect(from: EmptyNode())
    collector.collect(from: TextNode("literal"))
    collector.collect(from: OptionalNode<TextNode>(nil))
    collector.collect(from: OptionalNode(TextNode("has").padding(1)))

    let firstBranch = Stack {
        if true {
            TextNode("a").padding(2)
        } else {
            TextNode("no")
        }
    }
    let secondBranch = Stack {
        if false {
            TextNode("no")
        } else {
            TextNode("b").margin(3)
        }
    }
    collector.collect(from: firstBranch)
    collector.collect(from: secondBranch)

    collector.collect(from: ForEachNode([1, 2, 3]) { value in TextNode("\(value)").opacity(0.5) })
    let builtArray = Stack {
        for value in ["x", "y"] {
            TextNode(value).padding(4)
        }
    }
    collector.collect(from: builtArray)

    let css = collector.renderStylesheet()
    #expect(css.contains("padding: 1px"))
    #expect(css.contains("padding: 2px"))
    #expect(css.contains("margin: 3px"))
    #expect(css.contains("opacity: 0.5"))
    #expect(css.contains("padding: 4px"))
}

@Test func boxSizingEmitterCoversContentAndBorderBox() {
    let content = CSSEmitter.declarations(for: BoxSizingModifier(.contentBox))
    #expect(content == [CSSDeclaration(property: "box-sizing", value: "content-box")])

    let border = CSSEmitter.declarations(for: BoxSizingModifier(.borderBox))
    #expect(border == [CSSDeclaration(property: "box-sizing", value: "border-box")])
}
