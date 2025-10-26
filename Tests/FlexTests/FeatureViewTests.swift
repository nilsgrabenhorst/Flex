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
    
    @FeatureView
    public struct TestView {
        var viewModel: ViewModel
    
        @OnChange(update: \viewModel.counter)
        @State var counter = 0
    
        @OnChange(update: \viewModel.name)
        @State var name = "name"
    
        var presentation: some View {
            _ = viewModel.test()
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
                var viewModel: ViewModel
                @State var counter = 0
                @State var name = "name"
            
                var presentation: some View {
                    Text("test")
                }
            }
            
            extension TestView: FeatureView {
                public var body: some View {
                    presentation
                }
            }
            """#,
            macros: macros
        )
    }
}

@MainActor
private let macros: [String: Macro.Type] = [
    "FeatureView": FeatureViewMacro.self,
    "Updating": UpdatingMacro.self,
]
