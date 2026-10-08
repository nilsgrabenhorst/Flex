//
//  LazyStateMacro.swift
//  Flex
//
//  Created by Nils Grabenhorst on 09.03.26.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftUI

public struct LazyStateMacro {
}

extension LazyStateMacro: AccessorMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingAccessorsOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.AccessorDeclSyntax] {
        guard let variableDecl = declaration.as(VariableDeclSyntax.self),
              let patternBinding: PatternBindingSyntax = variableDecl.bindings.first,
              let identifier = patternBinding.pattern
                                             .as(IdentifierPatternSyntax.self)?
                                             .identifier.text
        else {
            return []
        }
        
        guard let initializer = patternBinding.initializer?.value
        else {
            return []
        }
        
        return [
            AccessorDeclSyntax(stringLiteral:
                                """
                                get {
                                    guard let existingValue = \(identifier)Box.value else {
                                        let newValue = \(initializer)
                                        \(identifier)Box.value = newValue
                                        return newValue
                                    }
                                    return existingValue
                                }
                                """
                              )
        ]
    }
}

extension LazyStateMacro: PeerMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        guard let variableDecl = declaration.as(VariableDeclSyntax.self),
              let patternBinding: PatternBindingSyntax = variableDecl.bindings.first,
              let identifier = patternBinding.pattern
                                             .as(IdentifierPatternSyntax.self)?
                                             .identifier.text,
              let typeString = patternBinding.typeAnnotation?
                                             .type.as(IdentifierTypeSyntax.self)?
                                             .name.text
        else {
            return []
        }
        
//        guard let initializer = patternBinding.initializer?.value
//        else {
//            return []
//        }
        
        return [
//            """
//            private var _\(raw: identifier): \(raw: typeString) {
//                get {
//                    guard let existingValue = \(raw: identifier)Box.value else {
//                        let newValue = \(initializer)
//                        \(raw: identifier)Box.value = newValue
//                        return newValue
//                    }
//                    return existingValue
//                }
//                nonmutating set {
//                    \(raw: identifier)Box.value = newValue
//                }
//            }
//            """,
            
            """
            @MainActor
            var $\(raw: identifier): Binding<\(raw: typeString)> {
                Binding {
                    \(raw: identifier)
                } set: { [\(raw: identifier)Box] newValue in
                    \(raw: identifier)Box.value = newValue
                }
            }
            """,
            
            """
            private var \(raw: identifier)BoxState = State(initialValue: Box<\(raw: typeString)?>())
            """,
            
            """
            private var \(raw: identifier)Box: Box<\(raw: typeString)?> {
                \(raw: identifier)BoxState.wrappedValue
            }
            """,
        ]
    }
}
