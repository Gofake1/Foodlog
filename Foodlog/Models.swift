//
//  Models.swift
//  Foodlog
//
//  Created by David on 12/15/17.
//  Copyright © 2017 Gofake1. All rights reserved.
//

import Foundation
import RealmSwift

final class Food: Object {
    @objc dynamic var id = 0 //? Derive from barcode
    @objc dynamic var name = ""
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

final class FoodEntry: Object {
    @objc dynamic var id = 0
    @objc dynamic var date = Date()
    @objc dynamic var food: Food?
    @objc dynamic var name = ""
    @objc dynamic var numServings = 1
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

final class RecipeEntry: Object {
    @objc dynamic var id = 0
    @objc dynamic var date = Date()
    let ingredients = List<Food>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
