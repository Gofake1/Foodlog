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
            let types = Set(arrayLiteral: HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
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
                            HKObjectType.quantityType(forIdentifier: .dietaryPotassium)!)
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
        var objects = Set<HKSample>()
        func add(_ nutrition: NutritionKind) {
            let value = food![keyPath: nutrition.keyPath]
            guard value > 0.0 else { return }
            let quantity = HKQuantity(unit: nutrition.unit.hkUnit, doubleValue: Double(value * measurementFloat))
            objects.insert(HKQuantitySample(type: nutrition.hkType, quantity: quantity, start: date, end: date))
        }
        
        add(.calories)
        add(.totalFat)
        add(.saturatedFat)
        add(.monounsaturatedFat)
        add(.polyunsaturatedFat)
        add(.cholesterol)
        add(.sodium)
        add(.totalCarbohydrate)
        add(.dietaryFiber)
        add(.sugars)
        add(.protein)
        add(.vitaminA)
        add(.vitaminB6)
        add(.vitaminB12)
        add(.vitaminC)
        add(.vitaminD)
        add(.vitaminE)
        add(.vitaminK)
        add(.calcium)
        add(.iron)
        add(.magnesium)
        add(.potassium)
        
        guard objects.count > 0 else { return nil }
        
        let metadata: [String: Any] = [HKMetadataKeyFoodType: food!.name, "FoodlogID": id]
        return HKCorrelation(type: .correlationType(forIdentifier: .food)!,
                             start: date, end: date, objects: objects, metadata: metadata)
    }
}

extension NutritionKind {
    fileprivate var hkType: HKQuantityType {
        switch self {
        case .calories:             return .quantityType(forIdentifier: .dietaryEnergyConsumed)!
        case .totalFat:             return .quantityType(forIdentifier: .dietaryFatTotal)!
        case .saturatedFat:         return .quantityType(forIdentifier: .dietaryFatSaturated)!
        case .monounsaturatedFat:   return .quantityType(forIdentifier: .dietaryFatMonounsaturated)!
        case .polyunsaturatedFat:   return .quantityType(forIdentifier: .dietaryFatPolyunsaturated)!
        case .transFat:             fatalError()
        case .cholesterol:          return .quantityType(forIdentifier: .dietaryCholesterol)!
        case .sodium:               return .quantityType(forIdentifier: .dietarySodium)!
        case .totalCarbohydrate:    return .quantityType(forIdentifier: .dietaryCarbohydrates)!
        case .dietaryFiber:         return .quantityType(forIdentifier: .dietaryFiber)!
        case .sugars:               return .quantityType(forIdentifier: .dietarySugar)!
        case .protein:              return .quantityType(forIdentifier: .dietaryProtein)!
        case .vitaminA:             return .quantityType(forIdentifier: .dietaryVitaminA)!
        case .vitaminB6:            return .quantityType(forIdentifier: .dietaryVitaminB6)!
        case .vitaminB12:           return .quantityType(forIdentifier: .dietaryVitaminB12)!
        case .vitaminC:             return .quantityType(forIdentifier: .dietaryVitaminC)!
        case .vitaminD:             return .quantityType(forIdentifier: .dietaryVitaminD)!
        case .vitaminE:             return .quantityType(forIdentifier: .dietaryVitaminE)!
        case .vitaminK:             return .quantityType(forIdentifier: .dietaryVitaminK)!
        case .calcium:              return .quantityType(forIdentifier: .dietaryCalcium)!
        case .iron:                 return .quantityType(forIdentifier: .dietaryIron)!
        case .magnesium:            return .quantityType(forIdentifier: .dietaryMagnesium)!
        case .potassium:            return .quantityType(forIdentifier: .dietaryPotassium)!
        }
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
        if ids.count == 0 {
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
        if objects.count == 0 {
            completionHandler(nil)
        } else {
            save(objects) { completionHandler($1) }
        }
    }
}
