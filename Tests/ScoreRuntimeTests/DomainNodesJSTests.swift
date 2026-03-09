import ScoreCore
import Testing

@testable import ScoreRuntime

// MARK: - Layout Container Nodes

private struct LayoutContainerPage: Page {
    static let path = "/layout-containers"
    var body: some Node {
        Stack {
            Main {
                Section {
                    Article {
                        Header { Navigation { Text(verbatim: "nav") } }
                        Footer { Aside { Group { Text(verbatim: "g") } } }
                    }
                }
            }
        }.on(.click, action: "go")
    }
}

@Test func layoutContainerNodesWalkForEvents() {
    let bindings = JSEmitter.extractEventBindings(from: LayoutContainerPage().body)
    #expect(bindings.count == 1)
    #expect(bindings[0].handler == "go")
}

// MARK: - Content Nodes

private struct ContentContainerPage: Page {
    static let path = "/content-containers"
    var body: some Node {
        Heading(.two) {
            Strong { Text(verbatim: "s") }
            Emphasis { Text(verbatim: "e") }
            Code { Text(verbatim: "c") }
            Small { Text(verbatim: "sm") }
            Mark { Text(verbatim: "m") }
        }.on(.click, action: "go")
        Paragraph { Text(verbatim: "p") }
        Preformatted { Text(verbatim: "pre") }
        Blockquote { Text(verbatim: "bq") }
        Address { Text(verbatim: "addr") }
        HorizontalRule()
        LineBreak()
    }
}

@Test func contentNodesWalkForEvents() {
    let bindings = JSEmitter.extractEventBindings(from: ContentContainerPage().body)
    #expect(bindings.count == 1)
    #expect(bindings[0].event == "click")
}

// MARK: - Form Control Nodes

private struct FormControlPage: Page {
    static let path = "/form-controls"
    var body: some Node {
        Form(action: "/submit", method: .post) {
            Fieldset {
                Legend { Text(verbatim: "legend") }
                Input(type: .text)
            }.on(.submit, action: "go")
            Select {
                Option(value: "a") { Text(verbatim: "A") }
            }
        }
    }
}

@Test func formControlNodesWalkForEvents() {
    let bindings = JSEmitter.extractEventBindings(from: FormControlPage().body)
    #expect(bindings.count == 1)
    #expect(bindings[0].handler == "go")
}

// MARK: - List Nodes

private struct ListContainerPage: Page {
    static let path = "/list-containers"
    var body: some Node {
        UnorderedList {
            ListItem { Text(verbatim: "a") }.on(.click, action: "go")
        }
        OrderedList {
            ListItem { Text(verbatim: "b") }
        }
        DescriptionList {
            DescriptionTerm { Text(verbatim: "dt") }
            DescriptionDetails { Text(verbatim: "dd") }
        }
    }
}

@Test func listNodesWalkForEvents() {
    let bindings = JSEmitter.extractEventBindings(from: ListContainerPage().body)
    #expect(bindings.count == 1)
    #expect(bindings[0].handler == "go")
}

// MARK: - Table Nodes

private struct TableContainerPage: Page {
    static let path = "/table-containers"
    var body: some Node {
        Table {
            TableCaption { Text(verbatim: "cap") }
            TableColumnGroup { TableColumn() }
            TableHead {
                TableRow { TableHeaderCell { Text(verbatim: "th") } }
            }
            TableBody {
                TableRow { TableCell { Text(verbatim: "td") }.on(.click, action: "go") }
            }
            TableFooter {
                TableRow { TableCell { Text(verbatim: "tf") } }
            }
        }
    }
}

@Test func tableNodesWalkForEvents() {
    let bindings = JSEmitter.extractEventBindings(from: TableContainerPage().body)
    #expect(bindings.count == 1)
    #expect(bindings[0].handler == "go")
}

// MARK: - Media and Interactive Nodes

private struct MediaInteractivePage: Page {
    static let path = "/media-interactive"
    var body: some Node {
        Figure {
            Image(src: "/i.png", alt: "img")
            FigureCaption { Text(verbatim: "cap") }
        }.on(.click, action: "go")
        Link(to: "/about") { Text(verbatim: "link") }
    }
}

@Test func mediaAndInteractiveNodesWalkForEvents() {
    let bindings = JSEmitter.extractEventBindings(from: MediaInteractivePage().body)
    #expect(bindings.count == 1)
    #expect(bindings[0].handler == "go")
}

// MARK: - JSEmitter Double State

private struct DoubleStatePage: Page {
    static let path = "/double-state"
    @State var price = 9.99
    var body: some Node { Text(verbatim: "price") }
}

@Test func doubleStateFormatsAsJSNumber() {
    let states = JSEmitter.extractStates(from: DoubleStatePage())
    #expect(states.count == 1)
    #expect(states[0].name == "price")
    #expect(states[0].initialValue == "9.99")
}

// MARK: - Composite Component Body Walk

private struct InnerEventComponent: Component {
    var body: some Node {
        Text(verbatim: "inner").on(.click, action: "handleInner")
    }
}

private struct CompositeComponentPage: Page {
    static let path = "/composite-component"
    @State var x = 0
    var body: some Node {
        InnerEventComponent()
    }
}

@Test func compositeComponentBodyIsWalked() {
    let bindings = JSEmitter.extractEventBindings(from: CompositeComponentPage().body)
    #expect(bindings.count == 1)
    #expect(bindings[0].handler == "handleInner")
}

// MARK: - Event-Only Page (no reactive properties)

private struct EventOnlyPage: Page {
    static let path = "/event-only"
    var body: some Node {
        Button { Text(verbatim: "click me") }
            .on(.click, action: "doSomething")
    }
}

@Test func eventOnlyPageEmitsScript() {
    let script = JSEmitter.emit(page: EventOnlyPage(), environment: .development)
    #expect(!script.isEmpty)
    #expect(script.contains("addEventListener(\"click\", doSomething)"))
}

// MARK: - Extended Form Control Nodes

private struct ExtendedFormControlPage: Page {
    static let path = "/extended-form-controls"
    var body: some Node {
        Label(for: "qty") { Text(verbatim: "Qty") }.on(.click, action: "go")
        Select {
            OptionGroup(label: "Group A") {
                Option(value: "a") { Text(verbatim: "A") }
            }
        }
        TextArea(name: "notes")
        Output(for: nil) { Text(verbatim: "result") }
        DataList(id: "cities") {
            Option(value: "NYC") { Text(verbatim: "New York") }
        }
        Progress(value: 0.5, max: 1.0)
        Meter(value: 7, min: 0, max: 10)
    }
}

@Test func extendedFormControlNodesWalkForEvents() {
    let bindings = JSEmitter.extractEventBindings(from: ExtendedFormControlPage().body)
    #expect(bindings.count == 1)
    #expect(bindings[0].handler == "go")
}

// MARK: - Interactive Nodes

private struct InteractiveNodePage: Page {
    static let path = "/interactive-nodes"
    var body: some Node {
        Dialog {
            Text(verbatim: "dialog content")
        }.on(.click, action: "openDialog")
        Menu {
            Button { Text(verbatim: "action") }
        }
        Details(
            summary: { Summary { Text(verbatim: "toggle") } },
            content: { Text(verbatim: "body") }
        )
    }
}

@Test func interactiveNodesWalkForEvents() {
    let bindings = JSEmitter.extractEventBindings(from: InteractiveNodePage().body)
    #expect(bindings.count == 1)
    #expect(bindings[0].handler == "openDialog")
}

// MARK: - Media Nodes

private struct MediaNodePage: Page {
    static let path = "/media-nodes"
    var body: some Node {
        Audio(src: "/a.mp3") {
            Source(src: "/a.ogg", type: "audio/ogg")
            Track(src: "/a.vtt")
        }.on(.click, action: "go")
        Video(src: "/v.mp4") {
            Source(src: "/v.webm", type: "video/webm")
        }
        Picture {
            Source(src: "/img.webp", type: "image/webp")
            Image(src: "/img.jpg", alt: "img")
        }
        Canvas(width: 400, height: 300) {
            Text(verbatim: "fallback")
        }
    }
}

@Test func mediaNodesWalkForEvents() {
    let bindings = JSEmitter.extractEventBindings(from: MediaNodePage().body)
    #expect(bindings.count == 1)
    #expect(bindings[0].handler == "go")
}
