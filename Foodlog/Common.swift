//
//  Common.swift
//  Foodlog
//
//  Created by David on 1/14/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import Foundation
import SystemConfiguration

private let _jsonDecoder = JSONDecoder()
private let _jsonEncoder = JSONEncoder()
private let _networkReachability = NetworkReachability()
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

func _retry(_ block: @escaping () -> (), after retryAfter: Double) {
    print("retrying after", retryAfter) //*
    DispatchQueue.main.asyncAfter(deadline: .now()+retryAfter, execute: block)
}

func _retryWhenNetworkAvailable(_ block: @escaping () -> ()) {
    _networkReachability.add(block: block)
}

protocol _JSONCoderDefaultType {}

extension _JSONCoderDefaultType where Self: Codable {
    static func decode(from data: Data) -> Self? {
        return try? _jsonDecoder.decode(Self.self, from: data)
    }
    
    func encode() -> Data? {
        return try? _jsonEncoder.encode(self)
    }
}

extension Data {
    init<T>(_ value: T) {
        var value = value
        self.init(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }
    
    func string(from representation: FoodEntry.MeasurementRepresentation) -> String? {
        switch representation {
        case .decimal:  return to(Float.self).pretty
        case .fraction: return Fraction.decode(from: self)?.description
        }
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
    var startOfDay: Date {
        let dc = Calendar.current.dateComponents([.year, .month, .day], from: self)
        return Calendar.current.date(from: dc) ?? self
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

extension Food.Unit {
    var suffix: String {
        switch self {
        case .none:         return ""
        case .gram:         return " g"
        case .milligram:    return " mg"
        case .ounce:        return " oz"
        case .milliliter:   return " mL"
        case .fluidOunce:   return " fl oz"
        }
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

extension Fraction: _JSONCoderDefaultType {}

// TODO: Persist to disk
// https://marcosantadev.com/network-reachability-swift/
final class NetworkReachability {
    private let reachability = SCNetworkReachabilityCreateWithName(nil, "www.google.com")!
    private var blocks = [() -> ()]()
    private var flags = SCNetworkReachabilityFlags()
    
    fileprivate init() {
        SCNetworkReachabilityGetFlags(reachability, &flags)
        
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = UnsafeMutableRawPointer(Unmanaged<NetworkReachability>.passUnretained(self).toOpaque())
        let callback: SCNetworkReachabilityCallBack? = {
            guard let info = $2 else { return }
            let newFlags = $1
            // Workaround: We can't capture `self` because C function pointers don't support capturing
            let networkReachability = Unmanaged<NetworkReachability>.fromOpaque(info).takeUnretainedValue()
            DispatchQueue.main.async {
                networkReachability.reachabilityChanged(newFlags)
            }
        }
        if !SCNetworkReachabilitySetCallback(reachability, callback, &context) {
            fatalError()
        }
    }
    
    fileprivate func add(block: @escaping () -> ()) {
        blocks.append(block)
    }
    
    private func reachabilityChanged(_ newFlags: SCNetworkReachabilityFlags) {
        func isReachable(_ flags: SCNetworkReachabilityFlags) -> Bool {
            let reachable = flags.contains(.reachable)
            let connectionRequired = flags.contains(.connectionRequired)
            let canConnectAutomatically = flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic)
            let canConnectWithoutIntervention = canConnectAutomatically && !flags.contains(.interventionRequired)
            return reachable && (!connectionRequired || canConnectWithoutIntervention)
        }
        
        guard flags != newFlags else { return }
        defer { flags = newFlags }
        print("Reachability changed") //*
        if isReachable(newFlags) {
            while !blocks.isEmpty {
                blocks.removeFirst()()
            }
        }
    }
}

// TODO: Convert IU to mcg
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
    
    enum ValueRepresentation {
        case percentage
        case real
    }
    
    case biotin
    case caffeine
    case calcium
    case calories
    case chloride
    case cholesterol
    case chromium
    case copper
    case dietaryFiber
    case folate
    case iodine
    case iron
    case magnesium
    case manganese
    case molybdenum
    case monounsaturatedFat
    case niacin
    case pantothenicAcid
    case phosphorus
    case polyunsaturatedFat
    case potassium
    case protein
    case riboflavin
    case saturatedFat
    case selenium
    case sodium
    case sugars
    case thiamin
    case totalCarbohydrate
    case totalFat
    case transFat
    case vitaminA
    case vitaminB6
    case vitaminB12
    case vitaminC
    case vitaminD
    case vitaminE
    case vitaminK
    case zinc
    
    var dailyValueReal: Float? {
        switch self {
        case .biotin:               return 300
        case .caffeine:             return nil
        case .calcium:              return 1000
        case .calories:             return 2000
        case .chloride:             return 3400
        case .cholesterol:          return 300
        case .chromium:             return 120
        case .copper:               return 2
        case .dietaryFiber:         return 25
        case .folate:               return 400
        case .iodine:               return 150
        case .iron:                 return 18
        case .magnesium:            return 400
        case .manganese:            return 2
        case .molybdenum:           return 75
        case .monounsaturatedFat:   return nil
        case .niacin:               return 20
        case .pantothenicAcid:      return 10
        case .phosphorus:           return 1000
        case .polyunsaturatedFat:   return nil
        case .potassium:            return 3500
        case .protein:              return 50
        case .riboflavin:           return 1.7
        case .saturatedFat:         return 20
        case .selenium:             return 70
        case .sodium:               return 2400
        case .sugars:               return 50
        case .thiamin:              return 1.5
        case .totalCarbohydrate:    return 300
        case .totalFat:             return 65
        case .transFat:             return nil
        case .vitaminA:             return nil // Was 900 mcg, should be 5000 IU
        case .vitaminB6:            return 2
        case .vitaminB12:           return 6
        case .vitaminC:             return 60
        case .vitaminD:             return nil // Was 20 mcg, should be 400 IU
        case .vitaminE:             return nil // Was 15 mcg, should be 30 IU
        case .vitaminK:             return 80
        case .zinc:                 return 15
        }
    }
    var title: String {
        switch self {
        case .biotin:               return "Biotin"
        case .caffeine:             return "Caffeine"
        case .calcium:              return "Calcium"
        case .calories:             return "Calories"
        case .chloride:             return "Chloride"
        case .cholesterol:          return "Cholesterol"
        case .chromium:             return "Chromium"
        case .copper:               return "Copper"
        case .dietaryFiber:         return "Dietary Fiber"
        case .folate:               return "Folate"
        case .iodine:               return "Iodine"
        case .iron:                 return "Iron"
        case .magnesium:            return "Magnesium"
        case .manganese:            return "Manganese"
        case .molybdenum:           return "Molybdenum"
        case .monounsaturatedFat:   return "Monounsaturated Fat"
        case .niacin:               return "Niacin"
        case .pantothenicAcid:      return "Pantothenic Acid"
        case .phosphorus:           return "Phosphorus"
        case .polyunsaturatedFat:   return "Polyunsaturated Fat"
        case .potassium:            return "Potassium"
        case .protein:              return "Protein"
        case .riboflavin:           return "Riboflavin"
        case .saturatedFat:         return "Saturated Fat"
        case .selenium:             return "Selenium"
        case .sodium:               return "Sodium"
        case .sugars:               return "Sugars"
        case .thiamin:              return "Thiamin"
        case .totalCarbohydrate:    return "Total Carbohydrate"
        case .totalFat:             return "Total Fat"
        case .transFat:             return "Trans Fat"
        case .vitaminA:             return "Vitamin A"
        case .vitaminB6:            return "Vitamin B6"
        case .vitaminB12:           return "Vitamin B12"
        case .vitaminC:             return "Vitamin C"
        case .vitaminD:             return "Vitamin D"
        case .vitaminE:             return "Vitamin E"
        case .vitaminK:             return "Vitamin K"
        case .zinc:                 return "Zinc"
        }
    }
    var keyPath: ReferenceWritableKeyPath<Food, Float> {
        switch self {
        case .biotin:               return \.biotin
        case .caffeine:             return \.caffeine
        case .calcium:              return \.calcium
        case .calories:             return \.calories
        case .chloride:             return \.chloride
        case .cholesterol:          return \.cholesterol
        case .chromium:             return \.chromium
        case .copper:               return \.copper
        case .dietaryFiber:         return \.dietaryFiber
        case .folate:               return \.folate
        case .iodine:               return \.iodine
        case .iron:                 return \.iron
        case .magnesium:            return \.magnesium
        case .manganese:            return \.manganese
        case .molybdenum:           return \.molybdenum
        case .monounsaturatedFat:   return \.monounsaturatedFat
        case .niacin:               return \.niacin
        case .pantothenicAcid:      return \.pantothenicAcid
        case .phosphorus:           return \.phosphorus
        case .polyunsaturatedFat:   return \.polyunsaturatedFat
        case .potassium:            return \.potassium
        case .protein:              return \.protein
        case .riboflavin:           return \.riboflavin
        case .saturatedFat:         return \.saturatedFat
        case .selenium:             return \.selenium
        case .sodium:               return \.sodium
        case .sugars:               return \.sugars
        case .thiamin:              return \.thiamin
        case .totalCarbohydrate:    return \.totalCarbohydrate
        case .totalFat:             return \.totalFat
        case .transFat:             return \.transFat
        case .vitaminA:             return \.vitaminA
        case .vitaminB6:            return \.vitaminB6
        case .vitaminB12:           return \.vitaminB12
        case .vitaminC:             return \.vitaminC
        case .vitaminD:             return \.vitaminD
        case .vitaminE:             return \.vitaminE
        case .vitaminK:             return \.vitaminK
        case .zinc:                 return \.zinc
        }
    }
    var unit: Unit {
        switch self {
        case .biotin:               return .microgram
        case .caffeine:             return .milligram
        case .calcium:              return .milligram
        case .calories:             return .calorie
        case .chloride:             return .milligram
        case .cholesterol:          return .milligram
        case .chromium:             return .microgram
        case .copper:               return .milligram
        case .dietaryFiber:         return .gram
        case .folate:               return .microgram
        case .iodine:               return .microgram
        case .iron:                 return .milligram
        case .magnesium:            return .milligram
        case .manganese:            return .milligram
        case .molybdenum:           return .microgram
        case .monounsaturatedFat:   return .gram
        case .niacin:               return .milligram
        case .pantothenicAcid:      return .milligram
        case .phosphorus:           return .milligram
        case .polyunsaturatedFat:   return .gram
        case .potassium:            return .milligram
        case .protein:              return .gram
        case .riboflavin:           return .milligram
        case .saturatedFat:         return .gram
        case .selenium:             return .microgram
        case .sodium:               return .milligram
        case .sugars:               return .gram
        case .thiamin:              return .milligram
        case .totalCarbohydrate:    return .gram
        case .totalFat:             return .gram
        case .transFat:             return .gram
        case .vitaminA:             return .microgram
        case .vitaminB6:            return .milligram
        case .vitaminB12:           return .microgram
        case .vitaminC:             return .milligram
        case .vitaminD:             return .microgram
        case .vitaminE:             return .milligram
        case .vitaminK:             return .microgram
        case .zinc:                 return .milligram
        }
    }
}

final class Ref<T> {
    var value: T {
        didSet {
            onChange(value)
        }
    }
    var onChange: (T) -> () = { _ in }
    
    init(_ value: T) {
        self.value = value
    }
}

extension String {
    var isValidForDecimalOrFractionalInput: Bool {
        for character in self {
            switch character {
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", ",", "/": continue
            default: return false
            }
        }
        return true
    }
    
    init<A: FloatingPoint>(dropDecimalIfZero floatingPoint: A) {
        if floatingPoint.truncatingRemainder(dividingBy: 1).isZero {
            self.init(format: "%.0f", floatingPoint as! CVarArg)
        } else {
            self.init(describing: floatingPoint)
        }
    }
}
