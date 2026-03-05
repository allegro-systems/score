import Score

struct Contact: Page {
    static let path = "/contact"

    var metadata: Metadata? {
        Metadata(title: "Contact", description: "Get in touch with the Acme team.")
    }

    var body: some Node {
        SiteHeader()
        Main {
            Section {
                Heading(.one) { Text { "Contact" } }
                Paragraph {
                    Text { "Get in touch with our team." }
                }
            }
            Section {
                Card {
                    CardContent {
                        Form(action: "/api/contact", method: .post) {
                            InputField(label: "Name", name: "name", placeholder: "Your name", required: true)
                            InputField(label: "Email", name: "email", type: .email, placeholder: "you@example.com", required: true)
                            Stack {
                                Label(for: "message") { Text { "Message" } }
                                TextArea(name: "message", placeholder: "How can we help?", rows: 5, id: "message", required: true)
                            }
                            StyledButton(.default, type: .submit) { Text { "Send Message" } }
                        }
                    }
                }
            }
        }
        SiteFooter()
    }
}
