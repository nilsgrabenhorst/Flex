import Flex
import SwiftUI

@Feature
@MainActor
struct CounterFeature {
    let presentation = CounterView()
    
    @State private var counter = 0
    @State private var theName = "Trudbert"
    
    @Outlet private(set) var count: Int {
        get { counter }
        set { counter = newValue }
    }
    @Outlet var isResettable: Bool { counter != 0 }
    @Outlet var greeting: String = "Hi"
    @Outlet var canSetTo42: Bool { counter != 42 }
    
    @Outlet var name: String {
        get { theName }
        nonmutating set { theName = newValue }
    }
    
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
        theName = (name == "Trudbert") ? "Möpelkötter" : "Trudbert"
    }
    
    @Destination var destinationView: Text? = Text("Destination")
}

@Presentation<CounterFeature>
struct CounterView: View {
    var body: some View {
        VStack {
            Text("\(outlets.greeting), \(outlets.name)!")
            
            Divider()
                .padding(.vertical)
            
            HStack {
                Button("-") {
                    perform.decrement()
                }
                Spacer()
                Text("\(outlets.count)")
                Spacer()
                Button("+") {
                    perform.increment()
                }
            }.padding(.bottom)
            
            
            HStack {
                Button("reset") {
                    perform.reset()
                }
                .disabled(!outlets.isResettable)
                
                Spacer()
                
                Button("42") {
                    perform.set(42)
                }
                .disabled(!outlets.canSetTo42)
            }
            
            Divider()
                .padding(.vertical)
            
            TextField("Name", text: outlets.$name)
            
            Button("Change name") {
                perform.changeName()
            }
            
        }
        .frame(maxWidth: 100)
    }
}

#Preview {
    CounterFeature()
        .padding()
}

