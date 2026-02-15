//
//  FeatureViewTests.swift
//  Flex
//
//  Created by Nils Grabenhorst on 22.10.25.
//

import XCTest
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import FlexMacros
import Flex

final class FeatureViewTests: XCTestCase {
    
    let sample =
    #"""
    class ViewModel {
        var counter = 0
        var name = ""
    }
    
    @Feature
    public struct TestView {
        private var viewModel: ViewModel
    
        @OnChange(update: \ViewModel.counter)
        @State var counter = 0
    
        @OnChange(update: \ViewModel.name)
        @State var name = "name"
    
        private func makeViewModel() -> ViewModel {
            ViewModel()
        }
    
        private var presentation: some View {
            Text("test")
        }
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
                private var viewModel: ViewModel
                @State var counter = 0
                @State var name = "name"
                @FeatureState
            
                private func makeViewModel() -> ViewModel {
                    ViewModel()
                }
            
                private var presentation: some View {
                    Text("test")
                }
            }
            
            extension TestView: View {
                public var body: some View {
                    presentation
                    .onChange(of: counter) { _, newValue in
                        viewModel.counter = newValue
                    }
                    .onChange(of: name) { _, newValue in
                        viewModel.name = newValue
                    }
            
                }
            }
            """#,
            macros: macros
        )
    }
}

@MainActor
private let macros: [String: Macro.Type] = [
    "Feature": FeatureMacro.self,
    "OnChange": OnChangeMacro.self,
]
