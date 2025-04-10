//
//  PresentationTests.swift
//  Flex
//
//  Created by Nils Grabenhorst on 4/10/25.
//

import XCTest
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import FlexMacros

final class PresentationTests: XCTestCase {
    let sample =
    """
    @Feature
    struct SomeFeature {
        @Outlet let name: String = "Trudbert"
    }
    
    @Presentation<SomeFeature>
    struct SomePresentation: View {
    
    }
    """
    
    func testExpansionShouldBeCorrect() async throws {
        
        assertMacroExpansion(
            sample,
            expandedSource:
                    """
                    
                    """
            ,
            macros: testMacros
        )
    }
}
