//
//  Sync.swift
//  Foodlog
//
//  Created by David on 4/29/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

// Workaround: CloudKit JIT schema can't infer `Food.tags`, `FoodEntry.food`, `FoodEntry.tags` as `CKReference`s.
// Set up those fields manually in CloudKit dashboard.

import CloudKit
import HealthKit.HKObject
import RealmSwift

private typealias Model = Object & Syncable & CascadeDeletable

final class Sync {
    private var recordsToChange   = [CKRecord]()
    private var recordIdsToDelete = [(String, CKRecordID)]()
    
    func change(_ record: CKRecord) {
        recordsToChange.append(record)
    }
    
    func delete(_ recordType: String, _ recordId: CKRecordID) {
        recordIdsToDelete.append((recordType, recordId))
    }
    
    /// - precondition: Must be called on Realm's thread (aka main)
    func process(completion completionHandler: @escaping (Error?) -> ()) {
        guard recordsToChange.count > 0 || recordIdsToDelete.count > 0 else { return }
        
        func tagToChangeForRecord(_ record: CKRecord) -> Object {
            let tag: Tag
            if let _tag = DataStore.object(Tag.self, primaryKey: record.recordID.recordName) {
                tag = Tag(value: _tag)
                tag.localRecord = CloudKitRecord(value: _tag.localRecord)
                tag.searchSuggestion = SearchSuggestion(value: _tag.searchSuggestion!)
            } else {
                tag = Tag()
                tag.id = record.recordID.recordName
                tag.localRecord = CloudKitRecord()
                tag.localRecord.recordName = record.recordID.recordName
                tag.localRecord.kind = .tag
                tag.searchSuggestion = SearchSuggestion()
                tag.searchSuggestion!.kind = .tag
            }
            tag.update(ckRecord: record)
            return tag
        }
        
        func foodToChangeForRecord(_ record: CKRecord) -> Object {
            let food: Food
            if let _food = DataStore.object(Food.self, primaryKey: record.recordID.recordName) {
                food = Food(value: _food)
                food.localRecord = CloudKitRecord(value: _food.localRecord)
                food.searchSuggestion = SearchSuggestion(value: _food.searchSuggestion!)
            } else {
                food = Food()
                food.id = record.recordID.recordName
                food.localRecord = CloudKitRecord()
                food.localRecord.recordName = record.recordID.recordName
                food.localRecord.kind = .food
                food.searchSuggestion = SearchSuggestion()
                food.searchSuggestion!.kind = .food
            }
            food.update(ckRecord: record)
            return food
        }
        
        /// - returns: `Day`s to update, `Day`s to delete, HealthKit IDs to delete, `HKObject`s to save, and
        //    invalid `CKRecord`s
        func processFoodEntryRecords(_ records: [CKRecord]) -> ([Object], [Object], [String], [HKObject], [CKRecord])
        {
            var dayObjectsForStartOfDay = [Date: Day]()
            var hkIds = [String]()
            var hkObjects = [HKObject]()
            var invalidRecords = [CKRecord]()
            for record in records {
                guard let startOfDay = (record["date"] as? Date)?.startOfDay else {
                    invalidRecords.append(record); continue }
                if dayObjectsForStartOfDay[startOfDay] == nil {
                    dayObjectsForStartOfDay[startOfDay] = _correctDay(startOfDay: startOfDay)
                }
                let foodEntry: FoodEntry
                if let _foodEntry = DataStore.object(FoodEntry.self, primaryKey: record.recordID.recordName) {
                    foodEntry = FoodEntry(value: _foodEntry)
                    foodEntry.localRecord = CloudKitRecord(value: _foodEntry.localRecord)
                    let previousStartOfDay = _foodEntry.day.startOfDay
                    if previousStartOfDay != startOfDay {
                        if dayObjectsForStartOfDay[previousStartOfDay] == nil {
                            dayObjectsForStartOfDay[previousStartOfDay] = _correctDay(startOfDay: previousStartOfDay)
                        }
                        dayObjectsForStartOfDay[previousStartOfDay]!.remove(foodEntry: _foodEntry)
                        dayObjectsForStartOfDay[startOfDay]!.foodEntries.append(foodEntry)
                    }
                } else {
                    foodEntry = FoodEntry()
                    foodEntry.id = record.recordID.recordName
                    foodEntry.localRecord = CloudKitRecord()
                    foodEntry.localRecord.recordName = record.recordID.recordName
                    foodEntry.localRecord.kind = .foodEntry
                    dayObjectsForStartOfDay[startOfDay]!.foodEntries.append(foodEntry)
                }
                foodEntry.update(ckRecord: record)
                
                hkIds.append(record.recordID.recordName)
                hkObjects.append(contentsOf: [foodEntry.hkObject].compactMap { $0 })
            }
            var days = Array(dayObjectsForStartOfDay.values)
            let partition = days.partition { $0.foodEntries.isEmpty }
            return (Array(days[..<partition]), Array(days[partition...]), hkIds, hkObjects, invalidRecords)
        }
        
        // TODO
        func groupToChangeForRecord(_ record: CKRecord) -> Object {
            fatalError()
        }
        
        func hkId(_ recordType: String, _ recordId: CKRecordID) -> String? {
            guard CloudKitRecord.Kind(ckRecordType: recordType)! == .foodEntry else { return nil }
            return recordId.recordName
        }
        
        func objectsToDeleteForRecordId(_ recordType: String, _ recordId: CKRecordID) -> [Object] {
            guard let localRecord = DataStore.object(CloudKitRecord.self, primaryKey: recordId.recordName)
                else { return [] }
            return localRecord.model.objectsToDelete
        }
        
        var foodRecords = [CKRecord]()
        var foodEntryRecords = [CKRecord]()
        var groupRecords = [CKRecord]()
        var tagRecords = [CKRecord]()
        for record in recordsToChange {
            switch CloudKitRecord.Kind(ckRecordType: record.recordType)! {
            case .food:         foodRecords.append(record)
            case .foodEntry:    foodEntryRecords.append(record)
            case .group:        groupRecords.append(record)
            case .tag:          tagRecords.append(record)
            }
        }
        
        // Model types saved in order of data dependencies:
        // 1. Save `Tag`s
        // 2. Save `Food`s
        // 3. Save `Day`s and `FoodGroupingTemplate`s
        // 4. Delete models that were deleted and prune `Day`s
        // 5. Delete HealthKit IDs whose models were deleted or updated, and save new `HKObject`s
        // 6. Delete invalid records
        let tagObjectsToChange = tagRecords.map(tagToChangeForRecord)
        DataStore.update(tagObjectsToChange) { [recordIdsToDelete] in
            if let error = $0 {
                completionHandler(error)
            } else {
                let foodObjectsToChange = foodRecords.map(foodToChangeForRecord)
                DataStore.update(foodObjectsToChange) {
                    if let error = $0 {
                        completionHandler(error)
                    } else {
                        let (dayObjectsToChange, dayObjectsToDelete, hkIds, hkObjects, invalidRecords) =
                            processFoodEntryRecords(foodEntryRecords)
                        let groupObjectsToChange = groupRecords.map(groupToChangeForRecord)
                        DataStore.update(dayObjectsToChange + groupObjectsToChange) {
                            if let error = $0 {
                                completionHandler(error)
                            } else {
                                let deletedHkIds = recordIdsToDelete.compactMap(hkId)
                                let objectsToDelete = recordIdsToDelete.flatMap(objectsToDeleteForRecordId)
                                DataStore.delete(objectsToDelete + dayObjectsToDelete) {
                                    if let error = $0 {
                                        completionHandler(error)
                                    } else {
                                        HealthKitStore.update(ids: hkIds + deletedHkIds, hkObjects: hkObjects) {
                                            if let error = $0 {
                                                completionHandler(error)
                                            } else {
                                                CloudStore.delete(invalidRecords.map { $0.recordID },
                                                                  completion: completionHandler)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

final class Changes<T> {
    var isEmpty: Bool {
        return keyPaths.isEmpty
    }
    private(set) var keyPaths = Set<PartialKeyPath<T>>()
    private var onInsert: () -> () = {}
    
    init() {}
    
    init(_ keyPaths: Set<PartialKeyPath<T>>) {
        self.keyPaths = keyPaths
    }
    
    func insert(change: PartialKeyPath<T>) {
        keyPaths.insert(change)
        onInsert()
    }
    
    func onInsertOnce(_ block: @escaping () -> ()) {
        onInsert = { [weak self] in
            block()
            self!.onInsert = {}
        }
    }
}

private protocol Syncable: class {
    var localRecord: CloudKitRecord { get set }
    var recordId: CKRecordID { get }
    var recordType: String { get }
    // Workaround: Implemented using string comparison because `KeyPath`s are not covariant. Therefore
    // `ReferenceWritableKeyPath<'Syncable', CKRecordValue>` requires too much boilerplate, and
    // `PartialKeyPath<'Syncable'>` doesn't allow writing.
    // https://forums.swift.org/t/keypath-collection-issue-where-value-is-an-existential/12044/5
    func set(key: String, to value: CKRecordValue)
}

extension Syncable {
    fileprivate func update(ckRecord: CKRecord) {
        localRecord.updateSystemFields(ckRecord)
        // Workaround: `CKRecord.changedKeys()` doesn't work as expected for "new" records
        for key in ckRecord.allKeys() {
            set(key: key, to: ckRecord[key]!)
        }
    }
}

extension Food: Syncable {
    fileprivate var localRecord: CloudKitRecord {
        get { return localCKRecord! }
        set { localCKRecord = newValue }
    }
    fileprivate var recordId: CKRecordID {
        return ckRecordId
    }
    fileprivate var recordType: String {
        return "Food"
    }
    
    fileprivate func set(key: String, to value: CKRecordValue) {
        switch key {
        case "biotin":              biotin = value as! Float
        case "caffeine":            caffeine = value as! Float
        case "calcium":             calcium = value as! Float
        case "calories":            calories = value as! Float
        case "chloride":            chloride = value as! Float
        case "cholesterol":         cholesterol = value as! Float
        case "chromium":            chromium = value as! Float
        case "copper":              copper = value as! Float
        case "dietaryFiber":        dietaryFiber = value as! Float
        case "folate":              folate = value as! Float
        case "iodine":              iodine = value as! Float
        case "iron":                iron = value as! Float
        case "lastUsed":            searchSuggestion!.lastUsed = value as! Date
        case "magnesium":           magnesium = value as! Float
        case "manganese":           manganese = value as! Float
        case "molybdenum":          molybdenum = value as! Float
        case "monounsaturatedFat":  monounsaturatedFat = value as! Float
        case "name":                name = value as! String; searchSuggestion!.text = value as! String
        case "niacin":              niacin = value as! Float
        case "pantothenicAcid":     pantothenicAcid = value as! Float
        case "phosphorus":          phosphorus = value as! Float
        case "polyunsaturatedFat":  polyunsaturatedFat = value as! Float
        case "potassium":           potassium = value as! Float
        case "protein":             protein = value as! Float
        case "riboflavin":          riboflavin = value as! Float
        case "saturatedFat":        saturatedFat = value as! Float
        case "selenium":            selenium = value as! Float
        case "servingSize":         servingSize = value as! Float
        case "servingSizeUnitRaw":  servingSizeUnitRaw = value as! Int
        case "sodium":              sodium = value as! Float
        case "sugars":              sugars = value as! Float
        case "tags":
            tags.removeAll()
            for recordName in (value as! [CKReference]).map({ $0.recordID.recordName }) {
                guard let tag = DataStore.object(Tag.self, primaryKey: recordName) else { continue }
                tags.append(tag)
            }
        case "thiamin":             thiamin = value as! Float
        case "totalCarbohydrate":   totalCarbohydrate = value as! Float
        case "totalFat":            totalFat = value as! Float
        case "transFat":            transFat = value as! Float
        case "vitaminA":            vitaminA = value as! Float
        case "vitaminB6":           vitaminB6 = value as! Float
        case "vitaminB12":          vitaminB12 = value as! Float
        case "vitaminC":            vitaminC = value as! Float
        case "vitaminD":            vitaminD = value as! Float
        case "vitaminE":            vitaminE = value as! Float
        case "vitaminK":            vitaminK = value as! Float
        case "zinc":                zinc = value as! Float
        default:                    break
        }
    }
}

extension FoodEntry: Syncable {
    fileprivate var localRecord: CloudKitRecord {
        get { return localCKRecord! }
        set { localCKRecord = newValue }
    }
    fileprivate var recordId: CKRecordID {
        return ckRecordId
    }
    fileprivate var recordType: String {
        return "FoodEntry"
    }
    
    fileprivate func set(key: String, to value: CKRecordValue) {
        switch key {
        case "date":
            date = value as! Date
        case "food":
            if let food = DataStore.object(Food.self, primaryKey: (value as! CKReference).recordID.recordName) {
                self.food = food
            }
        case "measurement":
            measurement = value as! Data
        case "measurementRepresentationRaw":
            measurementRepresentationRaw = value as! Int
        case "measurementUnitRaw":
            measurementUnitRaw = value as! Int
        case "tags":
            tags.removeAll()
            for recordName in (value as! [CKReference]).map({ $0.recordID.recordName }) {
                guard let tag = DataStore.object(Tag.self, primaryKey: recordName) else { continue }
                tags.append(tag)
            }
        default:
            break
        }
    }
}

extension FoodGroupingTemplate: Syncable {
    fileprivate var localRecord: CloudKitRecord {
        get { return localCKRecord! }
        set { localCKRecord = newValue }
    }
    fileprivate var recordId: CKRecordID {
        return ckRecordId
    }
    fileprivate var recordType: String {
        return "FoodGroupingTemplate"
    }
    
    fileprivate func set(key: String, to value: CKRecordValue) {
        switch key {
        default: fatalError()
        }
    }
}

extension Tag: Syncable {
    fileprivate var localRecord: CloudKitRecord {
        get { return localCKRecord! }
        set { localCKRecord = newValue }
    }
    fileprivate var recordId: CKRecordID {
        return ckRecordId
    }
    fileprivate var recordType: String {
        return "Tag"
    }
    
    fileprivate func set(key: String, to value: CKRecordValue) {
        switch key {
        case "colorCodeRaw":    colorCodeRaw = value as! Int
        case "lastUsed":        searchSuggestion!.lastUsed = value as! Date
        case "name":            name = value as! String; searchSuggestion!.text = value as! String
        default:                break
        }
    }
}

extension CloudKitRecord {
    fileprivate var model: Model {
        switch kind {
        case .food:         return foods.first!
        case .foodEntry:    return foodEntries.first!
        case .group:        return groups.first!
        case .tag:          return tags.first!
        }
    }
    
    fileprivate func updateSystemFields(_ ckRecord: CKRecord) {
        let data = NSMutableData()
        let encoder = NSKeyedArchiver(forWritingWith: data)
        encoder.requiresSecureCoding = true
        ckRecord.encodeSystemFields(with: encoder)
        encoder.finishEncoding()
        systemFields = data as Data
    }
}

extension CloudKitRecord.Kind {
    fileprivate init?(ckRecordType: String) {
        switch ckRecordType {
        case "Food":                    self = .food
        case "FoodEntry":               self = .foodEntry
        case "FoodGroupingTemplate":    self = .group
        case "Tag":                     self = .tag
        default:                        return nil
        }
    }
}

extension Food {
    var lastUsed: Date {
        return searchSuggestion!.lastUsed
    }
    var tagsCKReferences: [CKReference] {
        return tags.map { $0.ckReference } as [CKReference]
    }
    fileprivate var ckReference: CKReference {
        return CKReference(recordID: ckRecordId, action: .deleteSelf)
    }
    
    func ckRecord(from changes: Changes<Food>) -> CKRecord {
        return CKRecord(syncing: self, changes: changes)
    }
}

extension FoodEntry {
    var foodCKReference: CKReference {
        return food!.ckReference
    }
    var tagsCKReferences: [CKReference] {
        return tags.map { $0.ckReference } as [CKReference]
    }
    
    func ckRecord(from changes: Changes<FoodEntry>) -> CKRecord {
        return CKRecord(syncing: self, changes: changes)
    }
}

extension FoodGroupingTemplate {
    func ckRecord(from changes: Changes<FoodGroupingTemplate>) -> CKRecord {
        return CKRecord(syncing: self, changes: changes)
    }
}

extension Tag {
    var lastUsed: Date {
        return searchSuggestion!.lastUsed
    }
    fileprivate var ckReference: CKReference {
        return CKReference(recordID: ckRecordId, action: .none)
    }
    
    func ckRecord(from changes: Changes<Tag>) -> CKRecord {
        return CKRecord(syncing: self, changes: changes)
    }
}

extension CKRecord {
    fileprivate convenience init<T: Syncable>(syncing syncable: T, changes: Changes<T>) {
        if syncable.localRecord.systemFields != Data() {
            print("Created from saved") //*
            let decoder = NSKeyedUnarchiver(forReadingWith: syncable.localRecord.systemFields)
            decoder.requiresSecureCoding = true
            self.init(coder: decoder)!
            decoder.finishDecoding()
        } else {
            print("Created from new") //*
            self.init(recordType: syncable.recordType, recordID: syncable.recordId)
        }
        for keyPath in changes.keyPaths {
            self[keyPath.ckRecordKey] = syncable[keyPath: keyPath] as? CKRecordValue
        }
    }
}

extension PartialKeyPath where Root: Syncable {
    fileprivate var ckRecordKey: String {
        switch self {
        case \Food.biotin:                                      return "biotin"
        case \Food.caffeine:                                    return "caffeine"
        case \Food.calcium:                                     return "calcium"
        case \Food.calories:                                    return "calories"
        case \Food.chloride:                                    return "chloride"
        case \Food.cholesterol:                                 return "cholesterol"
        case \Food.chromium:                                    return "chromium"
        case \Food.copper:                                      return "copper"
        case \Food.dietaryFiber:                                return "dietaryFiber"
        case \Food.folate:                                      return "folate"
        case \Food.iodine:                                      return "iodine"
        case \Food.iron:                                        return "iron"
        case \Food.lastUsed:                                    return "lastUsed"
        case \Food.magnesium:                                   return "magnesium"
        case \Food.manganese:                                   return "manganese"
        case \Food.molybdenum:                                  return "molybdenum"
        case \Food.monounsaturatedFat:                          return "monounsaturatedFat"
        case \Food.name:                                        return "name"
        case \Food.niacin:                                      return "niacin"
        case \Food.pantothenicAcid:                             return "pantothenicAcid"
        case \Food.phosphorus:                                  return "phosphorus"
        case \Food.polyunsaturatedFat:                          return "polyunsaturatedFat"
        case \Food.potassium:                                   return "potassium"
        case \Food.protein:                                     return "protein"
        case \Food.riboflavin:                                  return "riboflavin"
        case \Food.saturatedFat:                                return "saturatedFat"
        case \Food.selenium:                                    return "selenium"
        case \Food.servingSize:                                 return "servingSize"
        case \Food.servingSizeUnitRaw:                          return "servingSizeUnitRaw"
        case \Food.sodium:                                      return "sodium"
        case \Food.sugars:                                      return "sugars"
        case \Food.tagsCKReferences:                            return "tags"
        case \Food.thiamin:                                     return "thiamin"
        case \Food.totalCarbohydrate:                           return "totalCarbohydrate"
        case \Food.totalFat:                                    return "totalFat"
        case \Food.transFat:                                    return "transFat"
        case \Food.vitaminA:                                    return "vitaminA"
        case \Food.vitaminB6:                                   return "vitaminB6"
        case \Food.vitaminB12:                                  return "vitaminB12"
        case \Food.vitaminC:                                    return "vitaminC"
        case \Food.vitaminD:                                    return "vitaminD"
        case \Food.vitaminE:                                    return "vitaminE"
        case \Food.vitaminK:                                    return "vitaminK"
        case \Food.zinc:                                        return "zinc"
        case \FoodEntry.date:                                   return "date"
        case \FoodEntry.foodCKReference:                        return "food"
        case \FoodEntry.measurement:                            return "measurement"
        case \FoodEntry.measurementRepresentationRaw:           return "measurementRepresentationRaw"
        case \FoodEntry.measurementUnitRaw:                     return "measurementUnitRaw"
        case \FoodEntry.tagsCKReferences:                       return "tags"
//        case \FoodGroupingTemplate.lastUsed:                    return "lastUsed"
//        case \FoodGroupingTemplate.name:                        return "name"
        case \Tag.colorCodeRaw:                                 return "colorCodeRaw"
        case \Tag.lastUsed:                                     return "lastUsed"
        case \Tag.name:                                         return "name"
        default:                                                fatalError()
        }
    }
}
