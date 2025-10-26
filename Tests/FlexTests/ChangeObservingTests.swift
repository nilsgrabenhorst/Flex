//
//  ChangeObservingTests.swift
//  Flex
//
//  Created by Nils Grabenhorst on 23.10.25.
//


//import XCTest
//import SwiftSyntaxMacros
//import SwiftSyntaxMacrosTestSupport
//import FlexMacros
//import Flex
//
//final class ChangeObservingTests: XCTestCase {
//    
//    let sample =
//    """
//    public struct TestView {
//        var presentation: some View {
//            Text("Hello")
//        }
//    }
//    """
//    
//    @MainActor
//    func testSimpleExpansionShouldBeCorrect() async throws {
//        assertMacroExpansion(
//            sample,
//            expandedSource:
//            """
//            public struct TestView {
//                var presentation: some View {
//                    Text("Hello")
//                }
//            
//                public var body: some View {
//                    presentation
//                }
//            }
//            """,
//            macros: macros
//        )
//    }
//}
//
//@MainActor
//private let macros: [String: Macro.Type] = [
//    "ChangeObserving": ChangeObservingMacro.self,
//]
