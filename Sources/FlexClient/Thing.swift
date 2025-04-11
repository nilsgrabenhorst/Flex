import Flex
import SwiftUI

@Feature
struct CounterFeature {
    let presentation = CounterView()
    
    @State private var counter = 0
    @State private var name = "Trudbert"
    
    @Outlet var count: Int { counter }
    @Outlet var isResettable: Bool { counter != 0 }
    @Outlet var greeting: String = "Hello"
    @Outlet var canSetTo42: Bool { counter != 42 }
    
    @Action
    func increment() { counter += 1 }
    
    @Action
    func decrement() { counter -= 1 }
    
    @Action
    func reset() { counter = 0 }
    
    @Action
    func set(_ value: Int) { counter = value }
    
    @Action
    func changeName() {
        name = (name == "Trudbert") ? "Möpelkötter" : "Trudbert"
    }
}

@Presentation<CounterFeature>
struct CounterView: View {
    var body: some View {
        VStack {
            HStack {
                Button("-") {
                    actions.decrement()
                }
                Spacer()
                Text("\(outlets.count)")
                Spacer()
                Button("+") {
                    actions.increment()
                }
            }
            
            Divider()
                .padding(.vertical)
            
            HStack {
                Button("reset") {
                    actions.reset()
                }
                .disabled(!outlets.isResettable)
                
                Spacer()
                
                Button("42") {
                    actions.set(42)
                }
                .disabled(!outlets.canSetTo42)
            }
            
            Button("Change name") {
                actions.changeName()
            }
        }
        .frame(maxWidth: 100)
    }
}

#Preview {
    CounterFeature()
        .padding()
}

