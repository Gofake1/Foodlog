//
//  CloudStore.swift
//  Foodlog
//
//  Created by David on 3/31/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

// TODO: Handle case when there are operations that are being retried and `impl` is no longer `WorkingImpl`
// TODO: Offer to migrate data when user changes iCloud accounts

import CloudKit

private let zoneId = CKRecordZoneID(zoneName: "Custom", ownerName: CKCurrentUserDefaultName)

/// Writes to cloud provider and syncs local data store.
final class CloudStore {
    private static let container = CKContainer(identifier: "iCloud.net.gofake1.Foodlog")
    private static var accountChangeHandler: (Error?) -> () = { _ in }
    /// Implementation is decided by user's iCloud account status
    private static var impl: CloudStoreImplType = DummyImpl()
    
    static func setup(onAccountChange accountChangeHandler: @escaping (Error?) -> ()) {
        CloudStore.accountChangeHandler = accountChangeHandler
        refreshAccountStatus()
        NotificationCenter.default.addObserver(self, selector: #selector(accountDidChange),
                                               name: .CKAccountChanged, object: nil)
    }
    
    static func received(remoteNotificationInfo info: [AnyHashable: Any], completionHandler: @escaping (Error?) -> ()) {
        let notification = CKNotification(fromRemoteNotificationDictionary: info)
        assert(notification.containerIdentifier == "iCloud.net.gofake1.Foodlog")
        assert(notification.subscriptionID == "private-changes")
        impl.fetchChanges(completion: completionHandler)
    }
    
    static func save(_ records: [CKRecord], completion completionHandler: @escaping (Error?) -> ()) {
        impl.modify(save: records, delete: [], completion: completionHandler)
    }
    
    static func delete(_ ids: [CKRecordID], completion completionHandler: @escaping (Error?) -> ()) {
        impl.modify(save: [], delete: ids, completion: completionHandler)
    }
    
    @objc private static func accountDidChange() {
        refreshAccountStatus()
    }
    
    private static func refreshAccountStatus() {
        container.accountStatus {
            if let error = $1 {
                impl = DummyImpl()
                accountChangeHandler(error)
            } else {
                switch $0 {
                case .couldNotDetermine:
                    fatalError()
                case .available:
                    let working = WorkingImpl(container)
                    working.reset {
                        if let error = $0 {
                            accountChangeHandler(error)
                        } else {
                            working.fetchChanges(completion: accountChangeHandler)
                        }
                    }
                    impl = working
                case .restricted:
                    impl = DummyImpl()
                    accountChangeHandler(AccountError.restricted)
                case .noAccount:
                    impl = DummyImpl()
                    accountChangeHandler(AccountError.noAccount)
                }
            }
        }
    }
}

extension CloudStore {
    enum AccountError: LocalizedError {
        case restricted
        case noAccount
        
        var errorDescription: String? {
            switch self {
            case .restricted:   return "The iCloud account is restricted."
            case .noAccount:    return "No iCloud account was found."
            }
        }
    }
    
    final class DummyImpl {}
    
    final class WorkingImpl {
        private let database: CKDatabase
        private let queue = DispatchQueue(label: "net.gofake1.Foodlog.CloudStore.WorkingImpl")
        private var zoneChangeToken: CKServerChangeToken? = {
            guard let data = UserDefaults.standard.value(forKey: "CustomZoneChangeToken") as? Data,
                let object = NSKeyedUnarchiver.unarchiveObject(with: data) else { return nil }
            return object as? CKServerChangeToken
            }() {
            didSet {
                if let token = zoneChangeToken {
                    let data = NSKeyedArchiver.archivedData(withRootObject: token)
                    UserDefaults.standard.set(data, forKey: "CustomZoneChangeToken")
                } else {
                    UserDefaults.standard.removeObject(forKey: "CustomZoneChangeToken")
                }
            }
        }
        
        init(_ container: CKContainer) {
            database = container.privateCloudDatabase
        }
        
        /// Create zone and subscription if they don't exist
        func reset(completion completionHandler: @escaping (Error?) -> ()) {
            // Check for existence of zone by fetching it
            func fetchPrivateChangesZone() {
                database.fetch(withRecordZoneID: zoneId) {
                    if let error = $1 as? CKError {
                        if let retryAfter = error.retryAfterSeconds {
                            _retry(fetchPrivateChangesZone, after: retryAfter)
                        } else if error.code == .networkUnavailable {
                            _retryWhenNetworkAvailable(fetchPrivateChangesZone)
                        } else if error.code == .zoneNotFound {
                            createPrivateChangesZone()
                        } else {
                            completionHandler(error)
                        }
                    } else {
                        fetchPrivateChangesSubscription()
                    }
                }
            }
            
            func createPrivateChangesZone() {
                let zone = CKRecordZone(zoneID: zoneId)
                database.save(zone) {
                    if let error = $1 as? CKError {
                        if let retryAfter = error.retryAfterSeconds {
                            _retry(createPrivateChangesZone, after: retryAfter)
                        } else if error.code == .networkUnavailable {
                            _retryWhenNetworkAvailable(createPrivateChangesZone)
                        } else {
                            completionHandler(error)
                        }
                    } else {
                        createPrivateChangesSubscription()
                    }
                }
            }
            
            // Check for existence of subscription by fetching it
            func fetchPrivateChangesSubscription() {
                database.fetch(withSubscriptionID: "private-changes") {
                    if let error = $1 as? CKError {
                        if let retryAfter = error.retryAfterSeconds {
                            _retry(fetchPrivateChangesSubscription, after: retryAfter)
                        } else if error.code == .networkUnavailable {
                            _retryWhenNetworkAvailable(fetchPrivateChangesSubscription)
                        } else {
                            // Note: CloudKit doesn't provide a code for "subscription not found", so we *assume*
                            // errors here indicate "subscription not found"
                            createPrivateChangesSubscription()
                        }
                    } else {
                        completionHandler(nil)
                    }
                }
            }
            
            func createPrivateChangesSubscription() {
                let notificationInfo = CKNotificationInfo()
                notificationInfo.shouldSendContentAvailable = true
                let subscription = CKRecordZoneSubscription(zoneID: zoneId, subscriptionID: "private-changes")
                subscription.notificationInfo = notificationInfo
                database.save(subscription) {
                    if let error = $1 as? CKError {
                        if let retryAfter = error.retryAfterSeconds {
                            _retry(createPrivateChangesSubscription, after: retryAfter)
                        } else if error.code == .networkUnavailable {
                            _retryWhenNetworkAvailable(createPrivateChangesSubscription)
                        } else {
                            completionHandler(error)
                        }
                    } else {
                        completionHandler(nil)
                    }
                }
            }
            
            fetchPrivateChangesZone()
        }
    }
}

protocol CloudStoreImplType {
    func fetchChanges(completion completionHandler: @escaping (Error?) -> ())
    func modify(save toSave: [CKRecord], delete toDelete: [CKRecordID],
                completion completionHandler: @escaping (Error?) -> ())
    func repair(completion completionHandler: @escaping (Error?) -> ())
}

extension CloudStore.DummyImpl: CloudStoreImplType {
    func fetchChanges(completion completionHandler: @escaping (Error?) -> ()) {
        completionHandler(nil)
    }
    
    func modify(save toSave: [CKRecord], delete toDelete: [CKRecordID],
                completion completionHandler: @escaping (Error?) -> ())
    {
        completionHandler(nil)
    }
    
    func repair(completion completionHandler: @escaping (Error?) -> ()) {
        completionHandler(nil)
    }
}

extension CloudStore.WorkingImpl: CloudStoreImplType {
    func fetchChanges(completion completionHandler: @escaping (Error?) -> ()) {
        let sync = Sync()
        let options = CKFetchRecordZoneChangesOptions()
        options.previousServerChangeToken = zoneChangeToken
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [zoneId],
                                                          optionsByRecordZoneID: [zoneId: options])
        operation.recordChangedBlock = { [queue] record in
            print("record changed", record.recordType, record.recordID.recordName) //*
            queue.async { sync.change(record) }
        }
        operation.recordWithIDWasDeletedBlock = { [queue] recordId, recordType in
            print("record deleted", recordType, recordId.recordName) //*
            queue.async { sync.delete(recordType, recordId) }
        }
        operation.recordZoneChangeTokensUpdatedBlock = { [weak self] in
            assert($0 == zoneId)
            if let token = self!.zoneChangeToken {
                if let lastClientToken = $2 {
                    assert(lastClientToken == NSKeyedArchiver.archivedData(withRootObject: token))
                }
            } else {
                assert($2 == nil)
            }
            self!.zoneChangeToken = $1
        }
        operation.recordZoneFetchCompletionBlock = { [weak self] in
            assert($0 == zoneId)
            if let error = $4 {
                // TODO: Handle errors
                print(error) //*
                fatalError() //*
            } else {
                self!.zoneChangeToken = $1
            }
        }
        operation.fetchRecordZoneChangesCompletionBlock = { [queue] in
            if let error = $0 as? CKError {
                if let retryAfter = error.retryAfterSeconds {
                    _retry({ [weak self] in self!.fetchChanges(completion: completionHandler) }, after: retryAfter)
                } else if error.code == .networkUnavailable {
                    _retryWhenNetworkAvailable { [weak self] in self!.fetchChanges(completion: completionHandler) }
                } else if error.code == .changeTokenExpired {
                    // TODO: Replace local data with server's data
                    fatalError() //*
                } else {
                    completionHandler(error)
                }
            } else {
                queue.async { DispatchQueue.main.async { sync.process(completion: completionHandler) }}
            }
        }
        database.add(operation)
    }
    
    func modify(save toSave: [CKRecord], delete toDelete: [CKRecordID],
                completion completionHandler: @escaping (Error?) -> ())
    {
        let operation = CKModifyRecordsOperation(recordsToSave: toSave, recordIDsToDelete: toDelete)
        operation.savePolicy = .changedKeys
        operation.modifyRecordsCompletionBlock = { [weak self] in
            if let error = $2 as? CKError {
                if let retryAfter = error.retryAfterSeconds {
                    _retry({ self!.modify(save: toSave, delete: toDelete, completion: completionHandler) },
                           after: retryAfter)
                } else if error.code == .networkUnavailable {
                    _retryWhenNetworkAvailable {
                        self!.modify(save: toSave, delete: toDelete, completion: completionHandler)
                    }
                } else if error.code == .limitExceeded {
                    // TODO: Limit exceeded
                    fatalError() //*
                } else if error.code == .userDeletedZone {
                    self!.reset {
                        if let error = $0 {
                            completionHandler(error)
                        } else {
                            self!.repair(completion: completionHandler)
                        }
                    }
                } else {
                    completionHandler(error)
                }
            } else {
                completionHandler(nil)
            }
        }
        database.add(operation)
    }
    
    func repair(completion completionHandler: @escaping (Error?) -> ()) {
        // TODO: Repair server records
        print("Not implemented") //*
        completionHandler(nil)
    }
}

extension Food {
    var ckRecordId: CKRecordID {
        return CKRecordID(recordName: id, zoneID: zoneId)
    }
}

extension FoodEntry {
    var ckRecordId: CKRecordID {
        return CKRecordID(recordName: id, zoneID: zoneId)
    }
}

extension FoodGroupingTemplate {
    var ckRecordId: CKRecordID {
        return CKRecordID(recordName: id, zoneID: zoneId)
    }
}

extension Tag {
    var ckRecordId: CKRecordID {
        return CKRecordID(recordName: id, zoneID: zoneId)
    }
}
