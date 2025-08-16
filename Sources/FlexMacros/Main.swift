//
//  Main.swift
//  Flex
//
//  Created by Nils Grabenhorst on 4/6/25.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct FlexPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        FeatureMacro.self,
        OutletMacro.self,
        PresentationMacro.self,
        ActionMacro.self,
        FetchedMacro.self,
//        DestinationMacro.self,
    ]
}
