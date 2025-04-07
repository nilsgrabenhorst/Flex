//
//  FeatureMacro.swift
//  Flex
//
//  Created by Nils Grabenhorst on 4/6/25.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftUI

public struct FeatureMacro: MemberMacro, PeerMacro, ExtensionMacro {
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
        
        let outletVariableDecls = structDecl.variableDecls.filter(\.isOutlet)
        guard !outletVariableDecls.isEmpty else {
            return []
        }
        
        return try [
            ExtensionDeclSyntax("extension \(structDecl.name)") {
                """
                struct Outlets {
                
                }
                """
            },
            ExtensionDeclSyntax("extension \(structDecl.name): Flex.Feature") { "" }
        ]
    }
    
    
    // MARK: Peers
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            // TODO: Error handling
            return []
        }
        
        let outletVariableDecls = structDecl.variableDecls.filter(\.isOutlet)
        guard !outletVariableDecls.isEmpty else {
            return []
        }
        
        return [
        ]
    }
    
    // MARK: Members
    public static func expansion(of node: AttributeSyntax,
                                 providingMembersOf declaration: some DeclGroupSyntax,
                                 in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        guard let structDecl = declaration as? StructDeclSyntax else {
            // TODO: Error handling
            return []
        }
        
        let outletVariableDecls = structDecl.variableDecls.filter(\.isOutlet)
        
        if !outletVariableDecls.isEmpty {
            // TODO: Create real outlets property
            return ["var outlets: Int { 42 }"]
        }
        
        return []
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
