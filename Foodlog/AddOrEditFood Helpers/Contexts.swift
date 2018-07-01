//
//  Contexts.swift
//  Foodlog
//
//  Created by David on 3/21/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import CloudKit.CKRecord
import HealthKit.HKObject

protocol AddOrEditFoodContextType: class {
    var name: String { get set }
    func configure(_ vc: AddOrEditFoodViewController)
    /// - postcondition: Writes to data store, cloud store, and HealthKit
    /// - returns: If the save operation requires user confirmation, returns a block that should be called.
    func save(completionHandler: @escaping (Error?) -> ()) -> (Int, () -> ())?
}

final class AddEntryForExistingFoodContext: AddOrEditFoodContextType {    
    var name: String {
        get { return foodEntry.food!.name }
        set { fatalError() }
    }
    private let foodEntry: FoodEntry
    
    init(_ foodEntry: FoodEntry) {
        self.foodEntry = foodEntry
        self.foodEntry.food = Food(value: foodEntry.food!)
    }
    
    func configure(_ vc: AddOrEditFoodViewController) {
        vc.useLabelForName(name)
        vc.useBView()
        
        vc.amountController.setup(AmountController.NewFoodEntry(foodEntry))
        vc.dateController.setup(DateController.NewFoodEntry(foodEntry))
        vc.foodEntryTagController.setup(TagController.NewFoodEntry(foodEntry))
        vc.foodTagController.setup(TagController.DisabledFood(foodEntry.food!))
        vc.nutritionController.setup(NutritionController.Disabled(foodEntry.food!))
    }
    
    func save(completionHandler: @escaping (Error?) -> ()) -> (Int, () -> ())? {
        foodEntry.localCKRecord = CloudKitRecord()
        foodEntry.localCKRecord!.kind = .foodEntry
        foodEntry.localCKRecord!.recordName = foodEntry.id
        foodEntry.food!.searchSuggestion! = SearchSuggestion(value: foodEntry.food!.searchSuggestion!)
        let foodEntryRecord = foodEntry.ckRecord(from: FoodEntry.changedAll)
        addFoodEntry(foodEntry, ckRecords: [foodEntryRecord], completion: completionHandler)
        return nil
    }
}

final class AddEntryForNewFoodContext: AddOrEditFoodContextType {
    var name: String {
        get { return foodEntry.food!.name }
        set { foodEntry.food!.name = newValue }
    }
    private let foodEntry: FoodEntry
    
    init(_ foodEntry: FoodEntry) {
        self.foodEntry = foodEntry
    }
    
    func configure(_ vc: AddOrEditFoodViewController) {
        vc.useLabelForName(name)
        vc.useAView()
        
        vc.amountController.setup(AmountController.NewFoodEntry(foodEntry))
        vc.dateController.setup(DateController.NewFoodEntry(foodEntry))
        vc.foodEntryTagController.setup(TagController.NewFoodEntry(foodEntry))
        vc.foodTagController.setup(TagController.EnabledNewFood(foodEntry.food!))
        vc.nutritionController.setup(NutritionController.EnabledNewFood(foodEntry.food!))
        vc.servingSizeController.setup(ServingSizeController.NewFood(foodEntry.food!))
    }
    
    func save(completionHandler: @escaping (Error?) -> ()) -> (Int, () -> ())? {
        foodEntry.localCKRecord = CloudKitRecord()
        foodEntry.localCKRecord!.kind = .foodEntry
        foodEntry.localCKRecord!.recordName = foodEntry.id
        foodEntry.food!.localCKRecord = CloudKitRecord()
        foodEntry.food!.localCKRecord!.kind = .food
        foodEntry.food!.localCKRecord!.recordName = foodEntry.food!.id
        foodEntry.food!.searchSuggestion = SearchSuggestion()
        foodEntry.food!.searchSuggestion!.kind = .food
        foodEntry.food!.searchSuggestion!.text = name
        let ckRecords = [foodEntry.food!.ckRecord(from: Food.changedAll),
                         foodEntry.ckRecord(from: FoodEntry.changedAll)]
        addFoodEntry(foodEntry, ckRecords: ckRecords, completion: completionHandler)
        return nil
    }
}

final class EditFoodContext: AddOrEditFoodContextType {
    var name: String {
        get { return food.name }
        set {
            guard newValue != oldFood.name else { return }
            foodChanges.insert(change: \Food.name)
            food.name = newValue
            food.searchSuggestion!.text = newValue
        }
    }
    private let food: Food
    private let foodChanges = Changes<Food>()
    private let foodEntriesCount: Int
    private let oldFood: Food
    
    init(_ food: Food) {
        self.food = Food(value: food)
        self.food.searchSuggestion = SearchSuggestion(value: food.searchSuggestion!)
        foodEntriesCount = food.entries.count
        oldFood = food
    }
    
    func configure(_ vc: AddOrEditFoodViewController) {
        vc.useFieldForName(name)
        vc.configureAddToLogButton(title: "Update Log", isEnabled: false)
        vc.useCView()
        
        foodChanges.onInsertOnce { [weak vc] in vc?.addToLogButton.isEnabled = true }
        vc.foodTagController.setup(TagController.EnabledExistingFood(food, foodChanges))
        vc.nutritionController.setup(NutritionController.EnabledExistingFood(food, oldFood, foodChanges))
        vc.servingSizeController.setup(ServingSizeController.ExistingFood(food, foodChanges))
    }
    
    func save(completionHandler: @escaping (Error?) -> ()) -> (Int, () -> ())? {
        let foodRecord = food.ckRecord(from: foodChanges)
        return (foodEntriesCount, { [food] in
            DataStore.update([food]) {
                if let error = $0 {
                    completionHandler(error)
                } else {
                    let hkIds = food.entries.map { $0.id } as Array
                    let hkObjects = food.entries.compactMap { $0.hkObject } as Array
                    HealthKitStore.update(ids: hkIds, hkObjects: hkObjects) {
                        if let error = $0 {
                            completionHandler(error)
                        } else {
                            CloudStore.save([foodRecord], completion: completionHandler)
                        }
                    }
                }
            }
        })
    }
}

final class EditFoodEntryContext: AddOrEditFoodContextType {
    var name: String {
        get { return foodEntry.food!.name }
        set { fatalError() }
    }
    private let foodEntry: FoodEntry
    private let foodEntryChanges = Changes<FoodEntry>()
    private let oldFoodEntry: FoodEntry
    
    init(_ foodEntry: FoodEntry) {
        self.foodEntry = FoodEntry(value: foodEntry)
        oldFoodEntry = foodEntry
    }
    
    func configure(_ vc: AddOrEditFoodViewController) {
        vc.useFieldForName(name)
        vc.configureAddToLogButton(title: "Update Log", isEnabled: false)
        vc.useBView()
        
        foodEntryChanges.onInsertOnce { [weak vc] in vc?.addToLogButton.isEnabled = true }
        vc.amountController.setup(AmountController.ExistingFoodEntry(foodEntry, foodEntryChanges))
        vc.dateController.setup(DateController.ExistingFoodEntry(foodEntry, foodEntryChanges))
        vc.foodEntryTagController.setup(TagController.ExistingFoodEntry(foodEntry, foodEntryChanges))
        vc.foodTagController.setup(TagController.DisabledFood(foodEntry.food!))
        vc.nutritionController.setup(NutritionController.Disabled(foodEntry.food!))
    }
    
    func save(completionHandler: @escaping (Error?) -> ()) -> (Int, () -> ())? {
        let oldDay = oldFoodEntry.day
        
        func saveLocally(completion completionHandler: @escaping (Error?) -> ()) {            
            func updateOldDay(completion completionHandler: @escaping (Error?) -> ()) {
                let _oldDay = Day(value: oldDay)
                _oldDay.remove(foodEntry: oldFoodEntry)
                if _oldDay.foodEntries.count <= 0 {
                    DataStore.delete([oldDay], completion: completionHandler)
                } else {
                    DataStore.update([_oldDay], completion: completionHandler)
                }
            }
            
            if oldDay.startOfDay != foodEntry.date.startOfDay {
                let correctDay = _correctDay(startOfDay: foodEntry.date.startOfDay)
                correctDay.foodEntries.append(foodEntry)
                DataStore.update([correctDay]) {
                    if let error = $0 {
                        completionHandler(error)
                    } else {
                        updateOldDay(completion: completionHandler)
                    }
                }
            } else {
                DataStore.update([foodEntry], completion: completionHandler)
            }
        }
        
        let hkIds = [foodEntry.id]
        let hkObjects = [foodEntry.hkObject].compactMap { $0 }
        let foodEntryRecord = foodEntry.ckRecord(from: foodEntryChanges)
        saveLocally {
            if let error = $0 {
                completionHandler(error)
            } else {
                HealthKitStore.update(ids: hkIds, hkObjects: hkObjects) {
                    if let error = $0 {
                        completionHandler(error)
                    } else {
                        CloudStore.save([foodEntryRecord], completion: completionHandler)
                    }
                }
            }
        }
        return nil
    }
}

private func addFoodEntry(_ foodEntry: FoodEntry, ckRecords: [CKRecord],
                          completion completionHandler: @escaping (Error?) -> ())
{
    foodEntry.food!.searchSuggestion!.lastUsed = Date()
    let day = _correctDay(startOfDay: foodEntry.date.startOfDay)
    day.foodEntries.append(foodEntry)
    DataStore.update([day]) {
        if let error = $0 {
            completionHandler(error)
        } else {
            HealthKitStore.save([foodEntry.hkObject].compactMap { $0 }) {
                if let error = $0 {
                    completionHandler(error)
                } else {
                    CloudStore.save(ckRecords, completion: completionHandler)
                }
            }
        }
    }
}

extension Food {
    fileprivate static var changedAll: Changes<Food> {
        let keyPaths = Set(arrayLiteral: \Food.biotin,
                           \Food.caffeine,
                           \Food.calcium,
                           \Food.calories,
                           \Food.chloride,
                           \Food.cholesterol,
                           \Food.chromium,
                           \Food.copper,
                           \Food.dietaryFiber,
                           \Food.folate,
                           \Food.iodine,
                           \Food.iron,
                           \Food.lastUsed,
                           \Food.magnesium,
                           \Food.manganese,
                           \Food.molybdenum,
                           \Food.monounsaturatedFat,
                           \Food.name,
                           \Food.niacin,
                           \Food.pantothenicAcid,
                           \Food.phosphorus,
                           \Food.polyunsaturatedFat,
                           \Food.potassium,
                           \Food.protein,
                           \Food.riboflavin,
                           \Food.saturatedFat,
                           \Food.selenium,
                           \Food.servingSize,
                           \Food.servingSizeUnitRaw,
                           \Food.sodium,
                           \Food.sugars,
                           \Food.tagsCKReferences,
                           \Food.thiamin,
                           \Food.totalCarbohydrate,
                           \Food.totalFat,
                           \Food.transFat,
                           \Food.vitaminA,
                           \Food.vitaminB12,
                           \Food.vitaminB6,
                           \Food.vitaminC,
                           \Food.vitaminD,
                           \Food.vitaminE,
                           \Food.vitaminK,
                           \Food.zinc)
        return Changes(keyPaths)
    }
}

extension FoodEntry {
    fileprivate static var changedAll: Changes<FoodEntry> {
        let keyPaths = Set(arrayLiteral: \FoodEntry.date,
                           \FoodEntry.foodCKReference,
                           \FoodEntry.measurement,
                           \FoodEntry.measurementRepresentationRaw,
                           \FoodEntry.measurementUnitRaw,
                           \FoodEntry.tagsCKReferences)
        return Changes(keyPaths)
    }
}
