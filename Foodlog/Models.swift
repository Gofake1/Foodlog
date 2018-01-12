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
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var name = ""
    @objc dynamic var picture: String? //*
    @objc dynamic var healthKitStatus = 0 //*
    @objc dynamic var calories = 0
    @objc dynamic var totalFat = 0
    @objc dynamic var saturatedFat = 0
    @objc dynamic var monounsaturatedFat = 0
    @objc dynamic var polyunsaturatedFat = 0
    @objc dynamic var transFat = 0
    @objc dynamic var cholesterol = 0
    @objc dynamic var sodium = 0
    @objc dynamic var totalCarbohydrate = 0
    @objc dynamic var dietaryFiber = 0
    @objc dynamic var sugars = 0
    @objc dynamic var protein = 0
    @objc dynamic var vitaminA = 0
    @objc dynamic var vitaminB6 = 0
    @objc dynamic var vitaminB12 = 0
    @objc dynamic var vitaminC = 0
    @objc dynamic var vitaminD = 0
    @objc dynamic var vitaminE = 0
    @objc dynamic var vitaminK = 0
    @objc dynamic var calcium = 0
    @objc dynamic var iron = 0
    
    override static func indexedProperties() -> [String] {
        return ["name"]
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

final class FoodEntry: Object {
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var date = Date()
    @objc dynamic var food: Food?
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
