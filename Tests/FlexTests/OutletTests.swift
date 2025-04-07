//
//  OutletTests.swift
//  Flex
//
//  Created by Nils Grabenhorst on 4/6/25.
//

import Testing

struct OutletTests {
    @Test func testErrors() async throws {
        // ...
    }
    
    struct UseCase {
        let sample =
        """
        @Outlet let name = "Trudbert"
        """
        
        @Test
        func expansionShouldBeCorrect() async throws {
            
        }
    }
}
