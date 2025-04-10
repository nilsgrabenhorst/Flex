import Flex
import SwiftUI

@Feature
struct CounterFeature {
    @State private var _counter = 0
    @State private var name = "Trudbert"
    
    @Outlet var count: Int { _counter }
    @Outlet var isResettable: Bool { _counter != 0 }
    @Outlet var greeting: String = "Hello"
    
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
        CounterView()
//                .environment(CounterFeatureActions(self))
//                .environment(CounterFeatureOutlets(self))
        
    }
}

@Presentation<CounterFeature>
struct CounterView: View {
    
    var body: some View {
        VStack {
            Text("\(outlets.count)")
            
            HStack {
                Button("-") {
//                    actions.decrement()
                }
                Button("+") {
//                    actions.increment()
                }
            }
            
            Button("reset") {
//                actions.reset()
            }
//            .disabled(!outlets.isResettable)
        }
    }
}

#Preview {
    CounterFeature()
        .padding()
}

