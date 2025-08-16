//
//  FetchedMacro.swift
//  Flex
//
//  Created by Nils Grabenhorst on 14.08.25.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftUI

struct FetchedMacroDiagnostic: DiagnosticMessage, Error {
    let message: String
    let diagnosticID: SwiftDiagnostics.MessageID
    let severity: SwiftDiagnostics.DiagnosticSeverity
    
    static let typeAnnotationMissing = FetchedMacroDiagnostic(
        message: "Type annotation missing",
        diagnosticID: MessageID(domain: domain, id: "typeAnnotationMissing"),
        severity: .error
    )
    
    static let unsupportedType = FetchedMacroDiagnostic(
        message: "Type not supported. Currently only arrays of PersistentModel are supported",
        diagnosticID: MessageID(domain: domain, id: "unsupportedType"),
        severity: .error
    )
    
    static let genericArgumentMissing = FetchedMacroDiagnostic(
        message: "Generic argument missing",
        diagnosticID: MessageID(domain: domain, id: "genericArgumentMissing"),
        severity: .error
    )
    
    static let fetchRequestMissing = FetchedMacroDiagnostic(
        message: "Please provide a FetchRequest",
        diagnosticID: MessageID(domain: domain, id: "fetchRequestMissing"),
        severity: .error
    )
    
    static let notAProperty = FetchedMacroDiagnostic(
        message: "The attribute can only be applied to a property",
        diagnosticID: MessageID(domain: domain, id: "notAStruct"),
        severity: .error
    )
    
    private static let domain = "com.dohle.flex.macros.feature"
}

struct DiagnosticError: Error {
    let diagnostic: Diagnostic
    
    init(node: some SyntaxProtocol, message: FetchedMacroDiagnostic) {
        self.diagnostic = Diagnostic(node: node, message: message)
    }
}

extension MacroExpansionContext {
    func diagnose(_ error: DiagnosticError) {
        self.diagnose(error.diagnostic)
    }
}

public struct FetchedMacro {
    private static func variableDeclaration(_ declaration: some DeclSyntaxProtocol) throws(DiagnosticError) -> VariableDeclSyntax {
        guard let variableDecl = declaration.as(VariableDeclSyntax.self)
        else {
            throw DiagnosticError(node: declaration, message: .notAProperty)
        }
        return variableDecl
    }
    
    private static func arrayTypeSyntax(_ variableDecl: VariableDeclSyntax) throws(DiagnosticError) -> ArrayTypeSyntax {
        guard let typeAnnotation = variableDecl.typeAnnotation,
              let arrayTypeSyntax = typeAnnotation.type.as(ArrayTypeSyntax.self)
        else {
            throw DiagnosticError(node: variableDecl, message: .unsupportedType)
        }
        return arrayTypeSyntax
    }
}

extension FetchedMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        do {
            let variableDecl = try variableDeclaration(declaration)
            let identifier = variableDecl.identifier
            let arrayTypeSyntax = try arrayTypeSyntax(variableDecl)
            let type = arrayTypeSyntax.element
            
            return [
                """
                private let \(identifier)Fetcher: Fetcher<\(type)> = .init()
                """
            ]
        } catch {
            context.diagnose(error)
            return []
        }
    }
}

extension FetchedMacro: AccessorMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingAccessorsOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.AccessorDeclSyntax] {
        do {
            let variableDecl = try variableDeclaration(declaration)
            let identifier = variableDecl.identifier
            
            return [
                """
                get {
                    \(identifier)Fetcher.results
                }
                """
            ]
        } catch {
            context.diagnose(error)
            return []
        }
    }
}
