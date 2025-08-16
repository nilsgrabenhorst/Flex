//
//  FetchedMacroTests.swift
//  Flex
//
//  Created by Nils Grabenhorst on 14.08.25.
//

import XCTest
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import FlexMacros
import Flex
import SwiftData

@Model
private final class TestModel {
    init() {}
}

final class FetchedTests: XCTestCase {
    
    let sample =
    """
    struct SomeFeature {
        @Fetched var objects: [TestModel]
    }
    """
    
    @MainActor
    func testSimpleExpansionShouldBeCorrect() async throws {
        
        assertMacroExpansion(
            sample,
            expandedSource:
            """
            struct SomeFeature {
                var objects: [TestModel] {
                    get {
                        objectsFetcher.results
                    }
                }
            
                private let objectsFetcher: Fetcher<TestModel> = .init()
            }
            """,
            macros: macros
        )
    }
}

private let macros: [String: Macro.Type] = [
    "Fetched": FetchedMacro.self,
]
