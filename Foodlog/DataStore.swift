//
//  DataStore.swift
//  Foodlog
//
//  Created by David on 1/12/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import RealmSwift

final class DataStore {
    static let days                 = realm.objects(Day.self)
    static let foodEntries          = realm.objects(FoodEntry.self)
    static let searchSuggestions    = realm.objects(SearchSuggestion.self)
    static let tags                 = realm.objects(Tag.self)
    private static var realm = try! Realm()
    
    static func object<A: Object, B>(_ type: A.Type, primaryKey: B) -> A? {
        return realm.object(ofType: type, forPrimaryKey: primaryKey)
    }
        
    static func update(_ objects: [Object], completion completionHandler: @escaping (Error?) -> ()) {
        do {
            try realm.write { realm.add(objects, update: true) }
        } catch {
            completionHandler(error)
        }
        completionHandler(nil)
    }
    
    static func delete(_ objects: [Object], withoutNotifying tokens: [NotificationToken] = [],
                       completion completionHandler: @escaping (Error?) -> ())
    {
        realm.beginWrite()
        realm.delete(objects)
        do {
            try realm.commitWrite(withoutNotifying: tokens)
        } catch {
            completionHandler(error)
        }
        completionHandler(nil)
    }
}
