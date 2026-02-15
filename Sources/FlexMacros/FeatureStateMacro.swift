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
        guard let funcDecl = declaration.as(FunctionDeclSyntax.self)
        else {
            return []
        }
        
        let signature = funcDecl.signature
        let parameterClause = signature.parameterClause
        guard parameterClause.parameters.isEmpty else {
            context.diagnose(Diagnostic(node: declaration, message: FeatureMacroDiagnostic.shouldHaveNoParameters))
            return []
        }
        
        guard let returnClause = signature.returnClause else {
            context.diagnose(Diagnostic(node: declaration, message: FeatureMacroDiagnostic.shouldReturnValue))
            return []
        }
        let typeString = returnClause.type.trimmed.description
        
//        let stateAttribute: AttributeSyntax = AttributeSyntax(stringLiteral: "@State")
//        let stateAttributeList: AttributeListSyntax = AttributeListSyntax([.attribute(stateAttribute)])
        
        return [
//            DeclSyntax(
//                VariableDeclSyntax(
////                    attributes: stateAttributeList,
//                    modifiers: DeclModifierListSyntax([DeclModifierSyntax(name: TokenSyntax(stringLiteral: "private"))]),
//                    bindingSpecifier: TokenSyntax(stringLiteral: "var"),
//                    bindings: PatternBindingListSyntax(
//                        [
//                            PatternBindingSyntax(
//                                leadingTrivia: .space,
//                                pattern: PatternSyntax(stringLiteral: "featureBox"),
//                                initializer: InitializerClauseSyntax(value: ExprSyntax(stringLiteral: "Box<\(typeString)?>()"))
//                            )
//                        ]
//                    )
//                )
//            ),
            
            """
            var viewModel: \(raw: typeString) {
                guard let viewModel = viewModelBox.value else {
                    let newViewModel = makeViewModel()
                    viewModelBox.value = newViewModel
                    return newViewModel
                }
                return viewModel
            }
            """,
            
            """
            @MainActor
            var $viewModel: Binding<\(raw: typeString)> {
                Binding {
                    viewModel
                } set: { [viewModelBox] newValue in
                    viewModelBox.value = newValue
                }
            }
            """,
            
            """
            private var _viewModelBox = State(initialValue: Box<\(raw: typeString)?>())
            """,
            
            """
            private var viewModelBox: Box<\(raw: typeString)?> {
                _viewModelBox.wrappedValue
            }
            """,
            
            """
            private var $viewModelBox: Binding<Box<\(raw: typeString)?>> {
                _viewModelBox.projectedValue
            }
            """,
        ]
    }
}

//extension FeatureStateMacro: AccessorMacro {
//    public static func expansion(
//        of node: SwiftSyntax.AttributeSyntax,
//        providingAccessorsOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
//        in context: some SwiftSyntaxMacros.MacroExpansionContext
//    ) throws -> [SwiftSyntax.AccessorDeclSyntax] {
//        
//        guard let varDecl = declaration.as(VariableDeclSyntax.self),
//              let binding = varDecl.bindings.first,
//              let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.trimmed,
//              binding.accessorBlock == nil
//        else {
//            return []
//        }
//        
//        return [
//            """
//            get {
//                guard let \(identifier) = \(identifier)Box.value else {
//                    let \(identifier) = makeState()
//                    self.\(identifier)Box.value = \(identifier)
//                    return \(identifier)
//                }
//                return \(identifier)
//            }
//            """
//        ]
//    }
//}

//extension FeatureStateMacro: BodyMacro {
//    public static func expansion(
//        of node: SwiftSyntax.AttributeSyntax,
//        providingBodyFor declaration: some SwiftSyntax.DeclSyntaxProtocol & SwiftSyntax.WithOptionalCodeBlockSyntax,
//        in context: some SwiftSyntaxMacros.MacroExpansionContext
//    ) throws -> [SwiftSyntax.CodeBlockItemSyntax] {
//        
//        guard let funcDecl = declaration.as(FunctionDeclSyntax.self),
//              let body = funcDecl.body
//        else {
//            return []
//        }
//        
//        return []
//    }
//}

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
