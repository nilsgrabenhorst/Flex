//
//  Box.swift
//  Flex
//
//  Created by Nils Grabenhorst on 30.10.25.
//

@Observable
public class Box<T> {
    public var value: T
    
    public init( _ value: T ) {
        self.value = value
    }
}

public extension Box where T: ExpressibleByNilLiteral {
    convenience init() {
        self.init(nil)
    }
}
