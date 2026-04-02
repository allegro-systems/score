import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct ScoreMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ActionMacro.self,
        ColorTokensMacro.self,
        ComponentMacro.self,
        ComputedMacro.self,
        ControllerMacro.self,
        QueryMacro.self,
        RouteMacro.self,
        StateMacro.self,
        ThemeMacro.self,
    ]
}
