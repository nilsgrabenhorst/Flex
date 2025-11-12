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
        func makeFeature() -> ViewModel {
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
        
            func makeFeature() -> ViewModel {
                ViewModel()
            }
        
            var feature: ViewModel {
                guard let feature = featureBox.value else {
                    let feature = makeFeature()
                    featureBox.value = feature
                    return feature
                }
                return feature
            }
        
            @State private var featureBox = Box<ViewModel?>()
        
            var $feature: Binding<ViewModel> {
                Binding {
                    feature
                } set: { newValue in
                    self.featureBox.value = newValue
                }
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
