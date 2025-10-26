//
//  ChangeObservingMacro.swift
//  Flex
//
//  Created by Nils Grabenhorst on 23.10.25.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftUI

//public enum ChangeObservingMacro {}

// MARK: - Peer
//extension ChangeObservingMacro: PeerMacro {
//    public static func expansion(
//        of node: AttributeSyntax,
//        providingPeersOf declaration: some DeclSyntaxProtocol,
//        in context: some MacroExpansionContext
//    ) throws -> [DeclSyntax] {
//        guard let variableDecl = declaration.as(VariableDeclSyntax.self) else {
//            context.diagnose(
//                Diagnostic(
//                    node: declaration,
//                    message: FeatureMacroDiagnostic.notAVariable
//                )
//            )
//            return []
//        }
//        
//        
//        
//        return [
//        ]
//    }
//}

// MARK: - Body

///
/// Rewrite the `body` getter, attaching `onChange(of:perform:)` modifiers that update the viewModel
///
/// - Warning Body macros currently don't work for variables
///   We could manually attach `@ChangeObserving` to the getter of the `var`, but only if it's written explicitly with the `get { ... }` syntax.
///   Nobody does that for `body` properties of `View`s though—everybody uses the shorthand syntax. We cannot "upgrade" the shorthand
///   syntax to the full getter syntax with our macro, and we also have no way to use a macro to add another macro annotation to the expanded
///   getter.
///
/// Conclusion: This idea is a dead end until the macro issue is fixed.
///
/// Ticket: https://github.com/swiftlang/swift/issues/75715
///
/*
extension ChangeObservingMacro: BodyMacro {
    
    public static func expansion(of node: AttributeSyntax,
                                 providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
                                 in context: some MacroExpansionContext) throws -> [CodeBlockItemSyntax] {
        let decl = declaration
        
//        guard let variableDecl = declaration.as(VariableDeclSyntax.self) else {
//            context.diagnose(
//                Diagnostic(
//                    node: declaration,
//                    message: FeatureMacroDiagnostic.notAVariable
//                )
//            )
//            return []
//        }
        
        return [
            """
            {}
            """
        ]
    }
}
*/
