//
//  Models.swift
//  Foodlog
//
//  Created by David on 12/15/17.
//  Copyright © 2017 Gofake1. All rights reserved.
//

import Foundation
import RealmSwift

final class SearchSuggestion: Object {
    enum Kind: Int {
        case food   = 0
        case group  = 1
        case tag    = 2
    }
    
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var kindRaw = -1
    @objc dynamic var lastUsed = Date()
    @objc dynamic var text = ""
    
    let foods = LinkingObjects(fromType: Food.self, property: "searchSuggestion")
    let groups = LinkingObjects(fromType: FoodGroupingTemplate.self, property: "searchSuggestion")
    let tags = LinkingObjects(fromType: Tag.self, property: "searchSuggestion")
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func indexedProperties() -> [String] {
        return ["lastUsed", "text"]
    }
}

final class Tag: Object {
    enum ColorCode: Int {
        case lightGray  = 0
        case red        = 1
        case orange     = 2
        case yellow     = 3
        case green      = 4
        case blue       = 5
        case purple     = 6
    }
    
    @objc dynamic var name = ""
    @objc dynamic var colorCodeRaw = ColorCode.lightGray.rawValue
    @objc dynamic var searchSuggestion: SearchSuggestion?
    let foods = LinkingObjects(fromType: Food.self, property: "tags")
    let foodEntries = LinkingObjects(fromType: FoodEntry.self, property: "tags")
    
    override static func primaryKey() -> String? {
        return "name"
    }
}

final class Food: Object {
    enum MeasurementRepresentation: Int {
        case serving    = 0
        case milligram  = 1
        case gram       = 2
        case ounce      = 3
        case pound      = 4
        case fluidOunce = 5
    }
    
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var name = ""
    @objc dynamic var searchSuggestion: SearchSuggestion?
    @objc dynamic var measurementRepresentationRaw = MeasurementRepresentation.serving.rawValue
    @objc dynamic var picture: String? //*
    @objc dynamic var calories = Float(0.0)
    @objc dynamic var totalFat = Float(0.0)
    @objc dynamic var saturatedFat = Float(0.0)
    @objc dynamic var monounsaturatedFat = Float(0.0)
    @objc dynamic var polyunsaturatedFat = Float(0.0)
    @objc dynamic var transFat = Float(0.0)
    @objc dynamic var cholesterol = Float(0.0)
    @objc dynamic var sodium = Float(0.0)
    @objc dynamic var totalCarbohydrate = Float(0.0)
    @objc dynamic var dietaryFiber = Float(0.0)
    @objc dynamic var sugars = Float(0.0)
    @objc dynamic var protein = Float(0.0)
    @objc dynamic var vitaminA = Float(0.0)
    @objc dynamic var vitaminB6 = Float(0.0)
    @objc dynamic var vitaminB12 = Float(0.0)
    @objc dynamic var vitaminC = Float(0.0)
    @objc dynamic var vitaminD = Float(0.0)
    @objc dynamic var vitaminE = Float(0.0)
    @objc dynamic var vitaminK = Float(0.0)
    @objc dynamic var calcium = Float(0.0)
    @objc dynamic var iron = Float(0.0)
    @objc dynamic var magnesium = Float(0.0)
    @objc dynamic var potassium = Float(0.0)
    let entries = LinkingObjects(fromType: FoodEntry.self, property: "food")
    let tags = List<Tag>()
    var measurementRepresentation: MeasurementRepresentation {
        return MeasurementRepresentation(rawValue: measurementRepresentationRaw)!
    }
    
    // HealthKit future-proofing, currently unused
    @objc dynamic var biotin = Float(0.0)
    @objc dynamic var caffeine = Float(0.0)
    @objc dynamic var chloried = Float(0.0)
    @objc dynamic var chromium = Float(0.0)
    @objc dynamic var copper = Float(0.0)
    @objc dynamic var folate = Float(0.0)
    @objc dynamic var iodine = Float(0.0)
    @objc dynamic var manganese = Float(0.0)
    @objc dynamic var molybdenum = Float(0.0)
    @objc dynamic var niacin = Float(0.0)
    @objc dynamic var pantothenicAcid = Float(0.0)
    @objc dynamic var phosphorus = Float(0.0)
    @objc dynamic var riboflavin = Float(0.0)
    @objc dynamic var selenium = Float(0.0)
    @objc dynamic var thiamin = Float(0.0)
    @objc dynamic var zinc = Float(0.0)
    
    override static func indexedProperties() -> [String] {
        return ["name"]
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

final class FoodEntry: Object {
    enum HealthKitStatus: Int {
        case unwritten              = 0
        case writtenAndUpToDate     = 1
        case writtenAndNeedsUpdate  = 2
    }
    
    enum MeasurementValueRepresentation: Int {
        case decimal    = 0
        case fraction   = 1
    }
    
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var date = Date().roundedToNearestHalfHour
    @objc dynamic var food: Food?
    @objc dynamic var measurementValueRepresentationRaw = MeasurementValueRepresentation.decimal.rawValue
    @objc dynamic var measurementValue = Data(Float(0.0))
    @objc dynamic var healthKitStatusRaw = HealthKitStatus.unwritten.rawValue
    let day = LinkingObjects(fromType: Day.self, property: "foodEntries")
    let tags = List<Tag>()
    var healthKitStatus: HealthKitStatus {
        return HealthKitStatus(rawValue: healthKitStatusRaw)!
    }
    var measurementValueRepresentation: MeasurementValueRepresentation {
        return MeasurementValueRepresentation(rawValue: measurementValueRepresentationRaw)!
    }
    var measurementFloat: Float {
        switch measurementValueRepresentation {
        case .decimal:  return measurementValue.to(Float.self)
        case .fraction: return Fraction.decode(from: measurementValue)?.floatValue ?? 0.0
        }
    }
    var measurementString: String? {
        switch measurementValueRepresentation {
        case .decimal:  return measurementValue.to(Float.self).pretty
        case .fraction: return Fraction.decode(from: measurementValue)?.description
        }
    }
    
    override static func indexedProperties() -> [String] {
        return ["date", "healthKitStatusRaw"]
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

final class Day: Object {
    @objc dynamic var id = 0
    @objc dynamic var startOfDay = Date()
    let foodEntries = List<FoodEntry>()
    
    convenience init(_ date: Date) {
        self.init()
        id = date.hashValue
        startOfDay = date
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

final class FoodServingPair: Object {
    @objc dynamic var food: Food?
    @objc dynamic var servings = 0
}

final class FoodGroupingTemplate: Object {
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var name = ""
    @objc dynamic var searchSuggestion: SearchSuggestion?
    let foodServingPairs = List<FoodServingPair>()
    
    override static func indexedProperties() -> [String] {
        return ["name"]
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

extension Date {
    var roundedToNearestHalfHour: Date {
        var dc = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: self)
        if let minute = dc.minute {
            switch minute {
            case 0, 30:
                break
            case 1...15:
                dc.minute = 0
            case 16...44:
                dc.minute = 30
            case 45...59:
                dc.minute = 0
                dc.hour? += 1
            default:
                dc.minute = 0
            }
        } else {
            dc.minute = 0
        }
        return Calendar.current.date(from: dc) ?? self
    }
}

extension Fraction {
    var floatValue: Float? {
        guard denominator > 0 else { return nil }
        return Float(numerator) / Float(denominator)
    }
}
