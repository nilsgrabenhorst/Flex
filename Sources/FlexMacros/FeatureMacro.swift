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

public enum FeatureMacro { }

private struct OnChangeDefinition {
    init?(variable: VariableDeclSyntax, onChangeAttribute: AttributeSyntax) {
        guard
            let argumentExpression = onChangeAttribute.arguments?.as(LabeledExprListSyntax.self)?.first?.expression,
//            let memberAccess = argument.as(MemberAccessExprSyntax.self)
            let keyPath = argumentExpression.as(KeyPathExprSyntax.self)
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
//        self.memberAccess = memberAccess
//        self.destinationRoot = root.name.text
    }
    
    let variable: VariableDeclSyntax
    let onChangeAttribute: AttributeSyntax
    let identifier: IdentifierPatternSyntax
    let keyPath: KeyPathExprSyntax
//    let memberAccess: MemberAccessExprSyntax
    
    var sourceName: String { identifier.trimmedDescription }
//    let destinationRoot: String
    var destinationPath: KeyPathComponentListSyntax { keyPath.components }
}

// MARK: - Member
extension FeatureMacro: MemberMacro {
    public static func expansion(of node: AttributeSyntax,
                                 providingMembersOf declaration: some DeclGroupSyntax,
                                 in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        
        return []
    }
}

// MARK: - Extension
extension FeatureMacro: ExtensionMacro {
    
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
        
        let name = structDecl.name.trimmed
        
        let modifiers: DeclModifierListSyntax = structDecl.modifiers
        
        let accessControl = modifiers.first.map( { $0.name.text + " " } ) ?? ""
        
        let onChangeModifiers: [FunctionCallExprSyntax] = onChangeDefinitions.compactMap { definition -> FunctionCallExprSyntax? in
            let callee = MemberAccessExprSyntax(period: .periodToken(), name: .identifier("onChange"))
            
            let codeBlockItemList = CodeBlockItemListSyntax([
                                """
                                    viewModel\(definition.destinationPath) = newValue
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
            ExtensionDeclSyntax("extension \(name): View") {
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
extension FeatureMacro: MemberAttributeMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingAttributesFor member: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.AttributeSyntax] {
        if let funcDecl = member.as(FunctionDeclSyntax.self),
           funcDecl.name.text == "makeViewModel"
        {
            return [
                AttributeSyntax(stringLiteral: "@FeatureState")
            ]
        }
        return []
    }
}

struct FeatureMacroDiagnostic: DiagnosticMessage {
    let message: String
    let diagnosticID: SwiftDiagnostics.MessageID
    let severity: SwiftDiagnostics.DiagnosticSeverity
    private static let domain = "com.dohle.flex.macros.feature"
    
    static let typeAnnotationMissing = FeatureMacroDiagnostic(
        message: "Type annotation missing",
        diagnosticID: MessageID(domain: domain, id: "typeAnnotationMissing"),
        severity: .error
    )
    
    static let notAnIdentifier = FeatureMacroDiagnostic(
        message: "Identifier expected",
        diagnosticID: MessageID(domain: domain, id: "notAnIdentifier"),
        severity: .error
    )
    
    static let notAStruct = FeatureMacroDiagnostic(
        message: "The attribute can only be applied to a struct",
        diagnosticID: MessageID(domain: domain, id: "notAStruct"),
        severity: .error
    )
    
    static let notAVariable = FeatureMacroDiagnostic(
        message: "The attribute can only be applied to a variable",
        diagnosticID: MessageID(domain: domain, id: "notAVariable"),
        severity: .error
    )
    
    static let supportsMaxOneModifier = FeatureMacroDiagnostic(
        message: "Currently only supports zero or one modifier like `public` or `private`.",
        diagnosticID: MessageID(domain: domain, id: "supportsMaxOneModifier"),
        severity: .error
    )
    
    static let initializerExpected = FeatureMacroDiagnostic(
        message: "Could not find an initializer",
        diagnosticID: MessageID(domain: domain, id: "initializerExpected"),
        severity: .error
    )
    
    static let shouldHaveNoParameters = FeatureMacroDiagnostic(
        message: "Function should have no parameters",
        diagnosticID: MessageID(domain: domain, id: "shouldHaveNoParameters"),
        severity: .error
    )
    
    static let shouldReturnValue = FeatureMacroDiagnostic(
        message: "Function should return a value",
        diagnosticID: MessageID(domain: domain, id: "shouldReturnValue"),
        severity: .error
    )
}
