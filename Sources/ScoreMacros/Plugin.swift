import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct ScoreMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ActionMacro.self,
        ColorTokensMacro.self,
        ComponentMacro.self,
        ComputedMacro.self,
        StateMacro.self,
    ]
}
