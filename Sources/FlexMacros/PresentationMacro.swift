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
            @Environment(\(raw: featureType.name.text)Outlets.self) private var outlets
            @Environment(\(raw: featureType.name.text)Actions.self) private var perform
            @Environment(\(raw: featureType.name.text)Destinations.self) private var destinations
            """
        ]
    }
}

extension PresentationMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}
