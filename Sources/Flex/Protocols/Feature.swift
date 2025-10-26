//
//  Feature.swift
//  Flex
//
//  Created by Nils Grabenhorst on 08.10.25.
//

import SwiftUI

@MainActor
public protocol Feature: View {
    associatedtype Presentation: View
    associatedtype Feature: AnyObject
    
    var feature: Feature { get }
    var presentation: Presentation { get }
}

/*
@MainActor
public protocol Feature: AnyObject {
    associatedtype Presentation: PresentationView where Presentation.F == Self
    associatedtype V: FeatureView where V.F == Self
    var view: V { get }
    var presentation: Presentation { get }
}

@MainActor
public protocol FeatureView: View {
    associatedtype F: Feature
    var feature: F { get }
    init(feature: F)
}

@MainActor
public protocol PresentationView: View {
    associatedtype F: Feature
    var feature: F { get }
    init(feature: F)
}

extension FeatureView {
    public var body: F.Presentation {
        feature.presentation
    }
}

extension Feature {
    public var View: V {
        V(feature: self)
    }
}
*/
