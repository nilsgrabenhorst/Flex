@_exported import SwiftUI

@attached(extension,
          conformances: Feature, View,
          names: named(body))
@attached(peer, names: suffixed(Outlets), suffixed(Actions))
public macro Feature() = #externalMacro(module: "FlexMacros", type: "FeatureMacro")

@attached(member, names: named(outlets), named(perform))
public macro Presentation<F: Feature>() = #externalMacro(module: "FlexMacros", type: "PresentationMacro")

@attached(peer)
public macro Outlet() = #externalMacro(module: "FlexMacros", type: "OutletMacro")

@attached(peer)
public macro Action() = #externalMacro(module: "FlexMacros", type: "ActionMacro")



import SwiftUI

@MainActor
public protocol Feature: View {
    associatedtype Presentation: View
    var presentation: Presentation { get }
}

