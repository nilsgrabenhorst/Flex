//
//  OutletMacro.swift
//  Flex
//
//  Created by Nils Grabenhorst on 4/10/25.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftUI

public struct OutletMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
//        guard let variableDecl = declaration.as(VariableDeclSyntax.self) else {
//            // TODO: Diagnostic
//            return []
//        }
//        guard variableDecl.isStoredProperty(), variableDecl.isWritable else {
//            // TODO: Diagnostic
//            return []
//        }
//        guard let identifier = variableDecl.identifier,
//              let typeAnnotation = variableDecl.typeAnnotation
//        else {
//            // TODO: Diagnostic
//            return []
//        }
//        let type: TypeSyntax = typeAnnotation.type
//        guard let initializer = variableDecl.initializer else {
//            // TODO: Diagnostic
//            return []
//        }
        return [
//            DeclSyntax(
//                "@State private var \(identifier)Storage: \(type)= \(initializer)"
//            ),
//            DeclSyntax(
//                """
//                var $\(identifier): Binding<\(type)> {
//                    $\(identifier)Storage
//                }
//                """
//            )
        ]
    }
}

extension OutletMacro: AccessorMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingAccessorsOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.AccessorDeclSyntax] {
//        guard let variableDecl = declaration.as(VariableDeclSyntax.self) else {
//            // TODO: Diagnostic
//            return []
//        }
//        guard variableDecl.isStoredProperty(), variableDecl.isWritable else {
//            // TODO: Diagnostic
//            return []
//        }
//        guard let identifier = variableDecl.identifier
//        else {
//            // TODO: Diagnostic
//            return []
//        }
        return [
//            "get { \(identifier)Storage }",
//            "nonmutating set { \(identifier)Storage = newValue }"
        ]
    }
}

extension VariableDeclSyntax {
    var identifier: TokenSyntax? {
        guard bindings.count == 1 else {
            // TODO: Diagnostic
            return nil
        }
        let binding: PatternBindingSyntax = bindings.first!
        guard let pattern = binding.pattern.as((IdentifierPatternSyntax).self) else {
            // TODO: Diagnostic
            return nil
        }
        return pattern.identifier
    }
    
    var typeAnnotation: TypeAnnotationSyntax? {
        guard bindings.count == 1 else {
            // TODO: Diagnostic
            return nil
        }
        return bindings.first?.typeAnnotation
    }
    
    var initializer: ExprSyntax? {
        guard bindings.count == 1 else {
            return nil
        }
        guard let initializer = bindings.first?.initializer else {
            return nil
        }
        return initializer.value
    }
}
