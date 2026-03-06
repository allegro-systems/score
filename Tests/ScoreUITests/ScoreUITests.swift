import Testing

@testable import ScoreHTML
@testable import ScoreUI

// MARK: - Construction tests

@Test func accordionCanBeConstructed() {
    let accordion = Accordion {
        AccordionItem(title: "Item 1") {
            Text(verbatim: "Content 1")
        }
        AccordionItem(title: "Item 2", open: true) {
            Text(verbatim: "Content 2")
        }
    }
    _ = accordion
}

@Test func alertCanBeConstructed() {
    let alert = Alert(.destructive) {
        Text(verbatim: "Something went wrong")
    }
    _ = alert
}

@Test func avatarCanBeConstructed() {
    let avatar = Avatar(src: "/img/me.png", alt: "Me", fallback: "JD", size: .large)
    _ = avatar
}

@Test func badgeCanBeConstructed() {
    let badge = Badge(.success) { "Active" }
    _ = badge
}

@Test func breadcrumbCanBeConstructed() {
    let breadcrumb = Breadcrumb {
        BreadcrumbItem(label: "Home", href: "/")
        BreadcrumbItem(label: "Docs")
    }
    _ = breadcrumb
}

@Test func styledButtonCanBeConstructed() {
    let btn = StyledButton(.destructive, size: .large, type: .submit) {
        Text(verbatim: "Delete")
    }
    _ = btn
}

@Test func cardCanBeConstructed() {
    let card = Card {
        CardHeader {
            CardTitle { "Revenue" }
            CardDescription { "Last 30 days" }
        }
        CardContent {
            Text(verbatim: "$12,450")
        }
        CardFooter {
            Badge(.success) { "↑ 8.2%" }
        }
    }
    _ = card
}

@Test func checkboxCanBeConstructed() {
    let cb = Checkbox(name: "terms", label: "I accept", value: "yes", checked: true)
    let renderer = HTMLRenderer()
    let html = renderer.render(cb)
    #expect(html.contains("terms"))
    #expect(html.contains("I accept"))
    #expect(html.contains("checked"))
}

@Test func commandPaletteCanBeConstructed() {
    let palette = CommandPalette(open: true) {
        CommandGroup(heading: "Navigation") {
            CommandItem(label: "Dashboard", shortcut: "Cmd+D")
            CommandItem(label: "Settings")
        }
    }
    _ = palette
}

@Test func dialogBoxCanBeConstructed() {
    let dialog = DialogBox(open: true) {
        DialogHeader { Text(verbatim: "Confirm") }
        DialogBody { Paragraph { Text(verbatim: "Are you sure?") } }
        DialogFooter {
            StyledButton(.destructive) { Text(verbatim: "Yes") }
        }
    }
    _ = dialog
}

@Test func dropdownCanBeConstructed() {
    let dropdown = Dropdown(label: "Actions") {
        DropdownItem(label: "Edit", href: "/edit")
        DropdownItem(label: "Delete")
    }
    _ = dropdown
}

@Test func inputFieldCanBeConstructed() {
    let field = InputField(
        label: "Email",
        name: "email",
        type: .email,
        placeholder: "you@example.com",
        required: true,
        helperText: "We'll never share your email."
    )
    _ = field
}

@Test func formLabelCanBeConstructed() {
    let lbl = FormLabel(for: "name-input", required: true) {
        Text(verbatim: "Name")
    }
    _ = lbl
}

@Test func localePickerCanBeConstructed() {
    let picker = LocalePicker(
        selected: "en",
        locales: [
            LocaleOption(code: "en", label: "English"),
            LocaleOption(code: "fr", label: "Français"),
        ]
    )
    _ = picker
}

@Test func navBarCanBeConstructed() {
    let nav = NavBar {
        NavBarBrand { Text(verbatim: "Score") }
        NavBarContent {
            NavItem(href: "/", isActive: true) { Text(verbatim: "Home") }
            NavItem(href: "/docs") { Text(verbatim: "Docs") }
        }
    }
    _ = nav
}

@Test func paginationCanBeConstructed() {
    let pages = Pagination(currentPage: 3, totalPages: 10, baseURL: "/articles")
    let renderer = HTMLRenderer()
    let html = renderer.render(pages)
    #expect(html.contains("/articles"))
    #expect(html.contains("Previous"))
    #expect(html.contains("Next"))
}

@Test func progressBarCanBeConstructed() {
    let bar = ProgressBar(value: 65, max: 100, label: "Uploading...")
    _ = bar
}

@Test func radioGroupCanBeConstructed() {
    let group = RadioGroup(
        name: "size",
        legend: "Size",
        selected: "m",
        options: [
            RadioOption(value: "s", label: "Small"),
            RadioOption(value: "m", label: "Medium"),
            RadioOption(value: "l", label: "Large"),
        ]
    )
    _ = group
}

@Test func selectFieldCanBeConstructed() {
    let field = SelectField(
        label: "Country",
        name: "country",
        selected: "us",
        options: [
            SelectOption(value: "us", label: "United States"),
            SelectOption(value: "ca", label: "Canada"),
        ]
    )
    _ = field
}

@Test func separatorCanBeConstructed() {
    let sep = Separator()
    let vsep = Separator(.vertical)
    _ = sep
    _ = vsep
}

@Test func sheetCanBeConstructed() {
    let sheet = Sheet(.left, open: true) {
        Text(verbatim: "Side panel content")
    }
    _ = sheet
}

@Test func skeletonCanBeConstructed() {
    let skeleton = Skeleton(width: "200px", height: "16px")
    let renderer = HTMLRenderer()
    let html = renderer.render(skeleton)
    #expect(html.contains("200px"))
    #expect(html.contains("16px"))
}

@Test func sliderCanBeConstructed() {
    let slider = Slider(name: "volume", label: "Volume", min: "0", max: "100", value: "50")
    let renderer = HTMLRenderer()
    let html = renderer.render(slider)
    #expect(html.contains("Volume"))
    #expect(html.contains("volume"))
    #expect(html.contains("range"))
}

@Test func switchToggleCanBeConstructed() {
    let toggle = SwitchToggle(name: "darkMode", label: "Dark Mode", isOn: true)
    let renderer = HTMLRenderer()
    let html = renderer.render(toggle)
    #expect(html.contains("Dark Mode"))
    #expect(html.contains("darkMode"))
    #expect(html.contains("checked"))
}

@Test func dataTableCanBeConstructed() {
    let table = DataTable(
        columns: [
            DataColumn(header: "Name"),
            DataColumn(header: "Role"),
        ],
        caption: "Team"
    ) {
        TableRow {
            TableCell { "Alice" }
            TableCell { "Engineer" }
        }
    }
    _ = table
}

@Test func tabGroupCanBeConstructed() {
    let tabs = TabGroup {
        TabPanel(label: "Overview", isActive: true) {
            Text(verbatim: "Overview content")
        }
        TabPanel(label: "Settings") {
            Text(verbatim: "Settings content")
        }
    }
    _ = tabs
}

@Test func textareaFieldCanBeConstructed() {
    let field = TextareaField(
        label: "Message",
        name: "message",
        placeholder: "Write...",
        rows: 4
    )
    _ = field
}

@Test func toastCanBeConstructed() {
    let toast = Toast(.success) {
        Text(verbatim: "Saved!")
    }
    _ = toast
}

@Test func toggleCanBeConstructed() {
    let toggle = Toggle(label: "Bold", isPressed: true)
    _ = toggle
}

@Test func tooltipCanBeConstructed() {
    let tooltip = Tooltip(text: "Copy to clipboard", position: .bottom) {
        Button { Text(verbatim: "Copy") }
    }
    _ = tooltip
}

// MARK: - HTML rendering tests

@Test func cardRendersAsArticle() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        Card {
            CardContent {
                Text(verbatim: "Hello")
            }
        }
    )
    #expect(html.contains("<article>"))
    #expect(html.contains("</article>"))
    #expect(html.contains("Hello"))
}

@Test func cardCompositionRendersHeaderAndFooter() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        Card {
            CardHeader {
                CardTitle { "Title" }
                CardDescription { "Desc" }
            }
            CardContent {
                Text(verbatim: "Body")
            }
            CardFooter {
                Text(verbatim: "Footer")
            }
        }
    )
    #expect(html.contains("<header>"))
    #expect(html.contains("<h3>Title</h3>"))
    #expect(html.contains("<p>Desc</p>"))
    #expect(html.contains("Body"))
    #expect(html.contains("<footer>"))
    #expect(html.contains("Footer"))
}

@Test func alertRendersContent() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        Alert(.warning) {
            Text(verbatim: "Warning message")
        }
    )
    #expect(html.contains("Warning message"))
}

@Test func badgeRendersContent() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        Badge(.success) { "Active" }
    )
    #expect(html.contains("Active"))
}

@Test func breadcrumbRendersNav() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        Breadcrumb {
            BreadcrumbItem(label: "Home", href: "/")
            BreadcrumbItem(label: "Current")
        }
    )
    #expect(html.contains("<nav"))
    #expect(html.contains("<ol>"))
    #expect(html.contains("Home"))
    #expect(html.contains("Current"))
}

@Test func styledButtonRendersButton() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        StyledButton(.outline) {
            Text(verbatim: "Cancel")
        }
    )
    #expect(html.contains("<button"))
    #expect(html.contains("Cancel"))
}

@Test func checkboxRendersLabelAndInput() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        Checkbox(name: "agree", label: "I agree")
    )
    #expect(html.contains("<label"))
    #expect(html.contains("<input"))
    #expect(html.contains("I agree"))
}

@Test func inputFieldRendersLabelAndInput() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        InputField(label: "Email", name: "email", type: .email, placeholder: "you@example.com")
    )
    #expect(html.contains("<label"))
    #expect(html.contains("Email"))
    #expect(html.contains("<input"))
    #expect(html.contains("email"))
}

@Test func dialogBoxRendersDialog() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        DialogBox(open: true) {
            DialogHeader { Text(verbatim: "Title") }
            DialogBody { Text(verbatim: "Body") }
        }
    )
    #expect(html.contains("<dialog"))
    #expect(html.contains("Title"))
    #expect(html.contains("Body"))
}

@Test func navBarRendersHeaderAndNav() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        NavBar {
            NavBarBrand { Text(verbatim: "MySite") }
            NavBarContent {
                NavItem(href: "/") { Text(verbatim: "Home") }
            }
        }
    )
    #expect(html.contains("<header"))
    #expect(html.contains("<nav>"))
    #expect(html.contains("MySite"))
    #expect(html.contains("Home"))
}

@Test func separatorRendersHr() {
    let renderer = HTMLRenderer()
    let html = renderer.render(Separator())
    #expect(html.contains("<hr>"))
}

@Test func dataTableRendersFullStructure() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        DataTable(
            columns: [DataColumn(header: "Name")],
            caption: "People"
        ) {
            TableRow {
                TableCell { "Alice" }
            }
        }
    )
    #expect(html.contains("<table>"))
    #expect(html.contains("<caption>People</caption>"))
    #expect(html.contains("<thead>"))
    #expect(html.contains("<th"))
    #expect(html.contains("Name"))
    #expect(html.contains("<tbody>"))
    #expect(html.contains("Alice"))
}

@Test func toastRendersContent() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        Toast(.error) {
            Text(verbatim: "Failed")
        }
    )
    #expect(html.contains("Failed"))
}

@Test func tooltipRendersContent() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        Tooltip(text: "Help text") {
            Text(verbatim: "Hover me")
        }
    )
    #expect(html.contains("Hover me"))
    #expect(html.contains("Help text"))
}

// MARK: - Additional render tests (body coverage)

@Test func accordionRendersDetails() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        Accordion {
            AccordionItem(title: "FAQ 1", open: false) {
                Text(verbatim: "Answer 1")
            }
            AccordionItem(title: "FAQ 2", open: true) {
                Text(verbatim: "Answer 2")
            }
        }
    )
    #expect(html.contains("FAQ 1"))
    #expect(html.contains("FAQ 2"))
    #expect(html.contains("Answer 1"))
    #expect(html.contains("Answer 2"))
}

@Test func avatarRendersImage() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        Avatar(src: "/me.png", alt: "Me", fallback: "JD", size: .large)
    )
    #expect(html.contains("/me.png"))
    #expect(html.contains("Me"))
}

@Test func avatarRendersWithoutFallback() {
    let renderer = HTMLRenderer()
    let html = renderer.render(Avatar(src: "/img.png", alt: "User"))
    #expect(html.contains("/img.png"))
}

@Test func commandItemRendersWithShortcut() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        CommandItem(label: "Save", shortcut: "Cmd+S")
    )
    #expect(html.contains("Save"))
    #expect(html.contains("Cmd+S"))
}

@Test func commandItemRendersWithoutShortcut() {
    let renderer = HTMLRenderer()
    let html = renderer.render(CommandItem(label: "Open"))
    #expect(html.contains("Open"))
}

@Test func commandItemRendersDisabled() {
    let renderer = HTMLRenderer()
    let html = renderer.render(CommandItem(label: "Cut", disabled: true))
    #expect(html.contains("Cut"))
    #expect(html.contains("disabled"))
}

@Test func commandGroupRendersHeadingAndList() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        CommandGroup(heading: "File") {
            CommandItem(label: "New")
            CommandItem(label: "Open", shortcut: "Cmd+O")
        }
    )
    #expect(html.contains("File"))
    #expect(html.contains("New"))
    #expect(html.contains("Open"))
    #expect(html.contains("Cmd+O"))
}

@Test func commandPaletteRendersOpenDialog() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        CommandPalette(placeholder: "Search…", open: true) {
            CommandGroup(heading: "Nav") {
                CommandItem(label: "Dashboard")
            }
        }
    )
    #expect(html.contains("Search"))
    #expect(html.contains("Nav"))
    #expect(html.contains("Dashboard"))
}

@Test func commandPaletteRendersClosed() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        CommandPalette(open: false) {
            CommandGroup(heading: "Actions") {
                CommandItem(label: "Delete")
            }
        }
    )
    #expect(html.contains("Actions"))
}

@Test func dropdownItemRendersAsLink() {
    let renderer = HTMLRenderer()
    let html = renderer.render(DropdownItem(label: "Edit", href: "/edit"))
    #expect(html.contains("Edit"))
    #expect(html.contains("/edit"))
    #expect(html.contains("<a"))
}

@Test func dropdownItemRendersAsButton() {
    let renderer = HTMLRenderer()
    let html = renderer.render(DropdownItem(label: "Delete"))
    #expect(html.contains("Delete"))
    #expect(html.contains("<button"))
}

@Test func dropdownItemRendersDisabledButton() {
    let renderer = HTMLRenderer()
    let html = renderer.render(DropdownItem(label: "Disabled", disabled: true))
    #expect(html.contains("Disabled"))
    #expect(html.contains("disabled"))
}

@Test func dropdownRendersDetailsAndMenu() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        Dropdown(label: "Actions") {
            DropdownItem(label: "Edit", href: "/edit")
            DropdownItem(label: "Archive")
        }
    )
    #expect(html.contains("Actions"))
    #expect(html.contains("Edit"))
    #expect(html.contains("Archive"))
}

@Test func inputFieldRendersWithErrorText() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        InputField(label: "Name", name: "name", errorText: "Required field")
    )
    #expect(html.contains("Name"))
    #expect(html.contains("Required field"))
}

@Test func inputFieldRendersWithHelperText() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        InputField(label: "Username", name: "username", helperText: "Letters only")
    )
    #expect(html.contains("Username"))
    #expect(html.contains("Letters only"))
}

@Test func formLabelRendersLabel() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        FormLabel(for: "email-input", required: true) {
            Text(verbatim: "Email Address")
        }
    )
    #expect(html.contains("Email Address"))
    #expect(html.contains("<label"))
}

@Test func localePickerRendersSelectWithOptions() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        LocalePicker(
            selected: "en",
            locales: [
                LocaleOption(code: "en", label: "English"),
                LocaleOption(code: "fr", label: "Français"),
            ]
        )
    )
    #expect(html.contains("Language"))
    #expect(html.contains("English"))
    #expect(html.contains("Français"))
    #expect(html.contains("<select"))
}

@Test func navBarRendersWithoutBrand() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        NavBar {
            NavBarContent {
                NavItem(href: "/") { Text(verbatim: "Home") }
                NavItem(href: "/about") { Text(verbatim: "About") }
            }
        }
    )
    #expect(html.contains("<nav>"))
    #expect(html.contains("Home"))
    #expect(html.contains("About"))
}

@Test func paginationRendersFirstPage() {
    let renderer = HTMLRenderer()
    let html = renderer.render(Pagination(currentPage: 1, totalPages: 5, baseURL: "/posts"))
    // Previous is rendered but disabled on the first page.
    #expect(html.contains("Previous"))
    #expect(html.contains("data-state=\"disabled\""))
    #expect(html.contains("Next"))
    #expect(html.contains("?page=2"))
}

@Test func paginationRendersLastPage() {
    let renderer = HTMLRenderer()
    let html = renderer.render(Pagination(currentPage: 5, totalPages: 5, baseURL: "/posts"))
    #expect(html.contains("Previous"))
    // Next is rendered but disabled on the last page.
    #expect(html.contains("Next"))
    #expect(html.contains("?page=4"))
}

@Test func paginationRendersMiddlePage() {
    let renderer = HTMLRenderer()
    let html = renderer.render(Pagination(currentPage: 3, totalPages: 5, baseURL: "/posts"))
    #expect(html.contains("Previous"))
    #expect(html.contains("Next"))
    #expect(html.contains("?page=2"))
    #expect(html.contains("?page=4"))
}

@Test func progressBarRendersWithLabel() {
    let renderer = HTMLRenderer()
    let html = renderer.render(ProgressBar(value: 50, max: 100, label: "Loading…"))
    #expect(html.contains("Loading"))
    #expect(html.contains("<progress"))
}

@Test func progressBarRendersWithoutLabel() {
    let renderer = HTMLRenderer()
    let html = renderer.render(ProgressBar(value: 75, max: 100))
    #expect(html.contains("<progress"))
}

@Test func radioGroupRendersFieldset() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        RadioGroup(
            name: "plan",
            legend: "Choose plan",
            selected: "pro",
            options: [
                RadioOption(value: "free", label: "Free"),
                RadioOption(value: "pro", label: "Pro"),
            ]
        )
    )
    #expect(html.contains("<fieldset"))
    #expect(html.contains("Choose plan"))
    #expect(html.contains("Free"))
    #expect(html.contains("Pro"))
    #expect(html.contains("radio"))
}

@Test func selectFieldRendersLabelAndSelect() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        SelectField(
            label: "Role",
            name: "role",
            selected: "admin",
            options: [
                SelectOption(value: "user", label: "User"),
                SelectOption(value: "admin", label: "Admin"),
            ]
        )
    )
    #expect(html.contains("Role"))
    #expect(html.contains("<select"))
    #expect(html.contains("User"))
    #expect(html.contains("Admin"))
}

@Test func sheetRendersDialog() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        Sheet(.right, open: true) {
            Text(verbatim: "Drawer content")
        }
    )
    #expect(html.contains("Drawer content"))
    #expect(html.contains("<dialog"))
}

@Test func sheetRendersDifferentSides() {
    let renderer = HTMLRenderer()
    for side in [SheetSide.top, .bottom, .left, .right] {
        let html = renderer.render(Sheet(side) { Text(verbatim: "Content") })
        #expect(html.contains("Content"))
    }
}

@Test func skeletonRendersStack() {
    let renderer = HTMLRenderer()
    let html = renderer.render(Skeleton(width: "200px", height: "20px"))
    #expect(html.contains("<div"))
}

@Test func sliderRendersLabelAndInput() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        Slider(name: "brightness", label: "Brightness", min: "0", max: "100", value: "80")
    )
    #expect(html.contains("Brightness"))
    #expect(html.contains("<input"))
    #expect(html.contains("range"))
}

@Test func switchToggleRendersLabelAndCheckbox() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        SwitchToggle(name: "notifications", label: "Notifications", isOn: true)
    )
    #expect(html.contains("Notifications"))
    #expect(html.contains("<input"))
    #expect(html.contains("checkbox"))
}

@Test func tabGroupRendersTabs() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        TabGroup {
            TabPanel(label: "Tab A", isActive: true) {
                Text(verbatim: "Content A")
            }
            TabPanel(label: "Tab B") {
                Text(verbatim: "Content B")
            }
        }
    )
    #expect(html.contains("Content A"))
    #expect(html.contains("Content B"))
}

@Test func textareaFieldRendersWithHelperText() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        TextareaField(label: "Bio", name: "bio", helperText: "Max 500 chars")
    )
    #expect(html.contains("Bio"))
    #expect(html.contains("Max 500 chars"))
}

@Test func textareaFieldRendersWithErrorText() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        TextareaField(label: "Notes", name: "notes", errorText: "Too short")
    )
    #expect(html.contains("Notes"))
    #expect(html.contains("Too short"))
}

@Test func toggleRendersButton() {
    let renderer = HTMLRenderer()
    let html = renderer.render(Toggle(label: "Bold", isPressed: true))
    #expect(html.contains("Bold"))
    #expect(html.contains("<button"))
}

@Test func toggleRendersUnpressed() {
    let renderer = HTMLRenderer()
    let html = renderer.render(Toggle(label: "Italic", isPressed: false))
    #expect(html.contains("Italic"))
}

@Test func dialogFooterRendersFooter() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        DialogFooter {
            StyledButton(.destructive) { Text(verbatim: "Confirm") }
            StyledButton(.ghost) { Text(verbatim: "Cancel") }
        }
    )
    #expect(html.contains("<footer>"))
    #expect(html.contains("Confirm"))
    #expect(html.contains("Cancel"))
}

@Test func dataTableRendersWithoutCaption() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        DataTable(columns: [DataColumn(header: "ID"), DataColumn(header: "Name")]) {
            TableRow {
                TableCell { "1" }
                TableCell { "Alice" }
            }
        }
    )
    #expect(html.contains("<table>"))
    #expect(html.contains("ID"))
    #expect(html.contains("Alice"))
    #expect(!html.contains("<caption>"))
}

@Test func styledButtonVariants() {
    let renderer = HTMLRenderer()
    for variant in [ButtonVariant.default, .outline, .ghost, .destructive] {
        let html = renderer.render(StyledButton(variant) { Text(verbatim: "Click") })
        #expect(html.contains("Click"))
    }
}

@Test func styledButtonSizes() {
    let renderer = HTMLRenderer()
    for size in [ButtonSize.small, .medium, .large] {
        let html = renderer.render(StyledButton(.default, size: size) { Text(verbatim: "OK") })
        #expect(html.contains("OK"))
    }
}

@Test func alertRendersAllVariants() {
    let renderer = HTMLRenderer()
    for variant in [AlertVariant.info, .success, .warning, .destructive] {
        let html = renderer.render(Alert(variant) { Text(verbatim: "Message") })
        #expect(html.contains("Message"))
    }
}

@Test func toastRendersAllVariants() {
    let renderer = HTMLRenderer()
    for variant in [ToastVariant.info, .success, .warning, .error] {
        let html = renderer.render(Toast(variant) { Text(verbatim: "Notif") })
        #expect(html.contains("Notif"))
    }
}

@Test func badgeRendersAllVariants() {
    let renderer = HTMLRenderer()
    for variant in [BadgeVariant.default, .success, .warning, .destructive, .outline] {
        let html = renderer.render(Badge(variant) { "Label" })
        #expect(html.contains("Label"))
    }
}

// MARK: - Drag and drop tests

@Test func dragSourceCanBeConstructed() {
    let source = DragSource(id: "item-1") {
        Text(verbatim: "Draggable")
    }
    _ = source
}

@Test func dragSourceWithCustomType() {
    let source = DragSource(id: "task-42", type: "application/x-task") {
        Card { CardContent { Text(verbatim: "Task") } }
    }
    _ = source
}

@Test func dragSourceRendersWithDraggableAttribute() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        DragSource(id: "card-1") {
            Text(verbatim: "Drag me")
        }
    )
    #expect(html.contains("draggable=\"true\""))
    #expect(html.contains("Drag me"))
    #expect(html.contains("data-component=\"drag-source\""))
    #expect(html.contains("data-drag-id=\"card-1\""))
}

@Test func dropTargetCanBeConstructed() {
    let target = DropTarget {
        Text(verbatim: "Drop here")
    }
    _ = target
}

@Test func dropTargetWithCustomAccept() {
    let target = DropTarget(accept: "application/x-task") {
        Stack { Text(verbatim: "Task bin") }
    }
    _ = target
}

@Test func dropTargetRendersWithDataAttributes() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        DropTarget(accept: "text/plain") {
            Text(verbatim: "Drop zone")
        }
    )
    #expect(html.contains("Drop zone"))
    #expect(html.contains("data-component=\"drop-target\""))
    #expect(html.contains("data-accept-type=\"text/plain\""))
}

@Test func sortableCanBeConstructed() {
    let sortable = Sortable {
        DragSource(id: "a") { Text(verbatim: "First") }
        DragSource(id: "b") { Text(verbatim: "Second") }
    }
    _ = sortable
}

@Test func sortableWithHorizontalAxis() {
    let sortable = Sortable(axis: .horizontal) {
        DragSource(id: "col-1") { Text(verbatim: "Column 1") }
        DragSource(id: "col-2") { Text(verbatim: "Column 2") }
    }
    _ = sortable
}

@Test func sortableRendersWithDataAttributes() {
    let renderer = HTMLRenderer()
    let html = renderer.render(
        Sortable(axis: .vertical) {
            DragSource(id: "item-1") { Text(verbatim: "Item 1") }
            DragSource(id: "item-2") { Text(verbatim: "Item 2") }
        }
    )
    #expect(html.contains("data-component=\"sortable\""))
    #expect(html.contains("data-axis=\"vertical\""))
    #expect(html.contains("Item 1"))
    #expect(html.contains("Item 2"))
    #expect(html.contains("data-component=\"drag-source\""))
}
