//
//  View+Sheet.swift
//  Flex
//
//  Created by Nils Grabenhorst on 5/2/25.
//

import SwiftUI

public extension View where Self: Presentation {
    func sheet<Destination: View>(destination: Binding<Destination?>, onDismiss: (() -> Void)? = nil) -> some View {
        let isPresented = Binding {
            destination.wrappedValue != nil
        } set: { isPresented in
            if !isPresented { destination.wrappedValue = nil }
        }

        return sheet(isPresented: isPresented, onDismiss: onDismiss) {
            if let destination = destination.wrappedValue {
                destination
            } else {
                EmptyView()
            }
        }
    }
}
