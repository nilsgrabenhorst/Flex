
@attached(extension, names: named(Outlets), conformances: Feature)
//@attached(peer, names: )
@attached(member, names: named(outlets), named(actions), named(destinations))
public macro Feature() = #externalMacro(module: "FlexMacros", type: "FeatureMacro")

@attached(peer)
public macro Outlet() = #externalMacro(module: "FlexMacros", type: "OutletMacro")

import SwiftUI

public protocol Feature: View {
    associatedtype Presentation: View
    var presentation: Presentation { get }
}

public extension Feature {
    var body: some View {
        presentation
    }
}
