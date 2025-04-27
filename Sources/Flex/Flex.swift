@_exported import SwiftUI

@attached(memberAttribute)
@attached(extension,
          conformances: Feature, View,
          names: named(body))
@attached(peer, names: suffixed(Outlets), suffixed(Actions), suffixed(Destinations))
public macro Feature() = #externalMacro(module: "FlexMacros", type: "FeatureMacro")

@attached(member, names: named(outlets), named(perform), named(destinations))
public macro Presentation<F: Feature>() = #externalMacro(module: "FlexMacros", type: "PresentationMacro")

@attached(accessor)
@attached(peer, names:
            suffixed(Storage)
          , prefixed(`$`)
)
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

@MainActor public protocol WithOutlets {
    associatedtype Outlets
}
@MainActor public protocol WithActions {
    associatedtype Actions
}
@MainActor public protocol WithDestinations {
    associatedtype Destinations
}

@MainActor
public protocol Presentation: View {
    associatedtype F: Feature
    var feature: F { get }
}

extension Presentation where F: WithOutlets {
    var outlets: F.Outlets {        
    }
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

@propertyWrapper @MainActor
public struct OutletState<T>: DynamicProperty {
    public typealias OutletBinding = Binding<T>
    @State private var value: T
    public var wrappedValue: T {
        get { value }
        nonmutating set { value = newValue }
    }
    
    public init(wrappedValue: T) {
        self._value = State(initialValue: wrappedValue)
    }
    
    public var projectedValue: OutletBinding {
        $value
    }
}
