//
//  DataStore.swift
//  Foodlog
//
//  Created by David on 1/12/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import RealmSwift
import UIKit

class DataStore {
    private static var (realm, initError): (Realm?, Error?) = {
        do {
            return (try Realm(), nil)
        } catch {
            return (nil, error)
        }
    }()
    
    static func object<A: Object>(_ type: A.Type, at indexPath: IndexPath) -> A? {
        let objects = read { $0.objects(type) }
        return objects?[indexPath.item]
    }
    
    static func count<A: Object>(_ type: A.Type) -> Int {
        return read { $0.objects(type).count } ?? 0
    }
    
    static func add(_ object: Object) {
        write { $0.add(object) }
    }
    
    static func update(_ object: Object) {
        write { $0.add(object, update: true) }
    }
    
    static func onChange<A: Object>(_ type: A.Type, _ block: @escaping (RealmCollectionChange<Results<A>>) -> ())
        -> NotificationToken? {
        guard let results = read({ $0.objects(type) }) else { return nil }
        return results.observe(block)
    }
    
    private static func read<A>(_ block: (Realm) -> (A)) -> A? {
        guard let realm = realm else { UIApplication.shared.alert(error: initError!); return nil }
        return block(realm)
    }
    
    private static func write(_ block: @escaping (Realm) -> ()) {
        guard let realm = realm else { UIApplication.shared.alert(error: initError!); return }
        do {
            try realm.write { block(realm) }
        } catch {
            UIApplication.shared.alert(error: error)
        }
    }
}
