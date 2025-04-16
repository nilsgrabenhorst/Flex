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

public struct FeatureMacro: PeerMacro, ExtensionMacro {
    
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
        
        let writableOutlets = outletVariableDecls
            .filter(\.isWritable)
            .flatMap(\.bindings)
        let readonlyOutlets = outletVariableDecls
            .filter { !$0.isWritable }
            .flatMap(\.bindings)
        
        let actionMethodDecls  = structDecl.methodDecls.filter(\.isAction)
        
        let actions: [FunctionDeclSyntax] = try actionMethodDecls.map {
            let modifiers = $0.modifiers
            let name = $0.name
            let signature = $0.signature
            let parameters = signature.parameterClause.parameters
            let arguments = parameters.map {
                let argumentName = $0.firstName.tokenKind == .wildcard ? "" : ($0.firstName.text + ": ")
                let valueName = $0.secondName?.text ?? $0.firstName.text
                return argumentName + valueName
            }
                .joined(separator: ", ")
            
            return try FunctionDeclSyntax("\(modifiers)func \(name)\(signature)") {
                "feature.\(name)(\(raw: arguments))"
            }
        }
        
        let readonlyOutletIdentifiersAndTypes = readonlyOutlets.identifiersAndTypes(context: context)
        let readWriteOutletIdentifiersAndTypes = writableOutlets.identifiersAndTypes(context: context)
        
        let destinationIdentifiersAndTypes = structDecl.variableDecls
            .filter(\.isDestination)
            .flatMap(\.bindings)
            .identifiersAndTypes(context: context)
        
        return [
            // TODO: only if we have outlets
            DeclSyntax(
                try ClassDeclSyntax("@MainActor @Observable public class \(raw: name.text + "Outlets")") {
                    "private let feature: \(raw: name)"
                    """
                    init(_ feature: \(name)) {
                        self.feature = feature
                    }
                    """
                    for (identifier, type) in readonlyOutletIdentifiersAndTypes {
                        try VariableDeclSyntax("var \(identifier)\(type)") {
                            "feature.\(identifier)"
                        }
                    }
                    for (identifier, type) in readWriteOutletIdentifiersAndTypes {
                        """
                        var \(identifier) \(type) {
                            get { feature.\(identifier) }
                            set { feature.\(identifier) = newValue }
                        }
                        
                        @ObservationIgnored
                        lazy var $\(identifier) = Binding(
                            get: { @MainActor [unowned self] in
                                self.feature.\(identifier)
                            },
                            set: { @MainActor [unowned self] newValue in
                                self.feature.\(identifier) = newValue
                            }
                        )
                        """
                    }
                }
            ),
            // TODO: Only if we have actions
            DeclSyntax(
                try ClassDeclSyntax("@MainActor @Observable public class \(raw: name.text + "Actions")") {
                    "private let feature: \(raw: name)"
                    """
                    init(_ feature: \(name)) {
                        self.feature = feature
                    }
                    """
                    actions
                }
            ),
            // TODO: Only if we have destinations
            DeclSyntax(
                try ClassDeclSyntax("@MainActor @Observable public class \(raw: name.text + "Destinations")") {
                    "private let feature: \(raw: name)"
                    """
                    init(_ feature: \(name)) {
                        self.feature = feature
                    }
                    """
                    for (identifier, type) in destinationIdentifiersAndTypes {
                        try VariableDeclSyntax("var \(identifier)\(type)") {
                            "feature.\(identifier)"
                        }
                    }
                }
            )
        ]
    }
    
    static func bindingInitializers(for identifiersAndTypes: [(IdentifierPatternSyntax, TypeAnnotationSyntax)]) -> String? {
        identifiersAndTypes
            .map { identifier, type in
                """
                self.$\(identifier) = Binding(
                    get: { self.feature.\(identifier) },
                    set: { newValue in self.feature.\(identifier) = newValue }
                )
                """
            }
            .joined(separator: "\n")
    }
    
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
        
        return try [
            ExtensionDeclSyntax("extension \(structDecl.name): Flex.Feature") { "" },
            ExtensionDeclSyntax("extension \(structDecl.name): SwiftUI.View") {
                """
                public var body: some View {
                    presentation
                        .environment(\(raw: name.text)Outlets(self))
                        .environment(\(raw: name.text)Actions(self))
                        .environment(\(raw: name.text)Destinations(self))
                }
                """
            },
        ]
    }
}

extension StructDeclSyntax {
    var variableDecls: [VariableDeclSyntax] {
        memberBlock.members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
    }
    
    var methodDecls: [FunctionDeclSyntax] {
        memberBlock.members
            .compactMap { $0.decl.as(FunctionDeclSyntax.self) }
    }
}

extension VariableDeclSyntax {
    var isOutlet: Bool {
        attributes
            .compactMap { $0.as(AttributeSyntax.self) }
            .compactMap { $0.attributeName.as(IdentifierTypeSyntax.self) }
            .contains { $0.name.text == "Outlet" }
    }
    
    var isDestination: Bool {
        attributes
            .compactMap { $0.as(AttributeSyntax.self) }
            .compactMap { $0.attributeName.as(IdentifierTypeSyntax.self) }
            .contains { $0.name.text == "Destination" }
    }
    
    var isWritable: Bool {
        guard bindingSpecifier.text == "var" else { return false }
        guard !modifiers.contains(where: { $0.isPrivateSet() }) else {
            return false
        }
        let bindings = bindings
        guard bindings.contains(where: { $0.hasSetter }) else { return false }
        return true
    }
}

extension PatternBindingSyntax {
    var hasSetter: Bool {
        guard let accessorBlock else { return false }
        guard let accessors = accessorBlock.accessors.as(AccessorDeclListSyntax.self) else { return false }
        return accessors.contains {
            $0.accessorSpecifier.text == "set"
        }
    }
    
    func identifier(context: some SwiftSyntaxMacros.MacroExpansionContext) -> IdentifierPatternSyntax? {
        guard let identifier = pattern.as(IdentifierPatternSyntax.self) else {
            context.diagnose(
                Diagnostic(
                    node: pattern,
                    message: FeatureMacroDiagnostic.notAnIdentifier
                )
            )
            return nil
        }
        return identifier
    }
    
    func type(context: some SwiftSyntaxMacros.MacroExpansionContext) -> TypeAnnotationSyntax? {
        guard let typeAnnotation else {
            context.diagnose(
                Diagnostic(
                    node: self,
                    message: FeatureMacroDiagnostic.typeAnnotationMissing
                )
            )
            return nil
        }
        return typeAnnotation
    }
}

extension Sequence<PatternBindingSyntax> {
    func identifiersAndTypes(context: some SwiftSyntaxMacros.MacroExpansionContext) -> [(IdentifierPatternSyntax, TypeAnnotationSyntax)] {
        compactMap {
            guard let identifier = $0.identifier(context: context) else { return nil }
            guard let type = $0.type(context: context) else { return nil }
            return (identifier, type)
        }
    }
}

extension DeclModifierSyntax {
    func isPrivateSet() -> Bool {
        name.text == "private" && detail?.detail.text == "set"
    }
}

extension FunctionDeclSyntax {
    var isAction: Bool {
        attributes
            .compactMap { $0.as(AttributeSyntax.self) }
            .compactMap { $0.attributeName.as(IdentifierTypeSyntax.self) }
            .contains { $0.name.text == "Action" }
    }
}
