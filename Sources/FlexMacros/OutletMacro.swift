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
        return []
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
