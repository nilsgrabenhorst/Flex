@_exported import SwiftUI

@attached(extension,
          conformances: Feature, View,
          names: named(body))
@attached(peer, names: suffixed(Outlets), suffixed(Actions), suffixed(Destinations))
public macro Feature() = #externalMacro(module: "FlexMacros", type: "FeatureMacro")

@attached(member, names: named(outlets), named(perform), named(destinations))
public macro Presentation<F: Feature>() = #externalMacro(module: "FlexMacros", type: "PresentationMacro")

@attached(peer)
public macro Outlet() = #externalMacro(module: "FlexMacros", type: "OutletMacro")

@attached(peer)
public macro Action() = #externalMacro(module: "FlexMacros", type: "ActionMacro")

//@attached(peer)
//public macro Destination() = #externalMacro(module: "FlexMacros", type: "DestinationMacro")



import SwiftUI

@MainActor
public protocol Feature: View {
    associatedtype Presentation: View
    var presentation: Presentation { get }
}

public extension View {
    @MainActor
    func sheet<Content: View>(
        destination content: Binding<Content?>,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        self.sheet(isPresented: Binding(get: {
            content.wrappedValue != nil
        }, set: { isPresented in
            if !isPresented {
                content.wrappedValue = nil
            }
        }), onDismiss: onDismiss, content: {
            content.wrappedValue
        })
    }
}

@propertyWrapper @MainActor
public struct Destination<V: View>: DynamicProperty {
    public typealias DestinationBinding = Binding<V?>
    @State private var value: V?
    public var wrappedValue: V? {
        get { value }
        nonmutating set { value = newValue }
    }
    
    public init(wrappedValue: V? = nil) {
        self.wrappedValue = wrappedValue
    }
    
    public var projectedValue: DestinationBinding {
        $value
    }
}
