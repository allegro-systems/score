import Testing

@testable import ScoreCore

// MARK: - Path normalization

@Test func normalizedPathTrimsAndPrefixesSlash() {
    #expect(" users ".normalized() == "/users")
    #expect("/users".normalized() == "/users")
    #expect("\n\t".normalized() == "/")
}

// MARK: - Routing

@Test func routeInitializersNormalizePaths() {
    let a = Route(method: .get, path: " users ")
    #expect(a.path == "/users")

    let b = Route(method: .post)
    #expect(b.path == "/")
}

@Test func typedRouteHandlerSucceedsForMatchingRequestType() async throws {
    let route = Route(method: .get, path: "echo") { (request: String) async throws -> Int in
        request.count
    }

    let response = try await route.handler?("hello")
    let typed = response as? Int
    #expect(typed == 5)
}

@Test func typedRouteHandlerThrowsOnTypeMismatch() async {
    let route = Route(method: .get, path: "echo") { (request: String) async throws -> Int in
        request.count
    }

    do {
        _ = try await route.handler?(123)
        #expect(Bool(false), "Expected requestTypeMismatch")
    } catch let Route.HandlerInvocationError.requestTypeMismatch(expected, actual) {
        #expect(expected.contains("String"))
        #expect(actual.contains("Int"))
    } catch {
        #expect(Bool(false), "Unexpected error type: \(error)")
    }
}

@Test func controllerConformanceCarriesBaseAndRoutes() {
    struct DemoController: Controller {
        let base: String = "/demo"
        let routes: [Route] = [Route(method: .get, path: "index")]
    }

    let controller = DemoController()
    #expect(controller.base == "/demo")
    #expect(controller.routes.count == 1)
    #expect(controller.routes[0].path == "/index")
}

// MARK: - Accessibility modifier

@Test func accessibilityModifierStoresAllFields() {
    let mod = AccessibilityModifier(label: "Avatar", isHidden: true, role: "img")
    #expect(mod.label == "Avatar")
    #expect(mod.isHidden == true)
    #expect(mod.role == "img")
}

@Test func nodeAccessibilityExtensionWrapsModifier() {
    let node = TextNode("x").accessibility(label: "label", hidden: false, role: "note")
    #expect(node.modifiers.count == 1)

    let mod = node.modifiers[0] as? AccessibilityModifier
    #expect(mod?.label == "label")
    #expect(mod?.isHidden == false)
    #expect(mod?.role == "note")
}

// MARK: - Responsive modifiers

@Test func responsiveEnumsExposeExpectedCases() {
    let breakpoints: [Breakpoint] = [.compact, .wide, .tablet, .large, .desktop, .cinema]
    #expect(breakpoints.count == 6)

    let schemes: [ColorScheme] = [.light, .dark]
    #expect(schemes.count == 2)
}

@Test func breakpointAndSchemeModifierInitializersStoreState() {
    let bp = BreakpointModifier(.desktop, content: TextNode("d"))
    #expect(bp.breakpoint == .desktop)

    let cs = ColorSchemeModifier(.dark, content: TextNode("x"))
    #expect(cs.scheme == .dark)

    let theme = NamedThemeModifier("brand", content: TextNode("x"))
    #expect(theme.name == "brand")
}

@Test func responsiveNodeExtensionsAttachCorrectModifiers() {
    let base = TextNode("x")

    let compact = base.compact { $0 }
    let compactMod = compact.modifiers[0] as? BreakpointModifier<TextNode>
    #expect(compactMod?.breakpoint == .compact)

    let wide = base.wide { $0 }
    let wideMod = wide.modifiers[0] as? BreakpointModifier<TextNode>
    #expect(wideMod?.breakpoint == .wide)

    let tablet = base.tablet { $0 }
    let tabletMod = tablet.modifiers[0] as? BreakpointModifier<TextNode>
    #expect(tabletMod?.breakpoint == .tablet)

    let large = base.large { $0 }
    let largeMod = large.modifiers[0] as? BreakpointModifier<TextNode>
    #expect(largeMod?.breakpoint == .large)

    let desktop = base.desktop { $0 }
    let desktopMod = desktop.modifiers[0] as? BreakpointModifier<TextNode>
    #expect(desktopMod?.breakpoint == .desktop)

    let cinema = base.cinema { $0 }
    let cinemaMod = cinema.modifiers[0] as? BreakpointModifier<TextNode>
    #expect(cinemaMod?.breakpoint == .cinema)

    let light = base.light { $0 }
    let lightMod = light.modifiers[0] as? ColorSchemeModifier<TextNode>
    #expect(lightMod?.scheme == .light)

    let dark = base.dark { $0 }
    let darkMod = dark.modifiers[0] as? ColorSchemeModifier<TextNode>
    #expect(darkMod?.scheme == .dark)

    let themed = base.theme("brand") { $0 }
    let themeMod = themed.modifiers[0] as? NamedThemeModifier<TextNode>
    #expect(themeMod?.name == "brand")
}

// MARK: - Border modifiers

@Test func borderModifierAndNodeOverloadsStoreEdgesAndRadius() {
    let direct = BorderModifier(width: 1, color: .accent, style: .solid, radius: 4, edges: [.top, .leading])
    #expect(direct.width == 1)
    #expect(direct.color == .accent)
    #expect(direct.style == .solid)
    #expect(direct.radius == 4)
    #expect(direct.edges == [.top, .leading])

    let vararg = TextNode("x").border(width: 2, color: .text, style: .dashed, radius: 6, at: .bottom)
    let varargMod = vararg.modifiers[0] as? BorderModifier
    #expect(varargMod?.edges == [.bottom])

    let arrayEdges = TextNode("x").border(width: 2, color: .text, style: .dashed, radius: 6, at: [.top, .trailing])
    let arrayMod = arrayEdges.modifiers[0] as? BorderModifier
    #expect(arrayMod?.edges == [.top, .trailing])

    let allEdges = TextNode("x").border(width: 1, color: .text, style: .solid, at: [])
    let allEdgesMod = allEdges.modifiers[0] as? BorderModifier
    #expect(allEdgesMod?.edges == nil)
}

// MARK: - Sizing modifiers

@Test func sizingExtensionsCreateExpectedModifierValues() {
    let sized = TextNode("x").size(width: 320, height: 200, minWidth: 100, minHeight: 80, maxWidth: 500, maxHeight: 400)
    let sizeMod = sized.modifiers[0] as? SizeModifier
    #expect(sizeMod?.width == 320)
    #expect(sizeMod?.height == 200)
    #expect(sizeMod?.minWidth == 100)
    #expect(sizeMod?.minHeight == 80)
    #expect(sizeMod?.maxWidth == 500)
    #expect(sizeMod?.maxHeight == 400)

    let aspect = TextNode("x").aspectRatio(16.0 / 9.0)
    let aspectMod = aspect.modifiers[0] as? AspectRatioModifier
    #expect(aspectMod?.ratio == 16.0 / 9.0)
}

// MARK: - Position modifiers

@Test func positionAndZIndexExtensionsStoreValues() {
    let positioned = TextNode("x").position(.absolute, top: 1, bottom: 2, leading: 3, trailing: 4)
    let posMod = positioned.modifiers[0] as? PositionModifier
    #expect(posMod?.mode == .absolute)
    #expect(posMod?.top == 1)
    #expect(posMod?.bottom == 2)
    #expect(posMod?.leading == 3)
    #expect(posMod?.trailing == 4)

    let z = TextNode("x").zIndex(10)
    let zMod = z.modifiers[0] as? ZIndexModifier
    #expect(zMod?.value == 10)
}

// MARK: - Display/Overflow modifiers

@Test func displayAndOverflowExtensionsStoreModes() {
    let display = TextNode("x").display(.inlineBlock)
    let displayMod = display.modifiers[0] as? DisplayModifier
    #expect(displayMod?.mode == .inlineBlock)

    let both = TextNode("x").overflow(.hidden)
    let bothMod = both.modifiers[0] as? OverflowModifier
    #expect(bothMod?.x == .hidden)
    #expect(bothMod?.y == .hidden)

    let split = TextNode("x").overflow(x: .auto, y: .scroll)
    let splitMod = split.modifiers[0] as? OverflowModifier
    #expect(splitMod?.x == .auto)
    #expect(splitMod?.y == .scroll)
}

// MARK: - Spacing modifiers

@Test func spacingExtensionsCoverAllOverloads() {
    let uniformPadding = TextNode("x").padding(8)
    let uniformPaddingMod = uniformPadding.modifiers[0] as? PaddingModifier
    #expect(uniformPaddingMod?.value == 8)
    #expect(uniformPaddingMod?.edges == nil)

    let singlePadding = TextNode("x").padding(4, at: .top)
    let singlePaddingMod = singlePadding.modifiers[0] as? PaddingModifier
    #expect(singlePaddingMod?.edges == [.top])

    let arrayPadding = TextNode("x").padding(6, at: [.leading, .trailing])
    let arrayPaddingMod = arrayPadding.modifiers[0] as? PaddingModifier
    #expect(arrayPaddingMod?.edges == [.leading, .trailing])

    let variadicPadding = TextNode("x").padding(10, at: .horizontal, .vertical)
    let variadicPaddingMod = variadicPadding.modifiers[0] as? PaddingModifier
    #expect(variadicPaddingMod?.edges == [.horizontal, .vertical])

    let uniformMargin = TextNode("x").margin(8)
    let uniformMarginMod = uniformMargin.modifiers[0] as? MarginModifier
    #expect(uniformMarginMod?.value == 8)
    #expect(uniformMarginMod?.edges == nil)

    let singleMargin = TextNode("x").margin(4, at: .bottom)
    let singleMarginMod = singleMargin.modifiers[0] as? MarginModifier
    #expect(singleMarginMod?.edges == [.bottom])

    let arrayMargin = TextNode("x").margin(6, at: [.top, .bottom])
    let arrayMarginMod = arrayMargin.modifiers[0] as? MarginModifier
    #expect(arrayMarginMod?.edges == [.top, .bottom])

    let variadicMargin = TextNode("x").margin(10, at: .leading, .trailing)
    let variadicMarginMod = variadicMargin.modifiers[0] as? MarginModifier
    #expect(variadicMarginMod?.edges == [.leading, .trailing])
}
