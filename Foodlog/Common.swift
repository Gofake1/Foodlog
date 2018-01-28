//
//  Common.swift
//  Foodlog
//
//  Created by David on 1/14/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import Foundation

infix operator &&=: AssignmentPrecedence
func &&=(lhs: inout Bool, rhs: Bool) {
    lhs = lhs && rhs
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

extension Fraction {
    init?(_ string: String) {
        enum ParseState {
            case expectNumeratorDigit
            case expectNumeratorDigitOrDivider
            case expectDenominatorDigit
        }
        
        var state = ParseState.expectNumeratorDigit
        var numeratorString = ""
        var denominatorString = ""
        for character in string {
            switch character {
            case ".", ",", "/":
                guard state == .expectNumeratorDigitOrDivider else { return nil }
                state = .expectDenominatorDigit
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
                switch state {
                case .expectNumeratorDigit:
                    numeratorString += String(character)
                    state = .expectNumeratorDigitOrDivider
                case .expectNumeratorDigitOrDivider:
                    numeratorString += String(character)
                case .expectDenominatorDigit:
                    denominatorString += String(character)
                }
            default:
                return nil
            }
        }
        self.init(numerator: Int(numeratorString) ?? 0, denominator: Int(denominatorString) ?? 1)
    }
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

enum HealthKitStatus: Int {
    case unwritten              = 0
    case writtenAndUpToDate     = 1
    case writtenAndNeedsUpdate  = 2
}

enum MeasurementRepresentation: Int {
    case serving    = 0
    case milligram  = 1
    case gram       = 2
    case ounce      = 3
    case pound      = 4
    case fluidOunce = 5
}

extension MeasurementRepresentation: CustomStringConvertible {
    var description: String {
        switch self {
        case .serving:      return "Serving"
        case .milligram:    return "Milligram"
        case .gram:         return "Gram"
        case .ounce:        return "Ounce"
        case .pound:        return "Pound"
        case .fluidOunce:   return "Fluid Oz."
        }
    }
}

enum MeasurementValueRepresentation: Int {
    case decimal    = 0
    case fraction   = 1
}

enum NutritionKind {
    enum Unit: Int {
        case calorie    = 0
        case gram       = 1
        case milligram  = 2
        case microgram  = 3
        
        var short: String {
            switch self {
            case .calorie:      return ""
            case .gram:         return " g"
            case .milligram:    return " mg"
            case .microgram:    return " mcg"
            }
        }
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
    
    var dailyValueReal: Float? {
        switch self {
        case .calories:             return 2000
        case .totalFat:             return 78
        case .saturatedFat:         return 20
        case .monounsaturatedFat:   return nil
        case .polyunsaturatedFat:   return nil
        case .transFat:             return nil
        case .cholesterol:          return 300
        case .sodium:               return 2300
        case .totalCarbohydrate:    return 275
        case .dietaryFiber:         return 28
        case .sugars:               return 50
        case .protein:              return 50
        case .vitaminA:             return 900
        case .vitaminB6:            return 1.7
        case .vitaminB12:           return 2.4
        case .vitaminC:             return 90
        case .vitaminD:             return 20
        case .vitaminE:             return 15
        case .vitaminK:             return 120
        case .calcium:              return 1300
        case .iron:                 return 18
        case .magnesium:            return 420
        case .potassium:            return 4700
        }
    }
    
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
    init<A: FloatingPoint>(dropDecimalIfZero floatingPoint: A) {
        if floatingPoint.truncatingRemainder(dividingBy: 1).isZero {
            self.init(format: "%.0f", floatingPoint as! CVarArg)
        } else {
            self.init(describing: floatingPoint)
        }
    }
}
