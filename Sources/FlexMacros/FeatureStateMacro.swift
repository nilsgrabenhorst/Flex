//
//  FeatureStateMacro.swift
//  Flex
//
//  Created by Nils Grabenhorst on 28.10.25.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftUI

public enum FeatureStateMacro {}

extension FeatureStateMacro: PeerMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
              let binding = varDecl.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.trimmed,
              binding.accessorBlock == nil
        else {
            return []
        }
        
        guard let typeString = binding.typeString
        else {
            context.diagnose(Diagnostic(node: declaration, message: FeatureMacroDiagnostic.typeAnnotationMissing))
            return []
        }
        
        return [
            """
            private var \(identifier)BoxState = State(initialValue: Box<\(raw: typeString)?>())
            """,
            
            """
            private var \(identifier)Box: Box<\(raw: typeString)?> {
                \(identifier)BoxState.wrappedValue
            }
            """,
            
            """
            var $\(identifier): Binding<\(raw: typeString)> {
                Binding {
                    \(identifier)
                } set: { newValue in
                    self.\(identifier)Box.value = newValue
                }
            }
            """
        ]
    }
}

extension FeatureStateMacro: AccessorMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingAccessorsOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.AccessorDeclSyntax] {
        
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
              let binding = varDecl.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.trimmed,
              binding.accessorBlock == nil
        else {
            return []
        }
        
        guard let initializer = binding.initializer?.value
        else {
            context.diagnose(Diagnostic(node: declaration, message: FeatureMacroDiagnostic.initializerExpected))
            return []
        }
        
        return [
            """
            get {
                guard let \(identifier) = \(identifier)Box.value else {
                    let \(identifier) = \(initializer)
                    self.\(identifier)Box.value = \(identifier)
                    return \(identifier)
                }
                return \(identifier)
            }
            """
        ]
    }
}

extension PatternBindingSyntax {
    var typeString: String? {
        if let typeAnnotation {
            return typeAnnotation.type.trimmed.description
        }
        if let initializerCallee = self.initializer?.value
            .as(FunctionCallExprSyntax.self)?
            .calledExpression
            .as(DeclReferenceExprSyntax.self)?
            .trimmed
        {
            return initializerCallee.description
        }
        return nil
    }
}
