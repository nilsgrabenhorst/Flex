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
    class ViewModel {}
    
    public struct TestView {
        var counter = 42
    
        @FeatureState
        func makeViewModel() -> ViewModel {
            ViewModel()
        }
    }
    """
    
    @MainActor
    func testSimpleExpansionShouldBeCorrect() async throws {
        let expected =
        """
        class ViewModel {}
        
        public struct TestView {
            var counter = 42
            func makeViewModel() -> ViewModel {
                ViewModel()
            }
        
            var viewModel: ViewModel {
                guard let viewModel = viewModelBox.value else {
                    let newViewModel = makeViewModel()
                    viewModelBox.value = newViewModel
                    return newViewModel
                }
                return viewModel
            }
        
            @MainActor
            var $viewModel: Binding<ViewModel> {
                Binding {
                    viewModel
                } set: { [viewModelBox] newValue in
                    viewModelBox.value = newValue
                }
            }
        
            private var _viewModelBox = State(initialValue: Box<ViewModel?>())
        
            private var viewModelBox: Box<ViewModel?> {
                _viewModelBox.wrappedValue
            }
        
            private var $viewModelBox: Binding<Box<ViewModel?>> {
                _viewModelBox.projectedValue
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
    "FeatureView": FeatureMacro.self,
    "OnChange": OnChangeMacro.self,
    "FeatureState": FeatureStateMacro.self,
]
