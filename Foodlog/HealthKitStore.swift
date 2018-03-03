//
//  HealthKitStore.swift
//  Foodlog
//
//  Created by David on 2/3/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import HealthKit
import UIKit

private enum CachedHealthKitTransaction {
    case delete([String], () -> ())
    case save([HKObject], () -> ())
}

private var _queue: DispatchQueue? = DispatchQueue(label: "Foodlog.HealthKitStore.lock")
private var _store: HKHealthStore!
// Cache transactions that occur before authorization
private var _cachedHealthKitTransactions: [CachedHealthKitTransaction]? = []

final class HealthKitStore {
    // We use a singleton because Apple recommends asking for authorization at the point of use:
    // https://developer.apple.com/ios/human-interface-guidelines/technologies/healthkit/
    // This rules out using static members because we don't want to ask for authorization immediately after app
    // finishes launching
    static let shared = HealthKitStore()
    private(set) var delete: ([String], @escaping () -> ()) -> () = { ids, completionHandler in
        guard HKHealthStore.isHealthDataAvailable() else { return }
        _queue?.sync {
            _cachedHealthKitTransactions?.append(CachedHealthKitTransaction.delete(ids, completionHandler))
        }
    }
    private(set) var save: ([HKObject], @escaping () -> ()) -> () = { objects, completionHandler in
        guard HKHealthStore.isHealthDataAvailable() else { return }
        _queue?.sync {
            _cachedHealthKitTransactions?.append(CachedHealthKitTransaction.save(objects, completionHandler))
        }
    }
    
    private init() {
        guard HKHealthStore.isHealthDataAvailable() else {
            // TODO: Test on iPad
            delete = { _, _ in }
            save = { _, _ in }
            return
        }
        _store = HKHealthStore()
        let types = Set(arrayLiteral:
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKObjectType.quantityType(forIdentifier: .dietaryFatTotal)!,
            HKObjectType.quantityType(forIdentifier: .dietaryFatSaturated)!,
            HKObjectType.quantityType(forIdentifier: .dietaryFatMonounsaturated)!,
            HKObjectType.quantityType(forIdentifier: .dietaryFatPolyunsaturated)!,
            HKObjectType.quantityType(forIdentifier: .dietaryCholesterol)!,
            HKObjectType.quantityType(forIdentifier: .dietarySodium)!,
            HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
            HKObjectType.quantityType(forIdentifier: .dietaryFiber)!,
            HKObjectType.quantityType(forIdentifier: .dietarySugar)!,
            HKObjectType.quantityType(forIdentifier: .dietaryProtein)!,
            HKObjectType.quantityType(forIdentifier: .dietaryVitaminA)!,
            HKObjectType.quantityType(forIdentifier: .dietaryVitaminB6)!,
            HKObjectType.quantityType(forIdentifier: .dietaryVitaminB12)!,
            HKObjectType.quantityType(forIdentifier: .dietaryVitaminC)!,
            HKObjectType.quantityType(forIdentifier: .dietaryVitaminD)!,
            HKObjectType.quantityType(forIdentifier: .dietaryVitaminE)!,
            HKObjectType.quantityType(forIdentifier: .dietaryVitaminK)!,
            HKObjectType.quantityType(forIdentifier: .dietaryCalcium)!,
            HKObjectType.quantityType(forIdentifier: .dietaryIron)!,
            HKObjectType.quantityType(forIdentifier: .dietaryMagnesium)!,
            HKObjectType.quantityType(forIdentifier: .dietaryPotassium)!
        )
        _store.requestAuthorization(toShare: types, read: nil) { [weak self] in
            if $0 {
                _queue?.sync {
                    _cachedHealthKitTransactions!.forEach {
                        switch $0 {
                        case .delete(let ids, let completionHandler):
                            _store.delete(foodEntryIds: ids, completionHandler: completionHandler)
                        case .save(let hkObjects, let completionHandler):
                            _store.save(foodEntryHKObjects: hkObjects, completionHandler: completionHandler)
                        }
                    }
                    _cachedHealthKitTransactions!.removeAll()
                    _cachedHealthKitTransactions = nil
                }
                _queue = nil
                
                // Swizzle `delete` and `save` to avoid conditional checks
                self?.delete = {
                    _store.delete(foodEntryIds: $0, completionHandler: $1)
                }
                self?.save = {
                    _store.save(foodEntryHKObjects: $0, completionHandler: $1)
                }
            } else {
                // TODO: Test permission denied
                print("Auth failed")
                _queue?.sync {
                    _cachedHealthKitTransactions!.removeAll()
                    _cachedHealthKitTransactions = nil
                }
                _queue = nil
                self?.delete = { _, _ in }
                self?.save = { _, _ in }
                if let error = $1 {
                    UIApplication.shared.alert(error: error)
                }
            }
        }
    }
}

extension FoodEntry {
    var hkObject: HKObject? {
        var objects = Set<HKSample>()
        func add(_ nutrition: NutritionKind, _ value: Float) {
            guard value > 0.0 else { return }
            let quantity = HKQuantity(unit: nutrition.unit.hkUnit, doubleValue: Double(value * measurementFloat))
            objects.insert(HKQuantitySample(type: nutrition.hkType, quantity: quantity, start: date, end: date))
        }
        
        add(.calories, food!.calories)
        add(.totalFat, food!.totalFat)
        add(.saturatedFat, food!.saturatedFat)
        add(.monounsaturatedFat, food!.monounsaturatedFat)
        add(.polyunsaturatedFat, food!.polyunsaturatedFat)
        add(.cholesterol, food!.cholesterol)
        add(.sodium, food!.sodium)
        add(.totalCarbohydrate, food!.totalCarbohydrate)
        add(.dietaryFiber, food!.dietaryFiber)
        add(.sugars, food!.sugars)
        add(.protein, food!.protein)
        add(.vitaminA, food!.vitaminA)
        add(.vitaminB6, food!.vitaminB6)
        add(.vitaminB12, food!.vitaminB12)
        add(.vitaminC, food!.vitaminC)
        add(.vitaminD, food!.vitaminD)
        add(.vitaminE, food!.vitaminE)
        add(.vitaminK, food!.vitaminK)
        add(.calcium, food!.calcium)
        add(.iron, food!.iron)
        add(.magnesium, food!.magnesium)
        add(.potassium, food!.potassium)
        
        guard objects.count > 0 else { return nil }
        
        let metadata: [String: Any] = [HKMetadataKeyFoodType: food!.name, "FoodlogID": id]
        return HKCorrelation(type: HKObjectType.correlationType(forIdentifier: .food)!,
                             start: date, end: date, objects: objects, metadata: metadata)
    }
}

extension NutritionKind {
    var hkType: HKQuantityType {
        switch self {
        case .calories:             return HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        case .totalFat:             return HKObjectType.quantityType(forIdentifier: .dietaryFatTotal)!
        case .saturatedFat:         return HKObjectType.quantityType(forIdentifier: .dietaryFatSaturated)!
        case .monounsaturatedFat:   return HKObjectType.quantityType(forIdentifier: .dietaryFatMonounsaturated)!
        case .polyunsaturatedFat:   return HKObjectType.quantityType(forIdentifier: .dietaryFatPolyunsaturated)!
        case .transFat:             fatalError()
        case .cholesterol:          return HKObjectType.quantityType(forIdentifier: .dietaryCholesterol)!
        case .sodium:               return HKObjectType.quantityType(forIdentifier: .dietarySodium)!
        case .totalCarbohydrate:    return HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates)!
        case .dietaryFiber:         return HKObjectType.quantityType(forIdentifier: .dietaryFiber)!
        case .sugars:               return HKObjectType.quantityType(forIdentifier: .dietarySugar)!
        case .protein:              return HKObjectType.quantityType(forIdentifier: .dietaryProtein)!
        case .vitaminA:             return HKObjectType.quantityType(forIdentifier: .dietaryVitaminA)!
        case .vitaminB6:            return HKObjectType.quantityType(forIdentifier: .dietaryVitaminB6)!
        case .vitaminB12:           return HKObjectType.quantityType(forIdentifier: .dietaryVitaminB12)!
        case .vitaminC:             return HKObjectType.quantityType(forIdentifier: .dietaryVitaminC)!
        case .vitaminD:             return HKObjectType.quantityType(forIdentifier: .dietaryVitaminD)!
        case .vitaminE:             return HKObjectType.quantityType(forIdentifier: .dietaryVitaminE)!
        case .vitaminK:             return HKObjectType.quantityType(forIdentifier: .dietaryVitaminK)!
        case .calcium:              return HKObjectType.quantityType(forIdentifier: .dietaryCalcium)!
        case .iron:                 return HKObjectType.quantityType(forIdentifier: .dietaryIron)!
        case .magnesium:            return HKObjectType.quantityType(forIdentifier: .dietaryMagnesium)!
        case .potassium:            return HKObjectType.quantityType(forIdentifier: .dietaryPotassium)!
        }
    }
}

extension NutritionKind.Unit {
    var hkUnit: HKUnit {
        switch self {
        case .calorie:      return HKUnit.kilocalorie()
        case .gram:         return HKUnit.gram()
        case .milligram:    return HKUnit.gramUnit(with: .milli)
        case .microgram:    return HKUnit.gramUnit(with: .micro)
        }
    }
}

extension HKHealthStore {
    func delete(foodEntryIds ids: [String], completionHandler: @escaping () -> () = {}) {
        if ids.count == 0 {
            completionHandler()
        } else if ids.count == 1 {
            let predicate = NSPredicate(format: "\(HKPredicateKeyPathMetadata).FoodlogID == %@", ids[0])
            delete(foodEntryPredicate: predicate, completionHandler: completionHandler)
        } else {
            fatalError("TODO: handle multiple deletions")
        }
    }
    
    func save(foodEntryHKObjects objects: [HKObject], completionHandler: @escaping () -> ()) {
        if objects.count == 0 {
            completionHandler()
        } else {
            save(objects) {
                if let error = $1 { UIApplication.shared.alert(error: error) }
                completionHandler()
            }
        }
    }
    
    private func delete(foodEntryPredicate predicate: NSPredicate, completionHandler: @escaping () -> ()) {
        let query = HKCorrelationQuery(type: HKObjectType.correlationType(forIdentifier: .food)!,
                                       predicate: predicate, samplePredicates: nil)
        { (_, matches, error) in
            if let error = error {
                UIApplication.shared.alert(error: error)
            } else if let matches = matches {
                guard matches.count > 0 else { return }
                _store.delete(matches.flatMap { $0.objects }) {
                    if let error = $1 { UIApplication.shared.alert(error: error) }
                    _store.delete(matches) {
                        if let error = $1 { UIApplication.shared.alert(error: error) }
                        completionHandler()
                    }
                }
            } else {
                completionHandler()
            }
        }
        execute(query)
    }
}
