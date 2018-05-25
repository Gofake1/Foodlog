//
//  Models.swift
//  Foodlog
//
//  Created by David on 12/15/17.
//  Copyright © 2017 Gofake1. All rights reserved.
//

import Foundation
import RealmSwift

// View controller helpers

/// - returns: `Day` instance that is associated with the date. Creates a new instance if it doesn't exist.
func _correctDay(startOfDay: Date) -> Day {
    if let day = DataStore.days.filter("startOfDay == %@", startOfDay).first {
        return Day(value: day)
    } else {
        return Day(startOfDay: startOfDay)
    }
}

/// - returns: Affected `FoodEntry`s, `Object`s to be deleted, and `Day`s to be pruned
func _deleteFood(_ food: Food) -> ([FoodEntry], [Object], Set<Day>) {
    return (Array(food.entries), food.objectsToDelete, Set(food.entries.map { $0.day }))
}

final class CloudKitRecord: Object {
    enum Kind: Int {
        case food       = 0
        case foodEntry  = 1
        case group      = 2
        case tag        = 3
    }
    
    @objc dynamic var recordName = ""
    @objc dynamic var kindRaw = -1
    @objc dynamic var systemFields = Data()
    let foods       = LinkingObjects(fromType: Food.self, property: "localCKRecord")
    let foodEntries = LinkingObjects(fromType: FoodEntry.self, property: "localCKRecord")
    let groups      = LinkingObjects(fromType: FoodGroupingTemplate.self, property: "localCKRecord")
    let tags        = LinkingObjects(fromType: Tag.self, property: "localCKRecord")
    var kind: Kind {
        get { return Kind(rawValue: kindRaw)! }
        set { kindRaw = newValue.rawValue }
    }
    
    override static func primaryKey() -> String? {
        return "recordName"
    }
}

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
    let foods  = LinkingObjects(fromType: Food.self, property: "searchSuggestion")
    let groups = LinkingObjects(fromType: FoodGroupingTemplate.self, property: "searchSuggestion")
    let tags   = LinkingObjects(fromType: Tag.self, property: "searchSuggestion")
    var kind: Kind {
        get { return Kind(rawValue: kindRaw)! }
        set { kindRaw = newValue.rawValue }
    }
    
    override static func indexedProperties() -> [String] {
        return ["lastUsed", "text"]
    }
    
    override static func primaryKey() -> String? {
        return "id"
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
    
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var localCKRecord: CloudKitRecord?
    @objc dynamic var searchSuggestion: SearchSuggestion?
    @objc dynamic var name = ""
    @objc dynamic var colorCodeRaw = ColorCode.lightGray.rawValue
    let foods       = LinkingObjects(fromType: Food.self, property: "tags")
    let foodEntries = LinkingObjects(fromType: FoodEntry.self, property: "tags")
    var colorCode: ColorCode {
        get { return ColorCode(rawValue: colorCodeRaw)! }
        set { colorCodeRaw = newValue.rawValue }
    }
    
    override static func indexedProperties() -> [String] {
        return ["name"]
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

final class Food: Object {
    enum MeasurementUnit: Int {
        case serving    = 0
        case milligram  = 1
        case gram       = 2
        case ounce      = 3
        case pound      = 4
        case fluidOunce = 5
    }
    
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var localCKRecord: CloudKitRecord?
    @objc dynamic var searchSuggestion: SearchSuggestion?
    @objc dynamic var name = ""
    @objc dynamic var measurementUnitRaw = MeasurementUnit.serving.rawValue
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
    let entries      = LinkingObjects(fromType: FoodEntry.self, property: "food")
    let servingPairs = LinkingObjects(fromType: FoodServingPair.self, property: "food")
    let tags         = List<Tag>()
    var measurementUnit: MeasurementUnit {
        get { return MeasurementUnit(rawValue: measurementUnitRaw)! }
        set { measurementUnitRaw = newValue.rawValue }
    }
    
    // HealthKit future-proofing, currently unused
    @objc dynamic var biotin = Float(0.0)
    @objc dynamic var caffeine = Float(0.0)
    @objc dynamic var chloride = Float(0.0)
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
    enum MeasurementValueRepresentation: Int {
        case decimal    = 0
        case fraction   = 1
    }
    
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var localCKRecord: CloudKitRecord?
    @objc dynamic var date = Date().roundedToNearestHalfHour
    @objc dynamic var food: Food?
    @objc dynamic var measurementValueRepresentationRaw = MeasurementValueRepresentation.decimal.rawValue
    @objc dynamic var measurementValue = Data(Float(0.0))
    let days = LinkingObjects(fromType: Day.self, property: "foodEntries")
    let tags = List<Tag>()
    var day: Day {
        return days[0]
    }
    var measurementValueRepresentation: MeasurementValueRepresentation {
        get { return MeasurementValueRepresentation(rawValue: measurementValueRepresentationRaw)! }
        set { measurementValueRepresentationRaw = newValue.rawValue }
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
        return ["date"]
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

final class Day: Object {
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var startOfDay = Date()
    let foodEntries = List<FoodEntry>()
    
    convenience init(startOfDay: Date) {
        self.init()
        self.startOfDay = startOfDay
    }
    
    override static func indexedProperties() -> [String] {
        return ["startOfDay"]
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    func remove(foodEntry: FoodEntry) {
        let index = foodEntries.index(of: foodEntry)!
        foodEntries.remove(at: index)
    }
}

final class FoodGroupingTemplate: Object {
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var localCKRecord: CloudKitRecord?
    @objc dynamic var searchSuggestion: SearchSuggestion?
    @objc dynamic var name = ""
    let foodServingPairs = List<FoodServingPair>()
    
    override static func indexedProperties() -> [String] {
        return ["name"]
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

final class FoodServingPair: Object {
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var food: Food?
    @objc dynamic var servings = 0
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

protocol CascadeDeletable {
    var objectsToDelete: [Object] { get }
}

extension Food: CascadeDeletable {
    var objectsToDelete: [Object] {
        return [localCKRecord!, searchSuggestion!, self] + Array(entries) as [Object] + Array(servingPairs) as [Object]
    }
}

extension FoodEntry: CascadeDeletable {
    var objectsToDelete: [Object] {
        return [localCKRecord!, self]
    }
}

extension FoodGroupingTemplate: CascadeDeletable {
    var objectsToDelete: [Object] {
        return [localCKRecord!, searchSuggestion!, self] + Array(foodServingPairs)
    }
}

extension Tag: CascadeDeletable {
    var objectsToDelete: [Object] {
        return [localCKRecord!, searchSuggestion!, self]
    }
}

extension Date {
    var roundedToNearestHalfHour: Date {
        var dc = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: self)
        if let minute = dc.minute, let _ = dc.hour {
            switch minute {
            case 0, 30:     break
            case 1...15:    dc.minute = 0
            case 16...44:   dc.minute = 30
            case 45...59:   dc.minute = 0; dc.hour! += 1
            default:        dc.minute = 0
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
