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
import Flex

//@Feature
//struct MockFeature {
//    @State var _counter: Int = 0
//    
//    @Outlet var mutableStored: Int = 0
//    @Outlet private(set) var privateSetStored: Int = 0
//    @Outlet let constantStored: Int = 0
//    @Outlet var immutableComputed: Int { _counter }
//    @Outlet var mutableComputed: Int {
//        get { _counter }
//        nonmutating set { _counter = newValue }
//    }
//    
//    init<V: View>(presentation: V) {
//        self.presentation = AnyView(presentation)
//    }
//    
//    let presentation: AnyView
//}
//
//@Presentation<MockFeature>
//struct MockView: View {
//    var body: some View {
//        EmptyView()
//    }
//}
//
//struct FeatureTests {
//    @Test func outletBindingForStoredVar() async throws {
//        let presentation = MockView()
//        let feature = MockFeature(presentation: presentation)
//        
//        #expect(presentation.outlets.$readWrite != nil)
//    }
//}

final class FeatureTests: XCTestCase {
    let sample =
    """
    @Feature
    struct SomeFeature {
        init(value: Int) {
            self.storedConstantWithoutInitializer = value
            self.storedMutableWithoutInitializer = value
        }
    
        @State private var counter = 0
        @Outlet var storedMutable: String = "Sören"
        @Outlet let storedConstantWithoutInitializer: Int
        @Outlet var storedMutableWithoutInitializer: Int
        @Outlet private(set) var stored: String = "Trudbert" {
            didSet { print(name) }
        }
        @Outlet let storedConstant: String = "Trudbert"
        @Outlet private(set) var computedPrivateSet: Int {
            get { counter }
            nonmutating set { counter = newValue }
        }
        @Outlet var computedReadonly: Int { counter }
        @Outlet var computed: Int {
            get { counter }
            nonmutating set { counter = newValue }
        }
        
        @Destination var destinationView: Text? = Text("Destination")
    }
    """
    
    let simpleSample =
    """
    @Feature
    struct SomeFeature {
        @State var counter: Int = 0
        @Outlet var storedMutable: String = "Sören"
        @Outlet var computedMutable: Int {
            get { counter }
            nonmutating set { counter = newValue }
        }
    }
    
    @Presentation<SomeFeature>
    struct SomePresentation: View {
        var body: some View {
            Text("Hello")
        }
    }
    """
    
    @MainActor
    func testSimpleExpansionShouldBeCorrect() async throws {
        
        assertMacroExpansion(
            simpleSample,
            expandedSource:
                    """
                    struct SomeFeature {
                        var storedMutable: String {
                            get {
                                storedMutableStorage
                            }
                            nonmutating set {
                                storedMutableStorage = newValue
                            }
                        }

                        @State private var storedMutableStorage: String = "Sören"

                        var $storedMutable: Binding<String > {
                            $storedMutableStorage
                        }
                    }
                    """
            ,
            macros: testMacros
        )
    }
    
//    @MainActor
//    func testExpansionShouldBeCorrect() async throws {
//        
//        assertMacroExpansion(
//            sample,
//            expandedSource:
//                    """
//                    struct SomeFeature {
//                        let name: String = "Trudbert"
//                    }
//                    """
//            ,
//            macros: testMacros
//        )
//    }
    
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
