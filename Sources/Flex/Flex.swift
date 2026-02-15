@_exported import SwiftUI
import SwiftData

//@attached(member, names: named(Box))
//@attached(memberAttribute)
//@attached(extension,
//          conformances: Feature, WithOutlets, WithActions, WithDestinations,
//          names: named(view), named(outlets), named(actions), named(destinations))
//@attached(peer, names: suffixed(Outlets), suffixed(Actions), suffixed(Destinations), suffixed(Box))
//public macro Feature() = #externalMacro(module: "FlexMacros", type: "FeatureMacro")
//
//@attached(extension, conformances: Presentation)
//@attached(member, names: named(_feature), named(outlets), named(perform), named(destinations))
//public macro Presentation<F: Feature>() = #externalMacro(module: "FlexMacros", type: "PresentationMacro")
//
//@attached(peer)
//public macro Outlet() = #externalMacro(module: "FlexMacros", type: "OutletMacro")
//
//@attached(peer)
//public macro Action() = #externalMacro(module: "FlexMacros", type: "ActionMacro")
//
//@attached(peer)
//public macro Destination() = #externalMacro(module: "FlexMacros", type: "DestinationMacro")

// TODO: This macro should either get a parameter for the context to use, or somehow grab the context from the enclosing scope...
@attached(peer, names: suffixed(Fetcher))
@attached(accessor)
public macro Fetched<Model: PersistentModel>(_ fetchDescriptor: FetchDescriptor<Model> = .init()) = #externalMacro(module: "FlexMacros", type: "FetchedMacro")

@attached(peer, names: suffixed(Fetcher))
@attached(accessor)
public macro Fetched() = #externalMacro(module: "FlexMacros", type: "FetchedMacro")

@attached(extension,
          conformances: View,
          names: named(body))
@attached(memberAttribute)
public macro Feature() = #externalMacro(module: "FlexMacros", type: "FeatureMacro")

@attached(peer,
          names: named(featureBox),
                 named(_featureBox),
                 named($featureBox),
                 named(feature),
                 named($feature)
)
@attached(body)
@attached(accessor, names: named(get))
public macro FeatureState() = #externalMacro(module: "FlexMacros", type: "FeatureStateMacro")

@attached(peer)
//public macro OnChange<T>(update keyPath: T) = #externalMacro(module: "FlexMacros", type: "OnChangeMacro")
public macro OnChange<F, T>(update keyPath: WritableKeyPath<F, T>) = #externalMacro(module: "FlexMacros", type: "OnChangeMacro")

//@attached(body)
//@attached(accessor, names: named(get))
//macro ChangeObserving() = #externalMacro(module: "FlexMacros", type: "ChangeObservingMacro")


//public extension View {
//    @MainActor
//    func sheet<Content: View>(
//        destination content: Binding<Content?>,
//        onDismiss: (() -> Void)? = nil
//    ) -> some View {
//        self.sheet(isPresented: Binding(get: {
//            content.wrappedValue != nil
//        }, set: { isPresented in
//            if !isPresented {
//                content.wrappedValue = nil
//            }
//        }), onDismiss: onDismiss, content: {
//            content.wrappedValue
//        })
//    }
//}
//
//@propertyWrapper @MainActor
//public struct Destination<V: View>: DynamicProperty {
//    public typealias DestinationBinding = Binding<V?>
//    @State private var value: V?
//    public var wrappedValue: V? {
//        get { value }
//        nonmutating set { value = newValue }
//    }
//    
//    public init(wrappedValue: V? = nil) {
//        self.wrappedValue = wrappedValue
//    }
//    
//    public var projectedValue: DestinationBinding {
//        $value
//    }
//}

//public extension Binding {
//    init(mainActorGet: @MainActor @escaping () -> Value, mainActorSet: @MainActor @escaping (Value) -> Void) {
//        self.init(get: { @MainActor in mainActorGet() },
//                  set: { @MainActor newValue in mainActorSet(newValue)})
//    }
//}

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
