import Testing

@testable import ScoreCore

@Test func typographyModifiersStoreConfiguredValues() {
    let styled = TextNode("title").font(
        align: .justify,
        transform: .uppercase,
        decoration: .lineThrough,
        wrap: .pretty,
        whiteSpace: .preWrap,
        overflow: .ellipsis,
        overflowWrap: .anywhere,
        wordBreak: .breakAll,
        hyphens: .auto,
        lineClamp: 2,
        indent: 8
    )

    let style = styled.modifiers.first as? FontModifier
    #expect(style?.align == .justify)
    #expect(style?.transform == .uppercase)
    #expect(style?.decoration == .lineThrough)
    #expect(style?.wrap == .pretty)
    #expect(style?.whiteSpace == .preWrap)
    #expect(style?.overflow == .ellipsis)
    #expect(style?.overflowWrap == .anywhere)
    #expect(style?.wordBreak == .breakAll)
    #expect(style?.hyphens == .auto)
    #expect(style?.lineClamp == 2)
    #expect(style?.indent == 8)

    let fonted = TextNode("code").font(
        .custom("Acme", fallback: .mono),
        size: 13,
        weight: .semibold,
        tracking: 0.4,
        lineHeight: 1.3,
        color: .accent
    )
    let font = fonted.modifiers.first as? FontModifier
    #expect(font?.size == 13)
    #expect(font?.weight == .semibold)
    #expect(font?.tracking == 0.4)
    #expect(font?.lineHeight == 1.3)
    #expect(font?.color == .accent)

    #expect(TextDecoration.lineThrough.rawValue == "line-through")
    #expect(WhiteSpace.preWrap.rawValue == "pre-wrap")
    #expect(WordBreak.breakAll.rawValue == "break-all")
}

@Test func layoutItemAndTableListStyleModifiersStoreConfiguredValues() {
    let flexed = TextNode("x").flex(.column, gap: 12, align: .center, justify: .spaceBetween, wrap: true)
    let flex = flexed.modifiers.first as? FlexModifier
    #expect(flex?.direction == .column)
    #expect(flex?.gap == 12)
    #expect(flex?.align == .center)
    #expect(flex?.justify == .spaceBetween)
    #expect(flex?.wrap == true)

    let gridded = TextNode("x").grid(columns: 3, rows: 2, gap: 10, autoFlow: .rowDense)
    let grid = gridded.modifiers.first as? GridModifier
    #expect(grid?.columns == 3)
    #expect(grid?.rows == 2)
    #expect(grid?.gap == 10)
    #expect(grid?.autoFlow == .rowDense)

    let item = TextNode("x").flexItem(grow: 1, shrink: 0, basis: 180, order: 2, alignSelf: .end)
    let itemMod = item.modifiers.first as? FlexItemModifier
    #expect(itemMod?.grow == 1)
    #expect(itemMod?.shrink == 0)
    #expect(itemMod?.basis == 180)
    #expect(itemMod?.order == 2)
    #expect(itemMod?.alignSelf == .end)

    let placed = TextNode("x").gridPlacement(column: "1 / 3", row: "2", area: "main", justifySelf: .center, placeSelf: "center stretch")
    let place = placed.modifiers.first as? GridPlacementModifier
    #expect(place?.column == "1 / 3")
    #expect(place?.row == "2")
    #expect(place?.area == "main")
    #expect(place?.justifySelf == .center)
    #expect(place?.placeSelf == "center stretch")

    #expect(TextNode("x").hidden().modifiers.first is HiddenModifier)

    let listStyled = TextNode("x").listStyle(type: .decimal, position: .inside, image: "url('/bullet.svg')")
    let list = listStyled.modifiers.first as? ListStyleModifier
    #expect(list?.type == .decimal)
    #expect(list?.position == .inside)
    #expect(list?.image == "url('/bullet.svg')")

    let tableStyled = TextNode("x").tableStyle(layout: .fixed, borderCollapse: .collapse, borderSpacing: 6, captionSide: .bottom)
    let table = tableStyled.modifiers.first as? TableStyleModifier
    #expect(table?.layout == .fixed)
    #expect(table?.borderCollapse == .collapse)
    #expect(table?.borderSpacing == 6)
    #expect(table?.captionSide == .bottom)
}

@Test func motionScrollInteractionFilterAndMediaModifiersStoreConfiguredValues() {
    let transformed = TextNode("x").transform("rotate(45deg)")
    #expect((transformed.modifiers.first as? TransformModifier)?.value == "rotate(45deg)")

    let transitioned = TextNode("x").transition(property: "opacity", duration: 0.2, timing: "ease-in-out", delay: 0.1)
    let transition = transitioned.modifiers.first as? TransitionModifier
    #expect(transition?.property == "opacity")
    #expect(transition?.duration == 0.2)
    #expect(transition?.timing == "ease-in-out")
    #expect(transition?.delay == 0.1)

    let animated = TextNode("x").animation(name: "fade", duration: 0.3, timing: "ease", delay: 0.05, iterationCount: "2", direction: "alternate", fillMode: "forwards")
    let animation = animated.modifiers.first as? AnimationModifier
    #expect(animation?.name == "fade")
    #expect(animation?.duration == 0.3)
    #expect(animation?.timing == "ease")
    #expect(animation?.delay == 0.05)
    #expect(animation?.iterationCount == "2")
    #expect(animation?.direction == "alternate")
    #expect(animation?.fillMode == "forwards")

    let scrollBehavior = TextNode("x").scrollBehavior(.smooth)
    #expect((scrollBehavior.modifiers.first as? ScrollBehaviorModifier)?.behavior == .smooth)

    let scrollMargin = TextNode("x").scrollMargin(20)
    #expect((scrollMargin.modifiers.first as? ScrollMarginModifier)?.value == 20)

    let scrollPadding = TextNode("x").scrollPadding(16)
    #expect((scrollPadding.modifiers.first as? ScrollPaddingModifier)?.value == 16)

    let snap = TextNode("x").scrollSnap(type: .x, align: .center)
    #expect((snap.modifiers.first as? ScrollSnapModifier)?.type == .x)
    #expect((snap.modifiers.first as? ScrollSnapModifier)?.align == .center)

    #expect((TextNode("x").cursor(.grab).modifiers.first as? CursorModifier)?.style == .grab)
    #expect((TextNode("x").userSelect(.none).modifiers.first as? UserSelectModifier)?.mode == UserSelectMode.none)

    #expect((TextNode("x").filter("blur(2px)").modifiers.first as? FilterModifier)?.value == "blur(2px)")
    #expect((TextNode("x").backdropFilter("blur(10px)").modifiers.first as? BackdropFilterModifier)?.value == "blur(10px)")
    #expect((TextNode("x").blendMode("multiply").modifiers.first as? BlendModeModifier)?.value == "multiply")

    #expect((TextNode("x").objectFit(.cover).modifiers.first as? ObjectFitModifier)?.fit == .cover)
    #expect((TextNode("x").objectPosition("top center").modifiers.first as? ObjectPositionModifier)?.value == "top center")
    #expect(ObjectFit.scaleDown.rawValue == "scale-down")
}

@Test func nodeBuilderCorePathsProduceExpectedStructures() {
    let empty = NodeBuilder.buildBlock()
    _ = empty

    let expression = NodeBuilder.buildExpression("hello")
    #expect(expression.content == "hello")

    let optionalSome = NodeBuilder.buildOptional(TextNode("present"))
    #expect(optionalSome.wrapped?.content == "present")

    let optionalNone = NodeBuilder.buildOptional(Optional<TextNode>.none)
    #expect(optionalNone.wrapped == nil)

    let eitherFirst = NodeBuilder.buildEither(first: TextNode("left")) as ConditionalNode<TextNode, TextNode>
    let eitherSecond = NodeBuilder.buildEither(second: TextNode("right")) as ConditionalNode<TextNode, TextNode>
    switch eitherFirst.storage {
    case .first(let node):
        #expect(node.content == "left")
    case .second:
        #expect(Bool(false))
    }
    switch eitherSecond.storage {
    case .first:
        #expect(Bool(false))
    case .second(let node):
        #expect(node.content == "right")
    }

    let arrayNode = NodeBuilder.buildArray([TextNode("1"), TextNode("2")])
    #expect(arrayNode.children.map(\.content) == ["1", "2"])

    let forEach = ForEachNode([1, 2, 3]) { value in
        TextNode("item-\(value)")
    }
    #expect(forEach.data.count == 3)
    #expect(forEach.content(2).content == "item-2")
}

@Test func semanticListTableAndTextNodesPreserveInitializerState() {
    let ordered = OrderedList(start: 5, reversed: true) {
        ListItem { TextNode("step") }
    }
    #expect(ordered.start == 5)
    #expect(ordered.reversed == true)

    let headerCell = TableHeaderCell(scope: .column) { TextNode("Name") }
    #expect(headerCell.scope == .column)

    let columnGroup = TableColumnGroup(span: 2) { TableColumn(span: 1) }
    #expect(columnGroup.span == 2)

    let column = TableColumn(span: 3)
    #expect(column.span == 3)

    let text = Text(verbatim: "plain")
    #expect(text.content.content == "plain")

    _ = HorizontalRule()
    _ = LineBreak()

    #expect(TableHeaderScope.rowGroup.rawValue == "rowgroup")
    #expect(TableHeaderScope.columnGroup.rawValue == "colgroup")
}

@Test func mediaNodesPreserveInitializerState() {
    let literalImage = Image(src: "/hero.jpg", alt: "Hero", width: 1200, height: 800, loading: .lazy, decoding: .async)
    #expect(literalImage.src == "/hero.jpg")
    #expect(literalImage.alt == "Hero")
    #expect(literalImage.isLocalized == false)
    #expect(literalImage.width == 1200)
    #expect(literalImage.height == 800)
    #expect(literalImage.loading == .lazy)
    #expect(literalImage.decoding == .async)

    let localizedImage = Image(localized: "hero.image", alt: "Hero")
    #expect(localizedImage.src == "hero.image")
    #expect(localizedImage.isLocalized == true)

    let source = Source(src: "/clip.webm", type: "video/webm", media: "(min-width: 800px)")
    #expect(source.src == "/clip.webm")
    #expect(source.type == "video/webm")
    #expect(source.media == "(min-width: 800px)")

    let track = Track(src: "/captions.vtt", kind: .captions, label: "English", languageCode: "en", isDefault: true)
    #expect(track.kind == .captions)
    #expect(track.label == "English")
    #expect(track.languageCode == "en")
    #expect(track.isDefault == true)

    let audio = Audio(src: "/audio.mp3", controls: true, autoplay: false, loop: true, muted: true, preload: .metadata) {
        Source(src: "/audio.ogg", type: "audio/ogg")
    }
    #expect(audio.src == "/audio.mp3")
    #expect(audio.controls == true)
    #expect(audio.loop == true)
    #expect(audio.muted == true)
    #expect(audio.preload == .metadata)

    let video = Video(src: "/video.mp4", controls: true, autoplay: false, loop: false, muted: true, preload: .auto, poster: "/poster.jpg", width: 1280, height: 720) {
        Track(src: "/video.vtt")
    }
    #expect(video.src == "/video.mp4")
    #expect(video.poster == "/poster.jpg")
    #expect(video.width == 1280)
    #expect(video.height == 720)
    #expect(video.muted == true)

    let canvas = Canvas(width: 800, height: 600) { TextNode("fallback") }
    #expect(canvas.width == 800)
    #expect(canvas.height == 600)
}

@Test func applicationAndPageDefaultsAreApplied() {
    struct DemoPage: Page {
        static let path: String = "/demo"
        var body: some Node { TextNode("demo") }
    }

    struct DemoApp: Application {
        var pages: [any Page] { [DemoPage()] }
    }

    let page = DemoPage()
    #expect(DemoPage.path == "/demo")
    #expect(page.metadata == nil)

    let app = DemoApp()
    #expect(app.pages.count == 1)
    #expect(app.theme is DefaultTheme)
    #expect(app.metadata == nil)
    #expect(app.controllers.isEmpty)
}
