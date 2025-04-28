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

public struct FeatureMacro {}

// MARK: - Peers
extension FeatureMacro: PeerMacro {
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
            return []
        }
        
        return [
            try outlets(for: structDecl, context: context),
            try actions(for: structDecl, context: context),
            try destinations(for: structDecl, context: context)
        ].compactMap { $0 }
    }
    
    private static func bindingInitializers(for identifiersAndTypes: [(IdentifierPatternSyntax, TypeAnnotationSyntax)]) -> String? {
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
    
    private static func destinations(for structDecl: StructDeclSyntax, context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> DeclSyntax? {
        let destinationIdentifiersAndTypes = structDecl.variableDecls
            .filter(\.isDestination)
            .flatMap(\.bindings)
            .identifiersAndTypes(context: context)
        guard !destinationIdentifiersAndTypes.isEmpty else { return nil }
        
        let name = structDecl.name
        
        return DeclSyntax(
            try ClassDeclSyntax("@MainActor @Observable public class \(raw: name.text + "Destinations")") {
                "private let feature: \(raw: name)"
                """
                init(_ feature: \(name)) {
                    self.feature = feature
                }
                """
                for (identifier, type) in destinationIdentifiersAndTypes {
                    """
                    var \(identifier)\(type) {
                        feature.\(identifier)
                    }
                    var $\(identifier): Binding<\(type.type)> {
                        feature.$\(identifier)
                    }
                    """
                }
            }
        )
    }
    
    private static func actions(for structDecl: StructDeclSyntax, context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> DeclSyntax? {
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
        guard !actions.isEmpty else { return nil }
        
        let name = structDecl.name
        return DeclSyntax(
            try ClassDeclSyntax.init("@MainActor @Observable public class \(raw: name.text + "Actions")") {
                "private let feature: \(raw: name)"
                """
                init(_ feature: \(name)) {
                    self.feature = feature
                }
                """
                actions
            }
        )
    }
    
    private static func outlets(for structDecl: StructDeclSyntax, context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> DeclSyntax? {
        let name = structDecl.name
        let (states, outlets) = structDecl.variableDecls
            .filter(\.isOutlet)
            .split { $0.isOutletConvertibleToState && !$0.isSetterPrivate }
        
        let (writeable, readonly) = outlets.split { $0.isWritable && !$0.isSetterPrivate }
        
        let stateOutlets = states.flatMap(\.bindings).identifiersAndTypes(context: context)
        let writableOutlets = writeable.flatMap(\.bindings).identifiersAndTypes(context: context)
        let readonlyOutlets = readonly.flatMap(\.bindings).identifiersAndTypes(context: context)
        
        guard !stateOutlets.isEmpty || !writableOutlets.isEmpty || !readonlyOutlets.isEmpty else {
            return nil
        }
        
        return DeclSyntax(
            try ClassDeclSyntax("@MainActor @Observable public class \(raw: name.text + "Outlets")") {
                "private let feature: \(raw: name)"
                """
                init(_ feature: \(name)) {
                    self.feature = feature
                }
                """
                for (identifier, type) in stateOutlets {
                    """
                    var \(identifier)\(type) {
                        feature.\(identifier)
                    }
                    var $\(identifier): Binding<\(type.type)> {
                        feature.$\(identifier)
                    } 
                    """
                }
                for (identifier, type) in writableOutlets {
                    """
                    var \(identifier)\(type) {
                        feature.\(identifier)
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
                for (identifier, type) in readonlyOutlets {
                    """
                    var \(identifier)\(type) {
                        feature.\(identifier)
                    } 
                    """
                }
            }
        )
    }
}
    
// MARK: - Extensions
extension FeatureMacro: ExtensionMacro {
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
        let variableDecls = structDecl.variableDecls
        let hasOutlets = variableDecls.contains(where: \.isOutlet)
        let hasDestinations = variableDecls.contains(where: \.isDestination)
        let hasActions = structDecl.methodDecls.contains(where: \.isAction)
        
        let withOutletsExtension = hasOutlets ? try ExtensionDeclSyntax("extension \(name): Flex.WithOutlets") {
            """
            public var outlets: \(raw: name.text)Outlets {
                _outlets
            }
            """
        } : nil
        let withActionsExtension = hasActions ? try ExtensionDeclSyntax("extension \(name): Flex.WithActions") {
            """
            public var actions: \(raw: name.text)Actions {
                _actions
            }
            """
        } : nil
        let withDestinationsExtension = hasDestinations ? try ExtensionDeclSyntax("extension \(name): Flex.WithDestinations") {
            """
            public var destinations: \(raw: name.text)Destinations {
                _destinations
            }
            """
        } : nil
        let markerExtensions = [withOutletsExtension, withActionsExtension, withDestinationsExtension].compactMap(\.self)
        
        return try [
            ExtensionDeclSyntax("extension \(name): Flex.Feature") { "" },
            ExtensionDeclSyntax("extension \(name): SwiftUI.View") {
                """
                public var body: some View {
                    presentation
                        .environment(SomeFeature(self))
                }
                """
            },
        ] + markerExtensions
    }
}



// MARK: - Members
extension FeatureMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            // TODO: Error handling
            return []
        }
        let name = structDecl.name.text
        let variableDecls = structDecl.variableDecls
        let hasOutlets = variableDecls.contains(where: \.isOutlet)
        let hasActions = structDecl.methodDecls.contains(where: \.isAction)
        let hasDestinations = variableDecls.contains(where: \.isDestination)
        
        /*
         lazy var does not work on an immutable struct.
         We need to create a bespoke Feature object for injecting into the environment...
         */
        
        let outletsVar: DeclSyntax? = hasOutlets ? "private lazy var _outlets = \(raw: name)Outlets(self)" : nil
        let actionsVar: DeclSyntax? = hasActions ? "private lazy var _actions = \(raw: name)Actions(self)" : nil
        let destinationsVar: DeclSyntax? = hasDestinations ? "private lazy var _destinations = \(raw: name)Destinations(self)" : nil
        
        return [
            outletsVar,
            actionsVar,
            destinationsVar,
        ].compactMap(\.self)
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
        guard let variableDecl = member.as(VariableDeclSyntax.self)
        else {
            return []
        }
        return variableDecl
            .isOutletConvertibleToState
                ? [AttributeSyntax(attributeName: IdentifierTypeSyntax(name: .identifier("State")))]
                : []
    }
}

// MARK: -

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
        hasAttribute("Outlet")
    }
    
    var isDestination: Bool {
        hasAttribute("Destination")
    }
    
    var isOutletState: Bool {
        hasAttribute("OutletState")
    }
    
    func isStoredProperty() -> Bool {
        guard bindings.count == 1 else {
            // TODO: Diagnostic
            return false
        }
        let binding: PatternBindingSyntax = bindings.first!
        guard let accessorBlock = binding.accessorBlock else { return true }
        guard let accessors = accessorBlock.accessors.as(AccessorDeclListSyntax.self) else {
            if let _ = accessorBlock.accessors.as(CodeBlockItemListSyntax.self) {
                return false
            } else {
                return true
            }
        }
        let accessorSpecifiers = Set(accessors.map(\.accessorSpecifier))
        let propertyObserverSpecifiers: Set<TokenSyntax> = ["didSet", "willSet"]
        
        return accessorSpecifiers
            .subtracting(propertyObserverSpecifiers)
            .isEmpty
    }
    
    var isWritable: Bool {
        guard bindingSpecifier.text == "var" else { return false }
        let bindings = bindings
        if isStoredProperty() {
            return true
        } else {
            return bindings.contains(where: { $0.hasSetter })
        }
    }
    
    var isSetterPrivate: Bool {
        modifiers.contains { $0.isPrivateSet() }
    }
    
    var isOutletConvertibleToState: Bool {
        isOutlet &&
        isStoredProperty() &&
        isWritable
    }
    
    var isStatePropertyWrapper: Bool {
        hasAttribute("State")
    }
    
    private func hasAttribute(_ attributeName: String) -> Bool {
        attributes
            .compactMap { $0.as(AttributeSyntax.self) }
            .compactMap { $0.attributeName.as(IdentifierTypeSyntax.self) }
            .contains { $0.name.text == attributeName }
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

public extension Sequence {
    func split<E: Error>(_ isIncluded: (Element) throws(E) -> Bool) throws(E) -> (satisfies: [Element], rest: [Element]) {
        var satisfies: [Element] = []
        var rest: [Element] = []
        for element in self {
            if try isIncluded(element) {
                satisfies.append(element)
            } else {
                rest.append(element)
            }
        }
        return (satisfies, rest)
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
