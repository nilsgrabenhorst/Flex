//
//  LazyStateMacroTests.swift
//  Flex
//
//  Created by Nils Grabenhorst on 09.03.26.
//

import XCTest
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import FlexMacros
import Flex

final class LazyStateMacroTests: XCTestCase {
    
    let sample =
    #"""
    class ViewModel {
        var counter = 0
        var name = ""
    }
    
    public struct TestView {
        @LazyState
        var model: ViewModel = ViewModel()
    }
    """#
    
    @MainActor
    func testSimpleExpansionShouldBeCorrect() async throws {
        assertMacroExpansion(
            sample,
            expandedSource:
            #"""
            class ViewModel {
                var counter = 0
                var name = ""
            }
            
            public struct TestView {
                var model: ViewModel {
                    get {
                        _model
                    }
                }
            
                private var _model: ViewModel {
                    guard let viewModel = modelBox.value else {
                        let newViewModel = _makeViewModel()
                        modelBox.value = newViewModel
                        return newViewModel
                    }
                    return viewModel
                }
            
                @MainActor
                var $model: Binding<ViewModel> {
                    Binding {
                        _model
                    } set: { [modelBox] newValue in
                        modelBox.value = newValue
                    }
                }
            
                private var _modelBox = State(initialValue: Box<ViewModel?>())
            
                private var modelBox: Box<ViewModel?> {
                    _modelBox.wrappedValue
                }
            
                private var $modelBox: Binding<Box<ViewModel?>> {
                    _modelBox.projectedValue
                }
            
                private func _makeViewModel() -> ViewModel {
                    return ViewModel()
                }
            }
            """#,
            macros: macros
        )
    }
}

@MainActor
private let macros: [String: Macro.Type] = [
    "LazyState": LazyStateMacro.self,
]
