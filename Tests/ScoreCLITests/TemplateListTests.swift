import Testing

@testable import ScoreCLI

@Test func allTemplatesHaveSummaries() {
    for template in Template.allCases {
        #expect(!template.summary.isEmpty)
    }
}

@Test func allTemplatesHaveDescriptions() {
    for template in Template.allCases {
        #expect(template.description.contains("—"))
    }
}

@Test func templateRawValuesAreDirectoryNames() {
    for template in Template.allCases {
        #expect(template.directoryName == template.rawValue)
    }
}

@Test func templateInitFromRawValue() {
    #expect(Template(rawValue: "minimal") == .minimal)
    #expect(Template(rawValue: "blog") == .blog)
    #expect(Template(rawValue: "nonexistent") == nil)
}

@Test func templateCaseCount() {
    #expect(Template.allCases.count == 10)
}
