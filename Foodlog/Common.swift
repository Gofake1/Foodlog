//
//  Common.swift
//  Foodlog
//
//  Created by David on 1/14/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import Foundation

private let _jsonDecoder = JSONDecoder()
private let _jsonEncoder = JSONEncoder()
private let _mediumDateShortTime: DateFormatter = {
    let df = DateFormatter()
    df.dateStyle = .medium
    df.timeStyle = .short
    return df
}()
private let _noDateShortTime: DateFormatter = {
    let df = DateFormatter()
    df.dateStyle = .none
    df.timeStyle = .short
    return df
}()
private let _shortDateNoTime: DateFormatter = {
    let df = DateFormatter()
    df.dateStyle = .short
    df.timeStyle = .none
    return df
}()
private let _shortDateShortTime: DateFormatter = {
    let df = DateFormatter()
    df.dateStyle = .short
    df.timeStyle = .short
    return df
}()

infix operator ||=: AssignmentPrecedence
func ||=(lhs: inout Bool, rhs: Bool) {
    lhs = lhs || rhs
}

extension Data {
    init<T>(_ value: T) {
        var value = value
        self.init(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }
        
    func to<T>(_ type: T.Type) -> T {
        return withUnsafeBytes { $0.pointee }
    }
}

extension Date {
    var mediumDateShortTimeString: String {
        return _mediumDateShortTime.string(from: self)
    }
    var noDateShortTimeString: String {
        return _noDateShortTime.string(from: self)
    }
    var shortDateNoTimeString: String {
        return _shortDateNoTime.string(from: self)
    }
    var shortDateShortTimeString: String {
        return _shortDateShortTime.string(from: self)
    }
}

extension Float {
    var pretty: String? {
        return String(dropDecimalIfZero: self)
    }
    
    func dailyValuePercentageFromReal(_ kind: NutritionKind) -> Float? {
        guard let real = kind.dailyValueReal else { return nil }
        return self/real * 100.0
    }
    
    func dailyValueRealFromPercentage(_ kind: NutritionKind) -> Float? {
        guard let real = kind.dailyValueReal else { return nil }
        return self/100.0 * real
    }
}

struct Fraction: Codable {
    enum CodingKeys: String, CodingKey {
        case numerator = "n"
        case denominator = "d"
    }
    
    var numerator = 0
    var denominator = 1
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

extension Fraction: JSONCoderProvided {}

protocol JSONCoderProvided {}

extension JSONCoderProvided where Self: Codable {
    static func decode(from data: Data) -> Self? {
        return try? _jsonDecoder.decode(Self.self, from: data)
    }
    
    func encode() -> Data? {
        return try? _jsonEncoder.encode(self)
    }
}

enum NutritionKind {
    enum Unit: Int {
        case calorie    = 0
        case gram       = 1
        case milligram  = 2
        case microgram  = 3
        
        var suffix: String {
            switch self {
            case .calorie:      return ""
            case .gram:         return " g"
            case .milligram:    return " mg"
            case .microgram:    return " mcg"
            }
        }
    }
    
    enum ValueRepresentation: Int {
        case percentage = 0
        case real       = 1
    }
    
    case calories
    case totalFat
    case saturatedFat
    case monounsaturatedFat
    case polyunsaturatedFat
    case transFat
    case cholesterol
    case sodium
    case totalCarbohydrate
    case dietaryFiber
    case sugars
    case protein
    case vitaminA
    case vitaminB6
    case vitaminB12
    case vitaminC
    case vitaminD
    case vitaminE
    case vitaminK
    case calcium
    case iron
    case magnesium
    case potassium
    
    var unit: Unit {
        switch self {
        case .calories:             return .calorie
        case .totalFat:             return .gram
        case .saturatedFat:         return .gram
        case .monounsaturatedFat:   return .gram
        case .polyunsaturatedFat:   return .gram
        case .transFat:             return .gram
        case .cholesterol:          return .milligram
        case .sodium:               return .milligram
        case .totalCarbohydrate:    return .gram
        case .dietaryFiber:         return .gram
        case .sugars:               return .gram
        case .protein:              return .gram
        case .vitaminA:             return .microgram
        case .vitaminB6:            return .milligram
        case .vitaminB12:           return .microgram
        case .vitaminC:             return .milligram
        case .vitaminD:             return .microgram
        case .vitaminE:             return .milligram
        case .vitaminK:             return .microgram
        case .calcium:              return .milligram
        case .iron:                 return .milligram
        case .magnesium:            return .milligram
        case .potassium:            return .milligram
        }
    }
}

extension NutritionKind: CustomStringConvertible {
    var description: String {
        switch self {
        case .calories:             return "Calories"
        case .totalFat:             return "Total Fat"
        case .saturatedFat:         return "Saturated Fat"
        case .monounsaturatedFat:   return "Monounsaturated Fat"
        case .polyunsaturatedFat:   return "Polyunsaturated Fat"
        case .transFat:             return "Trans Fat"
        case .cholesterol:          return "Cholesterol"
        case .sodium:               return "Sodium"
        case .totalCarbohydrate:    return "Total Carbohydrate"
        case .dietaryFiber:         return "Dietary Fiber"
        case .sugars:               return "Sugars"
        case .protein:              return "Protein"
        case .vitaminA:             return "Vitamin A"
        case .vitaminB6:            return "Vitamin B6"
        case .vitaminB12:           return "Vitamin B12"
        case .vitaminC:             return "Vitamin C"
        case .vitaminD:             return "Vitamin D"
        case .vitaminE:             return "Vitamin E"
        case .vitaminK:             return "Vitamin K"
        case .calcium:              return "Calcium"
        case .iron:                 return "Iron"
        case .magnesium:            return "Magnesium"
        case .potassium:            return "Potassium"
        }
    }
}

extension String {
    var dateFromShortDateShortTime: Date? {
        return _shortDateShortTime.date(from: self)
    }
    
    init<A: FloatingPoint>(dropDecimalIfZero floatingPoint: A) {
        if floatingPoint.truncatingRemainder(dividingBy: 1).isZero {
            self.init(format: "%.0f", floatingPoint as! CVarArg)
        } else {
            self.init(describing: floatingPoint)
        }
    }
}
