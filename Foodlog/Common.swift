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

extension Food.MeasurementUnit {
    var singular: String {
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
    var keyPath: ReferenceWritableKeyPath<Food, Float> {
        switch self {
        case .calories:             return \.calories
        case .totalFat:             return \.totalFat
        case .saturatedFat:         return \.saturatedFat
        case .monounsaturatedFat:   return \.monounsaturatedFat
        case .polyunsaturatedFat:   return \.polyunsaturatedFat
        case .transFat:             return \.transFat
        case .cholesterol:          return \.cholesterol
        case .sodium:               return \.sodium
        case .totalCarbohydrate:    return \.totalCarbohydrate
        case .dietaryFiber:         return \.dietaryFiber
        case .sugars:               return \.sugars
        case .protein:              return \.protein
        case .vitaminA:             return \.vitaminA
        case .vitaminB6:            return \.vitaminB6
        case .vitaminB12:           return \.vitaminB12
        case .vitaminC:             return \.vitaminC
        case .vitaminD:             return \.vitaminD
        case .vitaminE:             return \.vitaminE
        case .vitaminK:             return \.vitaminK
        case .calcium:              return \.calcium
        case .iron:                 return \.iron
        case .magnesium:            return \.magnesium
        case .potassium:            return \.potassium
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
