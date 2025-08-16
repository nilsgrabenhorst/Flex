//
//  Fetcher.swift
//  Flex
//
//  Created by Nils Grabenhorst on 14.08.25.
//

import SwiftData
import OSLog
import Observation
import FactoryKit

// TODO: Get rid of Combine
@unsafe @preconcurrency import Combine

// ???: We could share fetchers w/ same FetchDescriptor... See ``ActiveFetchers``

@MainActor
@Observable
public final class Fetcher<Model: PersistentModel> {
    @ObservationIgnored @Injected(\.dataMonitor)
    private var monitor
    
    @ObservationIgnored
    private var cancellables: Set<AnyCancellable> = []
    
    private let context: ModelContext
    private let fetchDescriptor: FetchDescriptor<Model>
    private let logger = Logger(subsystem: "Domain", category: "\(Fetcher.self)")
    public private(set) var results: [Model] = []
    
    public init(fetchDescriptor: FetchDescriptor<Model> = FetchDescriptor<Model>()) {
        self.fetchDescriptor = fetchDescriptor
        @Injected(\.mainContext) var context
        self.context = context
        fetch()
        subscribe()
    }
    
    private func subscribe() {
        Task {
            await monitor.$transactions
                .compactMap(\.self)
                .sink { [weak self] (transactions: [DefaultHistoryTransaction]) in
                    guard let self else { return }
                    Task { @MainActor in
                        if isAffected(by: transactions) {
                            logger.debug("there are changes for \(Model.self).")
                            // ???: Maybe there is a more efficient way to update wrappedValue.
                            // For now, let's just fetch agein. It's probably OK due to caching.
                            fetch()
                        }
                    }
                }
                .store(in: &cancellables)
        }
    }
    
    private func isAffected(by transactions: [DefaultHistoryTransaction]) -> Bool {
        transactions
            .flatMap(\.changes)
            .map(\.changedPersistentIdentifier)
            .map { identifier in context.model(for: identifier) }
            .contains { changedModel in changedModel is Model }
    }
    
    private func fetch() {
        logger.debug("Fetching \(Model.self)...")
        do {
            results = try context.fetch(fetchDescriptor)
        } catch {
            print("Error fetching objects: \(error)")
            results = []
        }
    }
}
