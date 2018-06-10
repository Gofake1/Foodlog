//
//  HealthKitStore.swift
//  Foodlog
//
//  Created by David on 2/3/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import HealthKit

final class HealthKitStore {
    private static let queue = DispatchQueue(label: "net.gofake1.Foodlog.HealthKitStore")
    /// Implementation is decided by HealthKit availability
    private static var impl: HealthKitStoreImplType = FirstRunImpl()
    
    static func delete(_ ids: [String], completion completionHandler: @escaping (Error?) -> ()) {
        queue.async { impl.delete(ids, completion: completionHandler) }
    }
    
    static func save(_ objects: [HKObject], completion completionHandler: @escaping (Error?) -> ()) {
        queue.async { impl.save(objects, completion: completionHandler) }
    }
    
    static func update(ids: [String], hkObjects objects: [HKObject],
                       completion completionHandler: @escaping (Error?) -> ())
    {
        delete(ids) { [save] in
            if let error = $0 {
                completionHandler(error)
            } else {
                save(objects, completionHandler)
            }
        }
    }
}

private protocol HealthKitStoreImplType {
    func delete(_ ids: [String], completion completionHandler: @escaping (Error?) -> ())
    func save(_ objects: [HKObject], completion completionHandler: @escaping (Error?) -> ())
}

extension HealthKitStore {
    fileprivate enum PendingTransaction {
        case delete([String], (Error?) -> ())
        case save([HKObject], (Error?) -> ())
    }
    
    fileprivate final class DummyImpl {}
    
    /// Will set implementation to either Dummy or Working
    fileprivate final class FirstRunImpl {}
    
    fileprivate final class WorkingImpl {
        private let store = HKHealthStore()
        
        init(pendingTransaction: PendingTransaction) {
            let types = Set(NutritionKind.writableToHealthKit.map { $0.hkType })
            store.requestAuthorization(toShare: types, read: nil) { [weak self] in
                if let error = $1 {
                    switch pendingTransaction {
                    case .delete(_, let completionHandler):
                        completionHandler(error)
                    case .save(_, let completionHandler):
                        completionHandler(error)
                    }
                } else {
                    switch pendingTransaction {
                    case .delete(let ids, let completionHandler):
                        self!.delete(ids, completion: completionHandler)
                    case .save(let objects, let completionHandler):
                        self!.save(objects, completion: completionHandler)
                    }
                }
            }
        }
    }
}

extension HealthKitStore.DummyImpl: HealthKitStoreImplType {
    fileprivate func delete(_ ids: [String], completion completionHandler: @escaping (Error?) -> ()) {
        completionHandler(nil)
    }
    
    fileprivate func save(_ objects: [HKObject], completion completionHandler: @escaping (Error?) -> ()) {
        completionHandler(nil)
    }
}

extension HealthKitStore.FirstRunImpl: HealthKitStoreImplType {
    fileprivate func delete(_ ids: [String], completion completionHandler: @escaping (Error?) -> ()) {
        if HKHealthStore.isHealthDataAvailable() {
            HealthKitStore.impl = HealthKitStore.WorkingImpl(pendingTransaction: .delete(ids, completionHandler))
        } else {
            HealthKitStore.impl = HealthKitStore.DummyImpl()
            completionHandler(nil)
        }
    }
    
    fileprivate func save(_ objects: [HKObject], completion completionHandler: @escaping (Error?) -> ()) {
        if HKHealthStore.isHealthDataAvailable() {
            HealthKitStore.impl = HealthKitStore.WorkingImpl(pendingTransaction: .save(objects, completionHandler))
        } else {
            HealthKitStore.impl = HealthKitStore.DummyImpl()
            completionHandler(nil)
        }
    }
}

extension HealthKitStore.WorkingImpl: HealthKitStoreImplType {
    fileprivate func delete(_ ids: [String], completion completionHandler: @escaping (Error?) -> ()) {
        store.delete(foodEntryIds: ids, completion: completionHandler)
    }
    
    fileprivate func save(_ objects: [HKObject], completion completionHandler: @escaping (Error?) -> ()) {
        store.save(foodEntryHKObjects: objects, completion: completionHandler)
    }
}

extension FoodEntry {
    var hkObject: HKObject? {
        let factor: Float
        do {
            factor = try conversionFactor()
        } catch {
            return nil
        }
        
        func hkSample(_ kind: NutritionKind) -> HKQuantitySample? {
            let value = food![keyPath: kind.keyPath]
            guard value > 0.0 else { return nil }
            let quantity = HKQuantity(unit: kind.unit.hkUnit, doubleValue: Double(value * factor))
            return HKQuantitySample(type: kind.hkType, quantity: quantity, start: date, end: date)
        }
        
        let objects = Set(NutritionKind.writableToHealthKit.compactMap(hkSample))
        guard objects.count > 0 else { return nil }
        let metadata: [String: Any] = [HKMetadataKeyFoodType: food!.name, "FoodlogID": id]
        return HKCorrelation(type: .correlationType(forIdentifier: .food)!,
                             start: date, end: date, objects: objects, metadata: metadata)
    }
}

extension NutritionKind {
    fileprivate var hkType: HKQuantityType {
        switch self {
        case .biotin:               return .quantityType(forIdentifier: .dietaryBiotin)!
        case .caffeine:             return .quantityType(forIdentifier: .dietaryCaffeine)!
        case .calcium:              return .quantityType(forIdentifier: .dietaryCalcium)!
        case .calories:             return .quantityType(forIdentifier: .dietaryEnergyConsumed)!
        case .chloride:             return .quantityType(forIdentifier: .dietaryChloride)!
        case .cholesterol:          return .quantityType(forIdentifier: .dietaryCholesterol)!
        case .chromium:             return .quantityType(forIdentifier: .dietaryChromium)!
        case .copper:               return .quantityType(forIdentifier: .dietaryCopper)!
        case .dietaryFiber:         return .quantityType(forIdentifier: .dietaryFiber)!
        case .folate:               return .quantityType(forIdentifier: .dietaryFolate)!
        case .iodine:               return .quantityType(forIdentifier: .dietaryIodine)!
        case .iron:                 return .quantityType(forIdentifier: .dietaryIron)!
        case .magnesium:            return .quantityType(forIdentifier: .dietaryMagnesium)!
        case .manganese:            return .quantityType(forIdentifier: .dietaryManganese)!
        case .molybdenum:           return .quantityType(forIdentifier: .dietaryMolybdenum)!
        case .monounsaturatedFat:   return .quantityType(forIdentifier: .dietaryFatMonounsaturated)!
        case .niacin:               return .quantityType(forIdentifier: .dietaryNiacin)!
        case .pantothenicAcid:      return .quantityType(forIdentifier: .dietaryPantothenicAcid)!
        case .phosphorus:           return .quantityType(forIdentifier: .dietaryPhosphorus)!
        case .polyunsaturatedFat:   return .quantityType(forIdentifier: .dietaryFatPolyunsaturated)!
        case .potassium:            return .quantityType(forIdentifier: .dietaryPotassium)!
        case .protein:              return .quantityType(forIdentifier: .dietaryProtein)!
        case .riboflavin:           return .quantityType(forIdentifier: .dietaryRiboflavin)!
        case .saturatedFat:         return .quantityType(forIdentifier: .dietaryFatSaturated)!
        case .selenium:             return .quantityType(forIdentifier: .dietarySelenium)!
        case .sodium:               return .quantityType(forIdentifier: .dietarySodium)!
        case .sugars:               return .quantityType(forIdentifier: .dietarySugar)!
        case .thiamin:              return .quantityType(forIdentifier: .dietaryThiamin)!
        case .totalCarbohydrate:    return .quantityType(forIdentifier: .dietaryCarbohydrates)!
        case .totalFat:             return .quantityType(forIdentifier: .dietaryFatTotal)!
        case .transFat:             fatalError()
        case .vitaminA:             return .quantityType(forIdentifier: .dietaryVitaminA)!
        case .vitaminB6:            return .quantityType(forIdentifier: .dietaryVitaminB6)!
        case .vitaminB12:           return .quantityType(forIdentifier: .dietaryVitaminB12)!
        case .vitaminC:             return .quantityType(forIdentifier: .dietaryVitaminC)!
        case .vitaminD:             return .quantityType(forIdentifier: .dietaryVitaminD)!
        case .vitaminE:             return .quantityType(forIdentifier: .dietaryVitaminE)!
        case .vitaminK:             return .quantityType(forIdentifier: .dietaryVitaminK)!
        case .zinc:                 return .quantityType(forIdentifier: .dietaryZinc)!
        }
    }
    
    // Excludes `transFat`
    fileprivate static var writableToHealthKit: [NutritionKind] {
        return [.biotin, .caffeine, .calcium, .calories, .chloride, .cholesterol, .chromium, .copper, .dietaryFiber,
                .folate, .iodine, .iron, .magnesium, .manganese, .molybdenum, .monounsaturatedFat, .niacin,
                .pantothenicAcid, .phosphorus, .polyunsaturatedFat, .potassium, .protein, .riboflavin, .saturatedFat,
                .selenium, .sodium, .sugars, .thiamin, .totalCarbohydrate, .totalFat, .vitaminA, .vitaminB6,
                .vitaminB12, .vitaminC, .vitaminD, .vitaminE, .vitaminK, .zinc]
    }
}

extension NutritionKind.Unit {
    fileprivate var hkUnit: HKUnit {
        switch self {
        case .calorie:      return .kilocalorie()
        case .gram:         return .gram()
        case .milligram:    return .gramUnit(with: .milli)
        case .microgram:    return .gramUnit(with: .micro)
        }
    }
}

extension HKHealthStore {
    fileprivate func delete(foodEntryIds ids: [String], completion completionHandler: @escaping (Error?) -> ()) {
        if ids.isEmpty {
            completionHandler(nil)
        } else {
            let predicate = NSPredicate(format: "\(HKPredicateKeyPathMetadata).FoodlogID IN %@", ids)
            let query = HKCorrelationQuery(type: .correlationType(forIdentifier: .food)!,
                                           predicate: predicate, samplePredicates: nil)
            { [weak self] in
                if let error = $2 {
                    completionHandler(error)
                } else if let matches = $1 {
                    if matches.count > 0 {
                        self!.delete(matches.flatMap { $0.objects }) {
                            if let error = $1 {
                                completionHandler(error)
                            } else {
                                self!.delete(matches) { completionHandler($1) }
                            }
                        }
                    } else {
                        completionHandler(nil)
                    }
                } else {
                    completionHandler(nil)
                }
            }
            execute(query)
        }
    }
    
    fileprivate func save(foodEntryHKObjects objects: [HKObject],
                          completion completionHandler: @escaping (Error?) -> ())
    {
        if objects.isEmpty {
            completionHandler(nil)
        } else {
            save(objects) { completionHandler($1) }
        }
    }
}
