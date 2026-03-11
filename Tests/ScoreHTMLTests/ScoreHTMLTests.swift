import Testing

@testable import ScoreHTML

// MARK: - Text and primitives

@Test func emptyNodeRendersNothing() {
    let html = HTMLRenderer().render(EmptyNode())
    #expect(html == "")
}

@Test func textNodeRendersContent() {
    let html = HTMLRenderer().render(TextNode("Hello, world!"))
    #expect(html == "Hello, world!")
}

@Test func textNodeEscapesEntities() {
    let html = HTMLRenderer().render(TextNode("<script>alert('xss')</script>"))
    #expect(html == "&lt;script&gt;alert('xss')&lt;/script&gt;")
}

@Test func lineBreakRendersVoidElement() {
    let html = HTMLRenderer().render(LineBreak())
    #expect(html == "<br>")
}

@Test func horizontalRuleRendersVoidElement() {
    let html = HTMLRenderer().render(HorizontalRule())
    #expect(html == "<hr>")
}

// MARK: - Headings

@Test func headingRendersCorrectLevel() {
    let renderer = HTMLRenderer()
    #expect(renderer.render(Heading(.one) { "Title" }) == "<h1>Title</h1>")
    #expect(renderer.render(Heading(.two) { "Sub" }) == "<h2>Sub</h2>")
    #expect(renderer.render(Heading(.six) { "Small" }) == "<h6>Small</h6>")
}

// MARK: - Layout nodes

@Test func stackRendersAsDiv() {
    let html = HTMLRenderer().render(Stack { TextNode("content") })
    #expect(html == "<div>content</div>")
}

@Test func mainRendersSemanticElement() {
    let html = HTMLRenderer().render(Main { TextNode("main") })
    #expect(html == "<main>main</main>")
}

@Test func sectionRendersSemanticElement() {
    let html = HTMLRenderer().render(Section { TextNode("s") })
    #expect(html == "<section>s</section>")
}

@Test func groupIsTransparent() {
    let html = HTMLRenderer().render(Group { TextNode("bare") })
    #expect(html == "bare")
}

// MARK: - Content nodes

@Test func paragraphRendersTag() {
    let html = HTMLRenderer().render(Paragraph { TextNode("text") })
    #expect(html == "<p>text</p>")
}

@Test func strongRendersTag() {
    let html = HTMLRenderer().render(Strong { TextNode("bold") })
    #expect(html == "<strong>bold</strong>")
}

@Test func emphasisRendersTag() {
    let html = HTMLRenderer().render(Emphasis { TextNode("em") })
    #expect(html == "<em>em</em>")
}

@Test func codeRendersTag() {
    let html = HTMLRenderer().render(Code { TextNode("var x = 1") })
    #expect(html == "<code>var x = 1</code>")
}

@Test func preformattedRendersTag() {
    let html = HTMLRenderer().render(Preformatted { TextNode("  spaced") })
    #expect(html == "<pre>  spaced</pre>")
}

// MARK: - Builder nodes

@Test func tupleNodeRendersChildren() {
    let html = HTMLRenderer().render(
        Stack {
            TextNode("a")
            TextNode("b")
        })
    #expect(html == "<div>ab</div>")
}

@Test func conditionalNodeRendersTrueBranch() {
    let show = true
    let html = HTMLRenderer().render(
        Stack {
            if show { TextNode("shown") }
        })
    #expect(html == "<div>shown</div>")
}

@Test func conditionalNodeRendersElseBranch() {
    let show = false
    let html = HTMLRenderer().render(
        Stack {
            if show {
                TextNode("true")
            } else {
                TextNode("false")
            }
        })
    #expect(html == "<div>false</div>")
}

@Test func forEachNodeRendersAllItems() {
    let items = ["x", "y", "z"]
    let html = HTMLRenderer().render(
        Stack {
            ForEachNode(items) { item in TextNode(item) }
        })
    #expect(html == "<div>xyz</div>")
}

// MARK: - Modified nodes

@Test func modifiedNodePassesThroughToContent() {
    let node = Stack { TextNode("hi") }.padding(8)
    let html = HTMLRenderer().render(node)
    #expect(html == "<div>hi</div>")
}

// MARK: - Controls

@Test func buttonDefaultTypeIsButton() {
    let html = HTMLRenderer().render(Button { TextNode("Click") })
    #expect(html.contains("<button"))
    #expect(html.contains("type=\"button\""))
    #expect(html.contains("Click"))
}

@Test func inputRendersVoidElement() {
    let html = HTMLRenderer().render(Input(type: .text, name: "q"))
    #expect(html.contains("<input"))
    #expect(html.contains("type=\"text\""))
    #expect(html.contains("name=\"q\""))
}

// MARK: - Media

@Test func imageRendersWithAlt() {
    let html = HTMLRenderer().render(Image(src: "/logo.png", alt: "Logo"))
    #expect(html.contains("<img"))
    #expect(html.contains("src=\"/logo.png\""))
    #expect(html.contains("alt=\"Logo\""))
}

// MARK: - Lists

@Test func unorderedListRendersItems() {
    let html = HTMLRenderer().render(
        UnorderedList {
            ListItem { TextNode("a") }
            ListItem { TextNode("b") }
        })
    #expect(html == "<ul><li>a</li><li>b</li></ul>")
}

@Test func orderedListRendersItems() {
    let html = HTMLRenderer().render(
        OrderedList {
            ListItem { TextNode("1") }
            ListItem { TextNode("2") }
        })
    #expect(html == "<ol><li>1</li><li>2</li></ol>")
}

// MARK: - Tables

@Test func tableRendersStructure() {
    let html = HTMLRenderer().render(
        Table {
            TableHead {
                TableRow {
                    TableHeaderCell { TextNode("Name") }
                }
            }
            TableBody {
                TableRow {
                    TableCell { TextNode("Alice") }
                }
            }
        }
    )
    #expect(html.contains("<table>"))
    #expect(html.contains("<thead>"))
    #expect(html.contains("<th>Name</th>"))
    #expect(html.contains("<tbody>"))
    #expect(html.contains("<td>Alice</td>"))
}

// MARK: - Interactive

@Test func linkRendersHref() {
    let html = HTMLRenderer().render(Link(to: "https://example.com") { TextNode("Click") })
    #expect(html.contains("href=\"https://example.com\""))
    #expect(html.contains("Click"))
}

@Test func detailsRendersDisclosure() {
    let html = HTMLRenderer().render(
        Details(summary: { Summary { TextNode("Toggle") } }) {
            Paragraph { TextNode("Body") }
        }
    )
    #expect(html.contains("<details>"))
    #expect(html.contains("<summary>Toggle</summary>"))
    #expect(html.contains("<p>Body</p>"))
}

// MARK: - HTML escaping

@Test func attributeValueIsEscaped() {
    let html = HTMLRenderer().render(Image(src: "/img.png", alt: "A \"quoted\" value"))
    #expect(html.contains("alt=\"A &quot;quoted&quot; value\""))
}

@Test func textContentAmpersandIsEscaped() {
    let html = HTMLRenderer().render(TextNode("a & b"))
    #expect(html == "a &amp; b")
}

// MARK: - Additional controls coverage

@Test func formRendersMethodActionEncodingAndID() {
    let html = HTMLRenderer().render(
        Form(action: "/submit", method: .post, encoding: .multipart, id: "profile-form") {
            Input(type: .email, name: "email", required: true)
        }
    )
    #expect(html.contains("<form"))
    #expect(html.contains("action=\"/submit\""))
    #expect(html.contains("method=\"post\""))
    #expect(html.contains("enctype=\"multipart/form-data\""))
    #expect(html.contains("id=\"profile-form\""))
}

@Test func selectOptionAndOptionGroupRenderAttributes() {
    let html = HTMLRenderer().render(
        Select(name: "country", id: "country", required: true, disabled: true, multiple: true) {
            Option(value: "uk", selected: true, disabled: true) { TextNode("United Kingdom") }
            OptionGroup(label: "Nordics", disabled: true) {
                Option(value: "se") { TextNode("Sweden") }
            }
        }
    )
    #expect(html.contains("<select"))
    #expect(html.contains("name=\"country\""))
    #expect(html.contains("id=\"country\""))
    #expect(html.contains("required"))
    #expect(html.contains("disabled"))
    #expect(html.contains("multiple"))
    #expect(html.contains("<option"))
    #expect(html.contains("value=\"uk\""))
    #expect(html.contains("selected"))
    #expect(html.contains("<optgroup"))
    #expect(html.contains("label=\"Nordics\""))
}

@Test func textAreaFieldsetLegendOutputAndDataListRender() {
    let html = HTMLRenderer().render(
        Fieldset(disabled: true) {
            Legend { TextNode("Profile") }
            Label(for: "bio") { TextNode("Bio") }
            TextArea(
                name: "bio",
                placeholder: "Tell us",
                value: "line <one>",
                rows: 4,
                columns: 60,
                id: "bio",
                required: true,
                disabled: true,
                readOnly: true
            )
            Output(for: "bio") { TextNode("ok") }
            DataList(id: "langs") {
                Option(value: "swift") { TextNode("Swift") }
            }
        }
    )
    #expect(html.contains("<fieldset disabled>"))
    #expect(html.contains("<legend>Profile</legend>"))
    #expect(html.contains("<label for=\"bio\">Bio</label>"))
    #expect(html.contains("<textarea"))
    #expect(html.contains("name=\"bio\""))
    #expect(html.contains("placeholder=\"Tell us\""))
    #expect(html.contains("rows=\"4\""))
    #expect(html.contains("cols=\"60\""))
    #expect(html.contains("readonly"))
    #expect(html.contains("line &lt;one&gt;"))
    #expect(html.contains("<output for=\"bio\">ok</output>"))
    #expect(html.contains("<datalist id=\"langs\">"))
}

@Test func progressAndMeterRenderNumericAttributes() {
    let progressHTML = HTMLRenderer().render(Progress(value: 0.5, max: 1.0))
    #expect(progressHTML == "<progress value=\"0.5\" max=\"1\"></progress>")

    let meterHTML = HTMLRenderer().render(Meter(value: 7.5, min: 0, max: 10, low: 2, high: 8, optimum: 1))
    #expect(meterHTML.contains("<meter"))
    #expect(meterHTML.contains("value=\"7.5\""))
    #expect(meterHTML.contains("min=\"0\""))
    #expect(meterHTML.contains("max=\"10\""))
    #expect(meterHTML.contains("low=\"2\""))
    #expect(meterHTML.contains("high=\"8\""))
    #expect(meterHTML.contains("optimum=\"1\""))
}

// MARK: - Additional media + semantic coverage

@Test func semanticContainersRenderExpectedTags() {
    let html = HTMLRenderer().render(
        Stack {
            Article { TextNode("a") }
            Header { TextNode("h") }
            Footer { TextNode("f") }
            Aside { TextNode("s") }
            Navigation { TextNode("n") }
        }
    )
    #expect(html.contains("<article>a</article>"))
    #expect(html.contains("<header>h</header>"))
    #expect(html.contains("<footer>f</footer>"))
    #expect(html.contains("<aside>s</aside>"))
    #expect(html.contains("<nav>n</nav>"))
}

@Test func mediaElementsRenderWithOptionalAttributes() {
    let html = HTMLRenderer().render(
        Figure {
            Picture {
                Source(src: "/hero.webp", type: "image/webp", media: "(min-width: 640px)")
                Image(src: "/hero.jpg", alt: "Hero", width: 640, height: 480, loading: .lazy, decoding: .async)
            }
            FigureCaption { TextNode("Caption") }
            Audio(src: "/track.mp3", showsControls: true, autoplays: true, loops: true, isMuted: true, preload: .metadata) {
                Track(src: "/track.vtt", kind: .captions, label: "English", languageCode: "en", isDefault: true)
            }
            Video(
                src: "/movie.mp4",
                showsControls: true,
                autoplays: true,
                loops: true,
                isMuted: true,
                preload: .auto,
                poster: "/poster.jpg",
                width: 1280,
                height: 720
            ) {
                Source(src: "/movie.webm", type: "video/webm")
            }
            Canvas(width: 300, height: 150) { TextNode("fallback") }
        }
    )

    #expect(html.contains("<figure>"))
    #expect(html.contains("<picture>"))
    #expect(html.contains("<source src=\"/hero.webp\" type=\"image/webp\" media=\"(min-width: 640px)\">"))
    #expect(html.contains("<img"))
    #expect(html.contains("loading=\"lazy\""))
    #expect(html.contains("decoding=\"async\""))
    #expect(html.contains("<figcaption>Caption</figcaption>"))
    #expect(html.contains("<audio"))
    #expect(html.contains("controls"))
    #expect(html.contains("autoplay"))
    #expect(html.contains("<track"))
    #expect(html.contains("default"))
    #expect(html.contains("<video"))
    #expect(html.contains("poster=\"/poster.jpg\""))
    #expect(html.contains("width=\"1280\""))
    #expect(html.contains("height=\"720\""))
    #expect(html.contains("<canvas width=\"300\" height=\"150\">fallback</canvas>"))
}

// MARK: - Additional high-coverage paths

@Test func textInlineAndBlockSemanticsRenderTags() {
    let html = HTMLRenderer().render(
        Stack {
            Text { TextNode("plain") }
            Small { TextNode("fine") }
            Mark { TextNode("hit") }
            Blockquote { TextNode("quote") }
            Address { TextNode("address") }
        }
    )
    #expect(html.contains("plain"))
    #expect(html.contains("<small>fine</small>"))
    #expect(html.contains("<mark>hit</mark>"))
    #expect(html.contains("<blockquote>quote</blockquote>"))
    #expect(html.contains("<address>address</address>"))
}

@Test func orderedAndDescriptionListsRenderAdvancedAttributes() {
    let ordered = HTMLRenderer().render(
        OrderedList(start: 3, isReversed: true) {
            ListItem { TextNode("third") }
            ListItem { TextNode("second") }
        }
    )
    #expect(ordered.contains("<ol"))
    #expect(ordered.contains("start=\"3\""))
    #expect(ordered.contains("reversed"))

    let description = HTMLRenderer().render(
        DescriptionList {
            DescriptionTerm { TextNode("Name") }
            DescriptionDetails { TextNode("Score") }
        }
    )
    #expect(description == "<dl><dt>Name</dt><dd>Score</dd></dl>")
}

@Test func tableRendersCaptionFooterColumnGroupAndScopes() {
    let html = HTMLRenderer().render(
        Table {
            TableCaption { TextNode("Stats") }
            TableColumnGroup(span: 2) {
                TableColumn(span: 1)
                TableColumn(span: 2)
            }
            TableHead {
                TableRow {
                    TableHeaderCell(scope: .column) { TextNode("Name") }
                    TableHeaderCell(scope: .row) { TextNode("Value") }
                }
            }
            TableBody {
                TableRow {
                    TableCell { TextNode("A") }
                    TableCell { TextNode("1") }
                }
            }
            TableFooter {
                TableRow {
                    TableCell { TextNode("Total") }
                    TableCell { TextNode("1") }
                }
            }
        }
    )

    #expect(html.contains("<caption>Stats</caption>"))
    #expect(html.contains("<colgroup span=\"2\">"))
    #expect(html.contains("<col span=\"1\">"))
    #expect(html.contains("<col span=\"2\">"))
    #expect(html.contains("scope=\"col\""))
    #expect(html.contains("scope=\"row\""))
    #expect(html.contains("<tfoot>"))
}

@Test func interactiveDialogMenuAndOpenDetailsRenderAttributes() {
    let dialog = HTMLRenderer().render(Dialog(open: true) { TextNode("d") })
    #expect(dialog.contains("<dialog open>"))

    let menu = HTMLRenderer().render(Menu { ListItem { TextNode("item") } })
    #expect(menu == "<menu><li>item</li></menu>")

    let details = HTMLRenderer().render(
        Details(open: true, summary: { Summary { TextNode("More") } }) {
            Paragraph { TextNode("Body") }
        }
    )
    #expect(details.contains("<details open>"))
    #expect(details.contains("<summary>More</summary>"))
}

@Test func builderArrayAndOptionalNilPathsRenderCorrectly() {
    let arrayBuilt = HTMLRenderer().render(
        Stack {
            for value in ["x", "y", "z"] {
                TextNode(value)
            }
        }
    )
    #expect(arrayBuilt == "<div>xyz</div>")

    let optionalValue: String? = nil
    let optionalBuilt = HTMLRenderer().render(
        Stack {
            if let optionalValue {
                TextNode(optionalValue)
            }
        }
    )
    #expect(optionalBuilt == "<div></div>")
}
