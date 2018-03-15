//
//  DataStore.swift
//  Foodlog
//
//  Created by David on 1/12/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import RealmSwift
import UIKit

final class DataStore {
    static let days                 = read { $0.objects(Day.self) }!
    static let foods                = read { $0.objects(Food.self) }!
    static let foodEntries          = read { $0.objects(FoodEntry.self) }!
    static let groups               = read { $0.objects(FoodGroupingTemplate.self) }!
    static let searchSuggestions    = read { $0.objects(SearchSuggestion.self) }!
    static let tags                 = read { $0.objects(Tag.self) }!
    private static var realm = try! Realm()
    
    static func object<A: Object, B>(_ type: A.Type, primaryKey: B) -> A? {
        return read { $0.object(ofType: type, forPrimaryKey: primaryKey) } ?? nil
    }
        
    static func update(_ object: Object) {
        write { $0.add(object, update: true) }
    }
    
    static func delete(_ object: Object, withoutNotifying tokens: [NotificationToken] = []) {
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
