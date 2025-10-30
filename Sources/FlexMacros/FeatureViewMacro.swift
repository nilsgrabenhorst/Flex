//
//  FeatureViewMacro.swift
//  Flex
//
//  Created by Nils Grabenhorst on 22.10.25.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftUI

public enum OnChangeMacro: PeerMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        return []
    }
}

public enum FeatureViewMacro { }

private struct OnChangeDefinition {
    init?(variable: VariableDeclSyntax, onChangeAttribute: AttributeSyntax) {
        guard
            let argument = onChangeAttribute.arguments?.as(LabeledExprListSyntax.self)?.first?.expression,
            let keyPath = argument.as(KeyPathExprSyntax.self)
        else {
            assertionFailure("Could not find keyPath in @OnChange argument")
            return nil
        }
        
        guard let identifier = variable.bindings.compactMap( {
            $0.pattern.as(IdentifierPatternSyntax.self)
        }).first
        else {
            assertionFailure("Could not find property name")
            return nil
        }
        
        guard let root = keyPath.root?.as(IdentifierTypeSyntax.self) else {
            assertionFailure("Could not read keypath root")
            return nil
        }
        
        self.identifier = identifier
        self.variable = variable
        self.onChangeAttribute = onChangeAttribute
        self.keyPath = keyPath
        self.destinationRoot = root.name.text
    }
    
    let variable: VariableDeclSyntax
    let onChangeAttribute: AttributeSyntax
    let identifier: IdentifierPatternSyntax
    let keyPath: KeyPathExprSyntax
    
    var sourceName: String { identifier.trimmedDescription }
    let destinationRoot: String
    var destinationPath: KeyPathComponentListSyntax { keyPath.components }
}

// MARK: - Extension
extension FeatureViewMacro: ExtensionMacro {
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            context.diagnose(
                Diagnostic(
                    node: declaration,
                    message: FeatureMacroDiagnostic.notAStruct
                )
            )
            return []
        }
        
//        let variableDecls = memberBlock.compactMap {
//            $0.decl.as(VariableDeclSyntax.self)
//        }
        
        let onChangeDefinitions: [OnChangeDefinition] = structDecl.memberBlock.onChangeDefinitions
        
        let name = structDecl.name
        
        let modifiers: DeclModifierListSyntax = structDecl.modifiers
        
        let accessControl = modifiers.first.map( { $0.name.text + " " } ) ?? ""
        
        let onChangeModifiers: [FunctionCallExprSyntax] = onChangeDefinitions.compactMap { definition -> FunctionCallExprSyntax? in
            let callee = MemberAccessExprSyntax(period: .periodToken(), name: .identifier("onChange"))
            
            let codeBlockItemList = CodeBlockItemListSyntax([
                                """
                                    \(raw: definition.destinationRoot)\(definition.destinationPath) = newValue
                                """
            ])
            let oldValueParameter = ClosureShorthandParameterSyntax(leadingTrivia: .space, name: .identifier("_"), trailingComma: .commaToken())
            let newValueParameter = ClosureShorthandParameterSyntax(leadingTrivia: .space, name: .identifier("newValue"), trailingTrivia: .space)
            let closureParameters = ClosureShorthandParameterListSyntax([
                oldValueParameter,
                newValueParameter
            ])
            let closureSignature = ClosureSignatureSyntax(parameterClause: .simpleInput(closureParameters),
                                                          trailingTrivia: .newline)
                
            let trailingClosure = ClosureExprSyntax(leftBrace: .leftBraceToken(),
                                                    signature: closureSignature,
                                                    statements: codeBlockItemList,
                                                    rightBrace: .rightBraceToken(leadingTrivia: .newline))
            let argument = LabeledExprSyntax(label: "of",
                                             colon: .colonToken(),
                                             expression: DeclReferenceExprSyntax(
                                                leadingTrivia: .space,
                                                baseName: TokenSyntax.identifier(definition.sourceName)
                                             ))
            let arguments = LabeledExprListSyntax([argument])
            return FunctionCallExprSyntax(calledExpression: callee,
                                          leftParen: .leftParenToken(),
                                          arguments: arguments,
                                          rightParen: .rightParenToken(trailingTrivia: .space),
                                          trailingClosure: trailingClosure,
                                          trailingTrivia: .newline)
        }
        
        let onChangeList = ExprListSyntax(onChangeModifiers)
        
        return try [
            ExtensionDeclSyntax("extension \(name): SwiftUI.View") {
                """
                \(raw: accessControl)var body: some View {
                    presentation
                    \(onChangeList)
                }
                """
            },
        ]
    }
}

extension MemberBlockSyntax {
    fileprivate var onChangeDefinitions: [OnChangeDefinition] {
        let variableDecls = members.compactMap {
            $0.decl.as(VariableDeclSyntax.self)
        }
        let onChangeDefinitions = variableDecls.compactMap { (variableDecl: VariableDeclSyntax) -> OnChangeDefinition? in
            guard let onChangeAttribute = variableDecl
                .attributes
                .compactMap({ $0.as(AttributeSyntax.self) })
                .first(where: {
                    guard
                        let identifier = $0.attributeName.as(IdentifierTypeSyntax.self)
                    else {
                        return false
                    }
                    return identifier.name.text == "OnChange"
                })
            else {
                return nil
            }
            return OnChangeDefinition(variable: variableDecl, onChangeAttribute: onChangeAttribute)
        }
        return onChangeDefinitions
    }
}

// MARK: - Member Attributes
extension FeatureViewMacro: MemberAttributeMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingAttributesFor member: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.AttributeSyntax] {
        guard let variableDecl = member.as(VariableDeclSyntax.self)
        else {
            return []
        }
        guard variableDecl.identifier?.text == "body" else {
            return []
        }
        
        return [
            AttributeSyntax(stringLiteral: "@ChangeObserving")
        ]
    }
}
