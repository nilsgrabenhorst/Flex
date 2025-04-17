//
//  FeatureTests.swift
//  Flex
//
//  Created by Nils Grabenhorst on 4/6/25.
//

import XCTest
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import FlexMacros

final class FeatureTests: XCTestCase {
    let sample =
    """
    @Feature
    struct SomeFeature {
        private var counter = 0
        @Outlet var mutableName: String = "Sören"
        @Outlet private(set) var name: String = "Trudbert" {
            didSet { print(name) }
        }
        @Outlet private(set) var privateSetter: Int {
            get { counter }
            set { counter = newValue }
        }
        @Outlet var count: Int {
            get { counter }
            set { counter = newValue }
        }
        
        @Destination var destinationView: Text? = Text("Destination")
    }
    """
    
    @MainActor
    func testExpansionShouldBeCorrect() async throws {
        
        assertMacroExpansion(
            sample,
            expandedSource:
                    """
                    struct SomeFeature {
                        let name: String = "Trudbert"
                    }
                    """
            ,
            macros: testMacros
        )
    }
    
}

//struct FeatureTests {
//    @Test func testErrors() async throws {
//        // ...
//    }
//    
//    struct UseCase {
//        let sample =
//        """
//        @Feature
//        struct SomeFeature {
//            @Outlet let name = "Trudbert"
//        }
//        """
//        
//        @Test
//        func expansionShouldBeCorrect() async throws {
//            
//            assertMacroExpansion(
//                sample,
//                expandedSource:
//                    """
//                    
//                    struct SomeFeature {
//                        @Outlet let name = "Trudbert"
//                    }
//                    var outlets: Int { 42 }
//                    """
//                    ,
//                macros: testMacros
//            )
//        }
//    }
//}

let testMacros: [String: Macro.Type] = [
    "Outlet": OutletMacro.self,
    "Feature": FeatureMacro.self,
    "Presentation": PresentationMacro.self,
    "Action": ActionMacro.self,
//    "Destination": DestinationMacro.self,
]
