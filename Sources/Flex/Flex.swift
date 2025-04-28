@_exported import SwiftUI

@attached(member, names: named(_outlets), named(_actions), named(_destinations))
@attached(memberAttribute)
@attached(extension,
          conformances: Feature, View, WithOutlets, WithActions, WithDestinations,
          names: named(body), named(outlets), named(actions), named(destinations))
@attached(peer, names: suffixed(Outlets), suffixed(Actions), suffixed(Destinations))
public macro Feature() = #externalMacro(module: "FlexMacros", type: "FeatureMacro")

@attached(extension, conformances: Presentation)
@attached(member, names: named(_feature), named(outlets), named(perform), named(destinations))
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

@Observable
public final class SomeFeature<F: Feature> {
    private let feature: F
    
    public init(_ feature: F) {
        self.feature = feature
    }
}

extension SomeFeature where F: WithOutlets {
    @MainActor
    public var outlets: F.Outlets {
        feature.outlets
    }
}

extension SomeFeature where F: WithActions {
    @MainActor
    public var actions: F.Actions {
        feature.actions
    }
}

extension SomeFeature where F: WithDestinations {
    @MainActor
    public var destinations: F.Destinations {
        feature.destinations
    }
}

@MainActor public protocol WithOutlets {
    associatedtype Outlets
    var outlets: Outlets { get }
}
@MainActor public protocol WithActions {
    associatedtype Actions
    var actions: Actions { get }
}
@MainActor public protocol WithDestinations {
    associatedtype Destinations
    var destinations: Destinations { get }
}

@MainActor
public protocol Presentation: View {
    associatedtype F: Feature
    var _feature: SomeFeature<F> { get }
}

@MainActor
extension Presentation where F: WithOutlets {
    public var outlets: F.Outlets {
        _feature.outlets
    }
}

@MainActor
extension Presentation where F: WithActions {
    public var perform: F.Actions {
        _feature.actions
    }
}

@MainActor
extension Presentation where F: WithDestinations {
    public var destinations: F.Destinations {
        _feature.destinations
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

//@propertyWrapper @MainActor
//public struct OutletState<T>: DynamicProperty {
//    public typealias OutletBinding = Binding<T>
//    @State private var value: T
//    public var wrappedValue: T {
//        get { value }
//        nonmutating set { value = newValue }
//    }
//    
//    public init(wrappedValue: T) {
//        self._value = State(initialValue: wrappedValue)
//    }
//    
//    public var projectedValue: OutletBinding {
//        $value
//    }
//}
