import Flex
import SwiftUI

@Feature
struct CounterFeature {
    @State private var _counter = 0
    
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
    
    @MainActor
    var presentation: some View {
        MyPresentation()
            .environment(outs)
            .environment(ins)
    }
}

extension CounterFeature {
    @Observable
    class Outs {
        private let feature: CounterFeature
        
        init(feature: CounterFeature) {
            self.feature = feature
        }
        
        var count: Int { feature.count }
        var isResettable: Bool { feature.isResettable }
    }
    
    var outs: Outs { Outs(feature: self) }
}

extension CounterFeature {
    @Observable
    class Ins {
        private let feature: CounterFeature
        
        init(feature: CounterFeature) {
            self.feature = feature
        }
        
        func increment() {
            feature.increment()
        }
        
        func decrement() {
            feature.decrement()
        }
        
        func reset() {
            feature.reset()
        }
    }
    
    var ins: Ins { Ins(feature: self) }
}

struct MyPresentation: View {
    @Environment(CounterFeature.Outs.self) var outlets
    @Environment(CounterFeature.Ins.self) var actions
    
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
