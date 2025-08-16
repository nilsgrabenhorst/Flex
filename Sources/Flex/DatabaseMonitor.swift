//
//  DatabaseMonitor.swift
//  Flex
//
//  Created by Nils Grabenhorst on 14.08.25.
//

import Foundation
import FoundationSwings
import FactoryKit
import SwiftData
import OSLog
@unsafe @preconcurrency import Combine

extension Container {
    var modelContainer: Factory<ModelContainer> {
        self {
            fatalError("No modelContainer has been set. Call Flex.setModelContainer(_:) first.")
        }
    }
    
    @MainActor
    var mainContext: Factory<ModelContext> {
        self { @MainActor in
            self.modelContainer.resolve().mainContext
        }
    }
    
    public var dataMonitor: Factory<DatabaseMonitor> {
        self {
            DatabaseMonitor()
        }
    }
    
    @MainActor
    func activeFetchers<Model: PersistentModel>() -> Factory<ActiveFetchers<Model>> {
        self { @MainActor in
            ActiveFetchers<Model>()
        }.cached
    }
    
    @MainActor
    func fetcher<Model: PersistentModel>() -> ParameterFactory<FetchDescriptor<Model>, Fetcher<Model>> {
        self { @MainActor in
            let activeFetchers: ActiveFetchers<Model> = self.activeFetchers().resolve()
            return activeFetchers[$0]
        }.unique
    }
}

public func setModelContainer(_ modelContainer: ModelContainer) {
    Container.shared.modelContainer.register {
        modelContainer
    }.cached
}

@ModelActor
public actor DatabaseMonitor {
    deinit {
        print("K THX BYE (Database monitor)")
    }
    
    private enum Constants {
        static let lastHistoryToken = "lastHistoryToken"
    }
    
    let logger = Logger(subsystem: "Domain", category: "Database")
    
    @DefaultsPersisted(key: Constants.lastHistoryToken)
    private var historyToken: DefaultHistoryToken?
    
    // TODO: Use AsyncAlgorithm's share() once available
    // See pitch at https://forums.swift.org/t/kickoff-of-a-new-season-of-development-for-asyncalgorithms-share/
    @MainActor
    @Published public var transactions: [DefaultHistoryTransaction]?
    
    init() {
        @Injected(\.modelContainer) var container
        self.init(modelContainer: container)
        subscribeToPersistentStoreChangeNotifications()
    }
    
    public func deleteHistoryToken() {
        historyToken = nil
    }
    
    /// Subscribes to persistent history tracking notifications
    nonisolated func subscribeToPersistentStoreChangeNotifications(/* excludeAuthors: [String] = [] */) {
        Task { [weak self, logger] in
            for await unsafe _ in NotificationCenter.default
                .notifications(named: .NSPersistentStoreRemoteChange)
                .map({ _ in () }) {
                do {
                    try await self?.processNewTransactions()
                } catch {
                    logger.error("Error processing transactions: \(error, privacy: .public)")
                }
            }
        }
    }
    
    func processNewTransactions() throws {
        logger.debug("Processing new transactions...")
        let lastToken = historyToken
        logger.debug("Last token: \(String(describing: lastToken))")
        let transactions = findTransactions(after: lastToken)
        let (updatedModelIds, newHistoryToken) = findUpdatedModelIds(in: transactions)
        if let newHistoryToken {
            historyToken = newHistoryToken
        }
        if let lastToken {
            // TODO: Clean up without screwing up other monitors!
//            try deleteTransactions(before: lastToken)
        }
        Task { @MainActor in
            self.transactions = transactions
        }
        // TODO: Do something with the updated model IDs
    }
    
    private func findTransactions(after token: DefaultHistoryToken?) -> [DefaultHistoryTransaction] {
        var historyDescriptor = HistoryDescriptor<DefaultHistoryTransaction>()
        if let token {
            do {
                let fullHistoryDescriptor = HistoryDescriptor<DefaultHistoryTransaction>()
                let allTransactions = try! modelContext.fetchHistory(fullHistoryDescriptor)
                let existingTokenJSON: String = try! String(data: JSONEncoder().encode(token), encoding: .utf8)!
                for transaction in allTransactions {
                    let newTokenJSON: String = try! String(data: JSONEncoder().encode(transaction.token), encoding: .utf8)!
                    logger.info(
                    """
                    Existing token: \(existingTokenJSON)
                    Transaction token: \(newTokenJSON)
                    \(transaction.token > token ? "new transaction" : "old transaction")
                    """
                    )
                }
            }
            
            historyDescriptor.predicate = #Predicate { transaction in
                (transaction.token > token)
            }
        }

        do {
            return try modelContext.fetchHistory(historyDescriptor)
        } catch {
            logger.error("Error fetching history transactions \(error, privacy: .public)")
            return []
        }
    }

    private func deleteTransactions(before token: DefaultHistoryToken) throws {
        var descriptor = HistoryDescriptor<DefaultHistoryTransaction>()
        descriptor.predicate = #Predicate { $0.token < token }

        let context = ModelContext(modelContainer)
        try context.deleteHistory(descriptor)
    }
    
    private func findUpdatedModelIds(in transactions: [DefaultHistoryTransaction]) -> (Set<UUID>, DefaultHistoryToken?) {
        let taskContext = ModelContext(modelContainer)
        var updatedModelIds: Set<UUID> = []
        logger.debug("\(transactions.count) Transactions:")
        for transaction in transactions {
            for change in transaction.changes {
                switch change {
                case .insert(let insertion):
                    logger.debug("Inserted \(insertion.changedPersistentIdentifier.entityName)")
                case .update(let update):
                    logger.debug("Updated \(update.changedPersistentIdentifier.entityName)")
                case .delete(let deletion):
                    logger.debug("Deleted \(deletion.changedPersistentIdentifier.entityName)")
                @unknown default:
                    logger.warning("Unknown kind of change!!!")
                }
                
//                let transactionModifiedID = change.changedPersistentIdentifier
//                let fetchDescriptor = FetchDescriptor<SongArtworkViewModel>(predicate: #Predicate { model in
//                    model.persistentModelID == transactionModifiedID
//                })
//                let fetchResults = try? taskContext.fetch(fetchDescriptor)
//                guard let matchedModel = fetchResults?.first else {
//                    continue
//                }
//                switch change {
//                case .insert(_ as DefaultHistoryInsert<SongArtworkViewModel>):
//                    break
//                case .update(_ as DefaultHistoryUpdate<SongArtworkViewModel>):
//                    updatedModelIds.update(with: matchedModel.id)
//                case .delete(_ as DefaultHistoryDelete<SongArtworkViewModel>):
//                    updatedModelIds.update(with: matchedModel.id)
//                default: break
//                }
            }
        }
        return (updatedModelIds, transactions.last?.token)
    }
}
