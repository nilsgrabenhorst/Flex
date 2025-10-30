//
//  FeatureStateTests.swift
//  Flex
//
//  Created by Nils Grabenhorst on 28.10.25.
//


import XCTest
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import FlexMacros
import Flex

final class FeatureStateTests: XCTestCase {
    
    let sample =
    """
    class ViewModel {
        var counter: Int
        var name = ""
        init(counter: Int) {
            self.counter = counter
        }
    }
    
    @FeatureView
    public struct TestView {
        var counter = 42
        @FeatureState
        var viewModel: ViewModel = ViewModel(counter: counter)
    
        var presentation: some View {
            Text("test")
        }
    }
    """
    
    @MainActor
    func testSimpleExpansionShouldBeCorrect() async throws {
        let expected =
        """
        class ViewModel {
            var counter: Int
            var name = ""
            init(counter: Int) {
                self.counter = counter
            }
        }
        public struct TestView {
            var counter = 42
            var viewModel: ViewModel {
                get {
                    guard let viewModel = viewModelBox.value else {
                        let viewModel = ViewModel(counter: counter)
                        self.viewModelBox.value = viewModel
                        return viewModel
                    }
                    return viewModel
                }
            }
        
            private var viewModelBoxState = State(initialValue: Box<ViewModel?>())
        
            private var viewModelBox: Box<ViewModel?> {
                viewModelBoxState.wrappedValue
            }
        
            var $viewModel: Binding<ViewModel> {
                Binding {
                    viewModel
                } set: { newValue in
                    self.viewModelBox.value = newValue
                }
            }
        
            var presentation: some View {
                Text("test")
            }
        }
        
        extension TestView : SwiftUI.View {
            public var body: some View {
                presentation
        
            }
        }
        """
        
        assertMacroExpansion(
            sample,
            expandedSource: expected,
            macros: macros
        )
    }
}

@MainActor
private let macros: [String: Macro.Type] = [
    "FeatureView": FeatureViewMacro.self,
    "OnChange": OnChangeMacro.self,
    "FeatureState": FeatureStateMacro.self,
]
