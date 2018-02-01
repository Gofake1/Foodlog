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
    private static var realm = try! Realm()
    
    static func object<A: Object, B>(_ type: A.Type, primaryKey: B) -> A? {
        return read { $0.object(ofType: type, forPrimaryKey: primaryKey) } ?? nil
    }
    
    static func objects<A: Object>(_ type: A.Type) -> Results<A>? {
        return read { $0.objects(type) }
    }
    
    static func objects<A: Object>(_ type: A.Type, filteredBy predicate: NSPredicate) -> Results<A>? {
        return read { $0.objects(type).filter(predicate) }
    }
    
    static func objects<A: Object>(_ type: A.Type, sortedBy keyPath: String) -> Results<A>? {
        return read { $0.objects(type).sorted(byKeyPath: keyPath, ascending: false) }
    }
    
    static func count<A: Object>(_ type: A.Type) -> Int {
        return read { $0.objects(type).count } ?? 0
    }
    
    static func update(_ object: Object) {
        write { $0.add(object, update: true) }
    }
    
    static func delete(_ object: Object, withoutNotifying tokens: [NotificationToken]) {
        do {
            realm.beginWrite()
            realm.delete(object)
            try realm.commitWrite(withoutNotifying: tokens)
        } catch {
            UIApplication.shared.alert(error: error)
        }
    }
    
    private static func read<A>(_ block: (Realm) -> (A)) -> A? {
        return block(realm)
    }
    
    private static func write(_ block: @escaping (Realm) -> ()) {
        do {
            try realm.write { block(realm) }
        } catch {
            UIApplication.shared.alert(error: error)
        }
    }
}
