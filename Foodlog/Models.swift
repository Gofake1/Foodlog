//
//  Models.swift
//  Foodlog
//
//  Created by David on 12/15/17.
//  Copyright © 2017 Gofake1. All rights reserved.
//

import Foundation
import RealmSwift

// MARK: - View controller helpers

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

// MARK: -

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
        case gray   = 0
        case red    = 1
        case orange = 2
        case yellow = 3
        case green  = 4
        case blue   = 5
        case purple = 6
    }
    
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var localCKRecord: CloudKitRecord?
    @objc dynamic var searchSuggestion: SearchSuggestion?
    @objc dynamic var name = ""
    @objc dynamic var colorCodeRaw = ColorCode.gray.rawValue
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

enum TagError: LocalizedError {
    case alreadyExists
    case illegalName
    
    var errorDescription: String? {
        switch self {
        case .alreadyExists:    return "A tag with this name already exists."
        case .illegalName:      return "This name is not valid."
        }
    }
}

final class Food: Object {
    enum Unit: Int {
        case none       = 0
        case gram       = 1
        case milligram  = 2
        case ounce      = 3
        case milliliter = 4
        case fluidOunce = 5
    }
    
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var localCKRecord: CloudKitRecord?
    @objc dynamic var searchSuggestion: SearchSuggestion?
    @objc dynamic var name = ""
    @objc dynamic var servingSize = Float(0.0)
    @objc dynamic var servingSizeUnitRaw = Unit.none.rawValue
    @objc dynamic var biotin                = Float(0.0)
    @objc dynamic var caffeine              = Float(0.0)
    @objc dynamic var calcium               = Float(0.0)
    @objc dynamic var calories              = Float(0.0)
    @objc dynamic var chloride              = Float(0.0)
    @objc dynamic var cholesterol           = Float(0.0)
    @objc dynamic var chromium              = Float(0.0)
    @objc dynamic var copper                = Float(0.0)
    @objc dynamic var dietaryFiber          = Float(0.0)
    @objc dynamic var folate                = Float(0.0)
    @objc dynamic var iodine                = Float(0.0)
    @objc dynamic var iron                  = Float(0.0)
    @objc dynamic var magnesium             = Float(0.0)
    @objc dynamic var manganese             = Float(0.0)
    @objc dynamic var molybdenum            = Float(0.0)
    @objc dynamic var monounsaturatedFat    = Float(0.0)
    @objc dynamic var niacin                = Float(0.0)
    @objc dynamic var pantothenicAcid       = Float(0.0)
    @objc dynamic var phosphorus            = Float(0.0)
    @objc dynamic var polyunsaturatedFat    = Float(0.0)
    @objc dynamic var potassium             = Float(0.0)
    @objc dynamic var protein               = Float(0.0)
    @objc dynamic var riboflavin            = Float(0.0)
    @objc dynamic var saturatedFat          = Float(0.0)
    @objc dynamic var selenium              = Float(0.0)
    @objc dynamic var sodium                = Float(0.0)
    @objc dynamic var sugars                = Float(0.0)
    @objc dynamic var thiamin               = Float(0.0)
    @objc dynamic var totalCarbohydrate     = Float(0.0)
    @objc dynamic var totalFat              = Float(0.0)
    @objc dynamic var transFat              = Float(0.0)
    @objc dynamic var vitaminA              = Float(0.0)
    @objc dynamic var vitaminB6             = Float(0.0)
    @objc dynamic var vitaminB12            = Float(0.0)
    @objc dynamic var vitaminC              = Float(0.0)
    @objc dynamic var vitaminD              = Float(0.0)
    @objc dynamic var vitaminE              = Float(0.0)
    @objc dynamic var vitaminK              = Float(0.0)
    @objc dynamic var zinc                  = Float(0.0)
    let entries      = LinkingObjects(fromType: FoodEntry.self, property: "food")
    let servingPairs = LinkingObjects(fromType: FoodServingPair.self, property: "food")
    let tags         = List<Tag>()
    var servingSizeUnit: Unit {
        get { return Unit(rawValue: servingSizeUnitRaw)! }
        set { servingSizeUnitRaw = newValue.rawValue }
    }
    
    override static func indexedProperties() -> [String] {
        return ["name"]
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

final class FoodEntry: Object {
    enum ConversionError: Error {
        case illegal
        case zeroServingSize
    }
    
    enum MeasurementRepresentation: Int {
        case decimal    = 0
        case fraction   = 1
    }
    
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var localCKRecord: CloudKitRecord?
    @objc dynamic var date = Date().roundedToNearestHalfHour
    @objc dynamic var food: Food?
    @objc dynamic var measurement = Data(Float(0.0))
    @objc dynamic var measurementRepresentationRaw = MeasurementRepresentation.decimal.rawValue
    @objc dynamic var measurementUnitRaw = Food.Unit.none.rawValue
    let days = LinkingObjects(fromType: Day.self, property: "foodEntries")
    let tags = List<Tag>()
    var day: Day {
        return days[0]
    }
    var measurementString: String? {
        return measurement.string(from: measurementRepresentation)
    }
    var measurementRepresentation: MeasurementRepresentation {
        get { return MeasurementRepresentation(rawValue: measurementRepresentationRaw)! }
        set { measurementRepresentationRaw = newValue.rawValue }
    }
    var measurementUnit: Food.Unit {
        get { return Food.Unit(rawValue: measurementUnitRaw)! }
        set { measurementUnitRaw = newValue.rawValue }
    }
    private var measurementFloat: Float {
        switch measurementRepresentation {
        case .decimal:  return measurement.to(Float.self)
        case .fraction: return Fraction.decode(from: measurement)?.floatValue ?? 0.0
        }
    }
    
    override static func indexedProperties() -> [String] {
        return ["date"]
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    func conversionFactor() throws -> Float {
        if measurementUnit == .none {
            return measurementFloat
        }
        guard let servingSize = food?.servingSize, servingSize > 0.0 else { throw ConversionError.zeroServingSize }
        switch (measurementUnit, food!.servingSizeUnit) {
        case (.gram, .gram):                fallthrough
        case (.milligram, .milligram):      fallthrough
        case (.ounce, .ounce):              fallthrough
        case (.milliliter, .milliliter):    fallthrough
        case (.fluidOunce, .fluidOunce):
            return measurementFloat / servingSize
        case (.gram, .milligram):           return 1000.0 * measurementFloat / servingSize
        case (.gram, .ounce):               return 28.3495 * measurementFloat / servingSize
        case (.milligram, .gram):           return 0.001 * measurementFloat / servingSize
        case (.milligram, .ounce):          return 0.000035274 * measurementFloat / servingSize
        case (.ounce, .gram):               return 0.035274 * measurementFloat / servingSize
        case (.ounce, .milligram):          return 28349.5 * measurementFloat / servingSize
        case (.milliliter, .fluidOunce):    return 29.5735 * measurementFloat / servingSize
        case (.fluidOunce, .milliliter):    return 0.033814 * measurementFloat / servingSize
        default:
            throw ConversionError.illegal
        }
    }
}

final class Day: Object {
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var startOfDay = Date()
    let foodEntries = List<FoodEntry>()
    lazy var sortedFoodEntries = foodEntries.sorted(byKeyPath: #keyPath(FoodEntry.date), ascending: false)
    
    convenience init(startOfDay: Date) {
        self.init()
        self.startOfDay = startOfDay
    }
    
    override static func ignoredProperties() -> [String] {
        return ["sortedFoodEntries"]
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
        return [localCKRecord!, searchSuggestion!, self] + entries.flatMap { $0.objectsToDelete }
            + Array(servingPairs) as [Object]
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
