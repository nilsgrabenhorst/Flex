//
//  FeatureMacro.swift
//  Flex
//
//  Created by Nils Grabenhorst on 4/6/25.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftUI

struct FeatureMacroDiagnostic: DiagnosticMessage {
    let message: String
    let diagnosticID: SwiftDiagnostics.MessageID
    let severity: SwiftDiagnostics.DiagnosticSeverity
    
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
    
    private static let domain = "com.dohle.flex.macros.feature"
}

public struct FeatureMacro: MemberMacro, PeerMacro, ExtensionMacro {
    
    // MARK: Extensions
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            // TODO: Error handling
            return []
        }
        let name = structDecl.name
        
        let outletVariableDecls = structDecl.variableDecls.filter(\.isOutlet)
        guard !outletVariableDecls.isEmpty else {
            return []
        }
        
        let outletBindings = outletVariableDecls.flatMap {
            $0.bindings
        }
        
        let identifiersAndTypes: [(IdentifierPatternSyntax, TypeAnnotationSyntax)] = outletBindings.compactMap { binding -> (IdentifierPatternSyntax, TypeAnnotationSyntax)? in
            guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self) else {
                context.diagnose(
                    Diagnostic(
                        node: binding.pattern,
                        message: FeatureMacroDiagnostic.notAnIdentifier
                    )
                )
                return nil
            }
            guard let type = binding.typeAnnotation else {
                context.diagnose(
                    Diagnostic(
                        node: identifier,
                        message: FeatureMacroDiagnostic.typeAnnotationMissing
                    )
                )
                return nil
            }
            return (identifier, type)
        }
        
        return try [
//            ExtensionDeclSyntax("extension \(structDecl.name)") {
//                DeclSyntax(
//                    try ClassDeclSyntax("@MainActor @Observable public class Outlets") {
//                        "public let feature: \(raw: name)"
//                        """
//                        init(_ feature: \(name)) {
//                            self.feature = feature
//                        }
//                        """
//                        for (identifier, type) in identifiersAndTypes {
//                            try VariableDeclSyntax("var \(identifier)\(type)") {
//                                "feature.\(identifier)"
//                            }
//                        }
//                    }
//                )
//                DeclSyntax(
//                    try ClassDeclSyntax("@MainActor @Observable public class \(raw: name.text + "Actions")") {
//                        "public let feature: \(raw: name)"
//                        """
//                        init(_ feature: \(name)) {
//                            self.feature = feature
//                        }
//                        """
//                    }
//                )
//            },
            ExtensionDeclSyntax("extension \(structDecl.name): Flex.Feature") { "" },
            ExtensionDeclSyntax("extension \(structDecl.name): SwiftUI.View") {
                """
                public var body: some View {
                    presentation
                        .environment(\(raw: name.text)Outlets(self))
                        .environment(\(raw: name.text)Actions(self))
                }
                """
            },
        ]
    }
    
    
    // MARK: Peers
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            context.diagnose(
                Diagnostic(
                    node: declaration,
                    message: FeatureMacroDiagnostic.notAStruct
                )
            )
            return ["protocol WrongOne {}"]
        }
        let name = structDecl.name
        
        let outletVariableDecls = structDecl.variableDecls.filter(\.isOutlet)
        guard !outletVariableDecls.isEmpty else {
            return []
        }
        
        let outletBindings = outletVariableDecls.flatMap {
            $0.bindings
        }
        
        let identifiersAndTypes: [(IdentifierPatternSyntax, TypeAnnotationSyntax)] = outletBindings.compactMap { binding -> (IdentifierPatternSyntax, TypeAnnotationSyntax)? in
            guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self) else {
                context.diagnose(
                    Diagnostic(
                        node: binding.pattern,
                        message: FeatureMacroDiagnostic.notAnIdentifier
                    )
                )
                return nil
            }
            guard let type = binding.typeAnnotation else {
                context.diagnose(
                    Diagnostic(
                        node: identifier,
                        message: FeatureMacroDiagnostic.typeAnnotationMissing
                    )
                )
                return nil
            }
            return (identifier, type)
        }
        
        return [
            DeclSyntax(
                try ClassDeclSyntax("@MainActor @Observable public class \(raw: name.text + "Outlets")") {
                    "private let feature: \(raw: name)"
                    """
                    init(_ feature: \(name)) {
                        self.feature = feature
                    }
                    """
                    for (identifier, type) in identifiersAndTypes {
                        try VariableDeclSyntax("var \(identifier)\(type)") {
                            "feature.\(identifier)"
                        }
                    }
                }
            ),
            DeclSyntax(
                try ClassDeclSyntax("@MainActor @Observable public class \(raw: name.text + "Actions")") {
                    "private let feature: \(raw: name)"
                    """
                    init(_ feature: \(name)) {
                        self.feature = feature
                    }
                    """
                }
            )
        ]
    }
    
    // MARK: Members
    public static func expansion(of node: AttributeSyntax,
                                 providingMembersOf declaration: some DeclGroupSyntax,
                                 in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        guard let structDecl = declaration as? StructDeclSyntax else {
            context.diagnose(
                Diagnostic(
                    node: declaration,
                    message: FeatureMacroDiagnostic.notAStruct
                )
            )
            return []
        }
        
        let outletVariableDecls = structDecl.variableDecls.filter(\.isOutlet)
        
        /*
        if !outletVariableDecls.isEmpty {
            // TODO: Create real outlets property
            return ["var outlets: Int { 42 }"]
        }
         */
        
        return [
            
        ]
    }
}

extension StructDeclSyntax {
    var variableDecls: [VariableDeclSyntax] {
        memberBlock.members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
    }
}

extension VariableDeclSyntax {
    var isOutlet: Bool {
        attributes
            .compactMap { $0.as(AttributeSyntax.self) }
            .compactMap { $0.attributeName.as(IdentifierTypeSyntax.self) }
            .contains { $0.name.text == "Outlet" }
    }
}
