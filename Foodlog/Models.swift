//
//  Models.swift
//  Foodlog
//
//  Created by David on 12/15/17.
//  Copyright © 2017 Gofake1. All rights reserved.
//

import Foundation
import RealmSwift

final class Tag: Object {
    @objc dynamic var name = ""
    let foods = LinkingObjects(fromType: Food.self, property: "tags")
    let foodEntries = LinkingObjects(fromType: FoodEntry.self, property: "tags")
    
    override static func primaryKey() -> String? {
        return "name"
    }
}

enum MeasurementKind: Int {
    case serving    = 0
    case milligram  = 1
    case gram       = 2
    case ounce      = 3
    case pound      = 4
    case fluidOunce = 5
}

final class Food: Object {
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var name = ""
    @objc dynamic var measurementKindRaw = MeasurementKind.serving.rawValue
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
    let tags = List<Tag>()
    
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

protocol JSONCoderProvided {}

private let _jsonDecoder = JSONDecoder()
private let _jsonEncoder = JSONEncoder()

extension JSONCoderProvided where Self: Codable {
    static func decode(from data: Data) -> Self? {
        return try? _jsonDecoder.decode(Self.self, from: data)
    }
    
    func encode() -> Data? {
        return try? _jsonEncoder.encode(self)
    }
}

extension Float: JSONCoderProvided {}

struct Fraction: Codable, JSONCoderProvided {
    enum CodingKeys: String, CodingKey {
        case numerator = "n"
        case denominator = "d"
    }
    
    var numerator: Int
    var denominator: Int
}

extension Fraction: CustomStringConvertible {
    var description: String {
        if numerator == 0 {
            return "0"
        }
        if denominator == 1 {
            return "\(numerator)"
        }
        return "\(numerator)/\(denominator)"
    }
}

enum MeasurementValueRepresentation: Int {
    case fraction   = 0
    case decimal    = 1
}

enum HealthKitStatus: Int {
    case unwritten              = 0
    case writtenAndUpToDate     = 1
    case writtenAndNeedsUpdate  = 2
}

final class FoodEntry: Object {
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var date = Date()
    @objc dynamic var food: Food?
    @objc dynamic var measurementValueRepresentationRaw = MeasurementValueRepresentation.fraction.rawValue
    @objc dynamic var measurementValue = Data()
    @objc dynamic var healthKitStatus = HealthKitStatus.unwritten.rawValue
    let tags = List<Tag>()
    
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
    let foodServingPairs = List<FoodServingPair>()
    
    override static func indexedProperties() -> [String] {
        return ["name"]
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
