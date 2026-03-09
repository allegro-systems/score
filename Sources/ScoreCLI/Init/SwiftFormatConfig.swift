import Foundation

/// Writes the standard `.swift-format` configuration to a project directory.
struct SwiftFormatConfig {

    private init() {}

    /// Writes `.swift-format` into the given directory.
    ///
    /// - Parameter directory: The project root directory.
    /// - Throws: An error if the file cannot be written.
    static func write(to directory: String) throws {
        let path = "\(directory)/.swift-format"
        try config.write(toFile: path, atomically: true, encoding: .utf8)
    }

    private static let config = """
        {
          "fileScopedDeclarationPrivacy" : {
            "accessLevel" : "private"
          },
          "indentation" : {
            "spaces" : 4
          },
          "indentConditionalCompilationBlocks" : false,
          "indentSwitchCaseLabels" : false,
          "lineBreakAroundMultilineExpressionChainComponents" : false,
          "lineBreakBeforeControlFlowKeywords" : false,
          "lineBreakBeforeEachArgument" : false,
          "lineBreakBeforeEachGenericRequirement" : false,
          "lineLength" : 180,
          "maximumBlankLines" : 1,
          "multiElementCollectionTrailingCommas" : true,
          "noAssignmentInExpressions" : {
            "allowedFunctions" : [
              "XCTAssertNoThrow"
            ]
          },
          "prioritizeKeepingFunctionOutputTogether" : false,
          "respectsExistingLineBreaks" : true,
          "rules" : {
            "AllPublicDeclarationsHaveDocumentation" : false,
            "AlwaysUseLowerCamelCase" : true,
            "AmbiguousTrailingClosureOverload" : false,
            "BeginDocumentationCommentWithOneLineSummary" : false,
            "DoNotUseSemicolons" : true,
            "DontRepeatTypeInStaticProperties" : true,
            "FileScopedDeclarationPrivacy" : true,
            "FullyIndirectEnum" : true,
            "GroupNumericLiterals" : true,
            "IdentifiersMustBeASCII" : true,
            "NeverForceUnwrap" : true,
            "NeverUseForceTry" : true,
            "NeverUseImplicitlyUnwrappedOptionals" : true,
            "NoAccessLevelOnExtensionDeclaration" : true,
            "NoAssignmentInExpressions" : true,
            "NoBlockComments" : false,
            "NoCasesWithOnlyFallthrough" : true,
            "NoEmptyTrailingClosureParentheses" : true,
            "NoLabelsInCasePatterns" : true,
            "NoLeadingUnderscores" : false,
            "NoParensAroundConditions" : true,
            "NoPlaygroundLiterals" : true,
            "NoVoidReturnOnFunctionSignature" : true,
            "OmitExplicitReturns" : true,
            "OneCasePerLine" : true,
            "OneVariableDeclarationPerLine" : true,
            "OnlyOneTrailingClosureArgument" : true,
            "OrderedImports" : true,
            "ReplaceForEachWithForLoop" : true,
            "ReturnVoidInsteadOfEmptyTuple" : true,
            "TypeNamesShouldBeCapitalized" : true,
            "UseEarlyExits" : true,
            "UseLetInEveryBoundCaseVariable" : true,
            "UseShorthandTypeNames" : true,
            "UseSingleLinePropertyGetter" : true,
            "UseSynthesizedInitializer" : true,
            "UseTripleSlashForDocumentationComments" : true,
            "UseWhereClausesInForLoops" : false,
            "ValidateDocumentationComments" : true
          },
          "spacesAroundRangeFormationOperators" : false,
          "tabWidth" : 2,
          "version" : 1
        }
        """
}
