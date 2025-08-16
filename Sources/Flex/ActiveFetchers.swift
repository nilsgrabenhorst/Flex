//
//  ActiveFetchers.swift
//  Flex
//
//  Created by Nils Grabenhorst on 14.08.25.
//

import Foundation
import FoundationSwings
import SwiftData

// OK to add @retroactive conformance because We own the `DefaultsValue`
// protocol. Unlikely that Apple adds conformance in the future ;-)
extension DefaultHistoryToken: @retroactive DefaultsValue {}

@MainActor
final class ActiveFetchers<Model: PersistentModel> {
    struct WeakBox<T: AnyObject> {
        weak var value: T?
        init(_ value: T) {
            self.value = value
        }
    }
    
    init() {}
    
    private var fetchers: [FetchDescriptorKey<Model>: WeakBox<Fetcher<Model>>] = [:]
    
    func fetcher(for fetchDescriptor: FetchDescriptor<Model>) -> Fetcher<Model> {
        let key = FetchDescriptorKey(fetchDescriptor)
        if let existing = fetchers[key]?.value {
            return existing
        }
        let newFetcher = Fetcher(fetchDescriptor: fetchDescriptor)
        fetchers[key] = WeakBox(newFetcher)
        return newFetcher
    }
    
    subscript (_ fetchDescriptor: FetchDescriptor<Model>) -> Fetcher<Model> {
        fetcher(for: fetchDescriptor)
    }
}

struct FetchDescriptorKey<T: PersistentModel>: Hashable {
    init(_ fetchDescriptor: FetchDescriptor<T>) {
        self.fetchDescriptor = fetchDescriptor
    }
    let fetchDescriptor: FetchDescriptor<T>

    func hash(into hasher: inout Hasher) {
        if let predicate = fetchDescriptor.predicate {
            do {
                let predicateData = try JSONEncoder().encode(predicate)
                hasher.combine(predicateData)
            } catch {
                fatalError()
            }
        }
        
        for sortDescriptor in fetchDescriptor.sortBy {
            hasher.combine(sortDescriptor)
        }
        
        hasher.combine(fetchDescriptor.fetchLimit)
        hasher.combine(fetchDescriptor.fetchOffset)
        hasher.combine(fetchDescriptor.includePendingChanges)
        for relationship in fetchDescriptor.relationshipKeyPathsForPrefetching {
            hasher.combine(relationship)
        }
        for properties in fetchDescriptor.propertiesToFetch {
            hasher.combine(properties)
        }
    }
}
