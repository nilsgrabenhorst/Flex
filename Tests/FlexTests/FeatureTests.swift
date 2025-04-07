//
//  FeatureTests.swift
//  Flex
//
//  Created by Nils Grabenhorst on 4/6/25.
//

import XCTest
//import Testing
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import FlexMacros

final class FeatureTests: XCTestCase {
    let sample =
    """
    @Feature
    struct SomeFeature {
        @Outlet let name = "Trudbert"
    }
    """
    
    func testExpansionShouldBeCorrect() async throws {
        
        assertMacroExpansion(
            sample,
            expandedSource:
                    """
                    struct SomeFeature {
                        let name = "Trudbert"
                    
                        var outlets: Int {
                            42
                        }
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
]
