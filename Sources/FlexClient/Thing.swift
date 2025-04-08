import Flex
import SwiftUI

@Feature
struct CounterFeature {
    
    @State private var _counter = 0
    @State private var name = "Trudbert"
    
    @Outlet var count: Int { _counter }
    @Outlet var isResettable: Bool { _counter != 0 }
    
    func increment() {
        _counter += 1
    }
    
    func decrement() {
        _counter -= 1
    }
    
    func reset() {
        _counter = 0
    }
    
    func changeName() {
        name = (name == "Trudbert") ? "Möpelkötter" : "Trudbert"
    }
    
    @MainActor
    var presentation: some View {
        MyPresentation()
            .environment(FeatureBox(self))
    }
}

@Observable
class FeatureBox<F: CounterFeatureOutlets & CounterFeatureActions> {
    private let feature: F!
    
    init(_ feature: F?) {
        self.feature = feature
    }
    
    var outlets: CounterFeatureOutlets { feature }
    var actions: CounterFeatureActions { feature }
}

protocol CounterFeatureOutlets {
    var count: Int { get }
    var isResettable: Bool { get }
}

protocol CounterFeatureActions {
    func increment()
    func decrement()
    func reset()
}

extension CounterFeature: CounterFeatureOutlets {}
extension CounterFeature: CounterFeatureActions {}

struct MyPresentation: View {
    @Environment(FeatureBox<CounterFeature>.self) private var _feature
    var outlets: CounterFeatureOutlets { _feature.outlets }
    var actions: CounterFeatureActions { _feature.actions }
    
    var body: some View {
        VStack {
            Text("\(outlets.count)")
            
            HStack {
                Button("-") {
                    actions.decrement()
                }
                Button("+") {
                    actions.increment()
                }
            }
            
            Button("reset") {
                actions.reset()
            }.disabled(!outlets.isResettable)
        }
    }
}

#Preview {
    CounterFeature()
        .padding()
}
