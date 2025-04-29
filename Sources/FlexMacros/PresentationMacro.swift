//
//  PresentationMacro.swift
//  Flex
//
//  Created by Nils Grabenhorst on 4/10/25.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftUI

public struct PresentationMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let identifier = node.attributeName.as(IdentifierTypeSyntax.self),
              let firstGenericArgument = identifier.genericArgumentClause?.arguments.first,
              let featureType = firstGenericArgument.argument.as(IdentifierTypeSyntax.self)
        else {
            // TODO: Diagnostic
            return[]
        }
        
        return [
            """
            @Environment(\(raw: featureType.name.text).Box.self) public var _feature
            """
        ]
    }
}

extension PresentationMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            // TODO: Error handling
            return []
        }
        let name = structDecl.name
        
        return try [
            ExtensionDeclSyntax("extension \(name): Flex.Presentation") { "" },
        ]
    }
}
