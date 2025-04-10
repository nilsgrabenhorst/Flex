
@attached(extension,
          conformances: Feature, View,
          names: named(body))
@attached(peer, names: suffixed(Outlets), suffixed(Actions))
@attached(member)
public macro Feature() = #externalMacro(module: "FlexMacros", type: "FeatureMacro")

@attached(member, names: named(outlets), named(actions))
public macro Presentation<F: Feature>() = #externalMacro(module: "FlexMacros", type: "PresentationMacro")

@attached(peer)
public macro Outlet() = #externalMacro(module: "FlexMacros", type: "OutletMacro")



import SwiftUI

public protocol Feature: View {
    associatedtype Presentation: View
    var presentation: Presentation { get }
}

