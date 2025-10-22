//
//  Observing.swift
//  Flex
//
//  Created by Nils Grabenhorst on 14.10.25.
//

import Foundation
import Observation

@propertyWrapper
@Observable
public class Observing<T> {
    public var wrappedValue: T
    
    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
    
    public var projectedValue: Observing<T> { self }
}
