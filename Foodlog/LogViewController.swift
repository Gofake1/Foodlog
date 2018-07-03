//
//  LogViewController.swift
//  Foodlog
//
//  Created by David on 12/12/17.
//  Copyright © 2017 Gofake1. All rights reserved.
//

import RealmSwift
import UIKit

final class LogViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    private var currentLogTableController: Either<LogTableController>!
    private let defaultLogTableController = DefaultLogTableController()
    private let filteredLogTableController = FilteredLogTableController()
    
    override func viewDidLoad() {
        let onSwitchController: (LogTableController, LogTableController) -> () = { [tableView] in
            $0.tearDown()
            $1.setup(tableView!)
        }
        currentLogTableController = Either(a: defaultLogTableController, b: filteredLogTableController,
                                           onAtoB: onSwitchController, onBtoA: onSwitchController)
        currentLogTableController.current.setup(tableView)
        
        tableView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 64.0, right: 0.0)
        tableView.scrollIndicatorInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 64.0, right: 0.0)
    }
    
    func clearTableSelection() {
        guard let indexPath = tableView.indexPathForSelectedRow else { return }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func filter(_ food: Food) {
        currentLogTableController.change(to: .b)
        filteredLogTableController.filter(food)
    }
    
    func filter(_ tag: Tag) {
        currentLogTableController.change(to: .b)
        filteredLogTableController.filter(tag)
    }
    
    func clearFilter() {
        assert(currentLogTableController.current === filteredLogTableController)
        currentLogTableController.change(to: .a)
    }
}

private struct Either<T> {
    enum Side {
        case a
        case b
    }
    
    var current: T {
        switch side {
        case .a: return a
        case .b: return b
        }
    }
    private let a: T
    private let b: T
    private let onAtoB: (T, T) -> ()
    private let onBtoA: (T, T) -> ()
    private var side: Side = .a
    
    init(a: T, b: T, onAtoB: @escaping (T, T) -> (), onBtoA: @escaping (T, T) -> ()) {
        self.a = a
        self.b = b
        self.onAtoB = onAtoB
        self.onBtoA = onBtoA
    }
    
    mutating func change(to side: Side) {
        guard side != self.side else { return }
        self.side = side
        switch side {
        case .a: onBtoA(b, a)
        case .b: onAtoB(a, b)
        }
    }
}

private class LogTableController: NSObject {
    func setup(_ tableView: UITableView) {}
    func tearDown() {}
}

private final class DefaultLogTableController: LogTableController {
    private var daysChangeToken: NotificationToken!
    private let sortedDays = DataStore.days.sorted(byKeyPath: #keyPath(Day.startOfDay), ascending: false)

    override func setup(_ tableView: UITableView) {
        tableView.dataSource = self
        tableView.delegate = self
        daysChangeToken = sortedDays.observe {
            switch $0 {
            case .initial:
                tableView.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                tableView.performBatchUpdates({
                    tableView.deleteSections(IndexSet(deletions), with: .automatic)
                    tableView.insertSections(IndexSet(insertions), with: .automatic)
                    tableView.reloadSections(IndexSet(modifications), with: .automatic)
                })
            case .error(let error):
                GlobalAlerts.append(error: error)
            }
        }
    }
    
    override func tearDown() {
        daysChangeToken.invalidate()
    }
}

extension DefaultLogTableController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sortedDays.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sortedDays[section].startOfDay.shortDateNoTimeString
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedDays[section].sortedFoodEntries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FoodEntryCell", for: indexPath)
            as! TitleSubtitleDetailTableViewCell
        let foodEntry = sortedDays[indexPath.section].sortedFoodEntries[indexPath.row]
        cell.configureForFoodEntry(foodEntry, \.noDateShortTimeString)
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle,
                   forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let day = sortedDays[indexPath.section]
        let foodEntry = day.sortedFoodEntries[indexPath.row]
        let (objects, delete) = day.foodEntries.count <= 1 ?
            (foodEntry.objectsToDelete + [day],
             { tableView.deleteSections(.init([$0.section]), with: .automatic) }) :
            (foodEntry.objectsToDelete,
             { tableView.deleteRows(at: [$0], with: .automatic) })
        let hkIds = [foodEntry.id]
        let ckIds = [foodEntry.ckRecordId]
        DataStore.delete(objects, withoutNotifying: [daysChangeToken]) {
            if let error = $0 {
                GlobalAlerts.append(error: error)
            } else {
                HealthKitStore.delete(hkIds) {
                    if let error = $0 {
                        GlobalAlerts.append(error: error)
                    } else {
                        CloudStore.delete(ckIds) {
                            if let error = $0 {
                                GlobalAlerts.append(error: error)
                            }
                        }
                    }
                }
            }
        }
        delete(indexPath)
    }
}

extension DefaultLogTableController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if tableView.cellForRow(at: indexPath)!.isSelected {
            tableView.deselectRow(at: indexPath, animated: true)
            VCController.dismissDetail()
            return nil
        } else {
            return indexPath
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        VCController.showDetail(sortedDays[indexPath.section].sortedFoodEntries[indexPath.row])
    }
}

private final class FilteredLogTableController: LogTableController {
    private weak var tableView: UITableView!
    private var tableData = [AnyRandomAccessCollection<AnyFilteredResult>]()
    private var tableDataChangeTokens = [NotificationToken]()
    
    override func setup(_ tableView: UITableView) {
        self.tableView = tableView
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func tearDown() {
        tableDataChangeTokens.forEach { $0.invalidate() }
    }
    
    func filter(_ food: Food) {
        tableDataChangeTokens.forEach { $0.invalidate() }
        let foodEntries = DataStore.foodEntries.filter("food == %@", food)
            .sorted(byKeyPath: #keyPath(FoodEntry.date), ascending: false)
        
        let foodEntryResults = foodEntries.map(AnyFilteredResult.init)
        tableData = [AnyRandomAccessCollection(foodEntryResults)]
        tableView.reloadData()
        
        let foodEntriesChangeToken = observe(foodEntries, section: 0) { [weak self] in self!.tableData[0] = $0 }
        tableDataChangeTokens = [foodEntriesChangeToken]
    }
    
    func filter(_ tag: Tag) {
        tableDataChangeTokens.forEach { $0.invalidate() }
        let foods       = tag.foods.sorted(byKeyPath: #keyPath(Food.name))
        let foodEntries = tag.foodEntries.sorted(byKeyPath: #keyPath(FoodEntry.date), ascending: false)
        
        let foodResults      = foods.map(AnyFilteredResult.init)
        let foodEntryResults = foodEntries.map(AnyFilteredResult.init)
        tableData = [AnyRandomAccessCollection(foodResults), AnyRandomAccessCollection(foodEntryResults)]
        tableView.reloadData()
        
        let foodsChangeToken       = observe(foods, section: 0) { [weak self] in self!.tableData[0] = $0 }
        let foodEntriesChangeToken = observe(foodEntries, section: 1) { [weak self] in self!.tableData[1] = $0 }
        tableDataChangeTokens = [foodsChangeToken, foodEntriesChangeToken]
    }
    
    private func observe<T: Object & FilteredResultType>(_ results: Results<T>, section: Int,
        updateTableData: @escaping (AnyRandomAccessCollection<AnyFilteredResult>) -> ()) -> NotificationToken
    {
        return results.observe { [tableView] in
            switch $0 {
            case .initial:
                break
            case .update(_, let deletes, let inserts, let reloads):
                // Keep `tableView` consistent if more than one `tableData` section is being modified
                DispatchQueue.main.async {
                    updateTableData(AnyRandomAccessCollection(results.map(AnyFilteredResult.init)))
                    tableView!.performBatchUpdates({
                        tableView!.deleteRows(at: deletes.map { .init(row: $0, section: section) }, with: .automatic)
                        tableView!.insertRows(at: inserts.map { .init(row: $0, section: section) }, with: .automatic)
                        tableView!.reloadRows(at: reloads.map { .init(row: $0, section: section) }, with: .automatic)
                    })
                }
            case .error(let error):
                GlobalAlerts.append(error: error)
            }
        }
    }
}

extension FilteredLogTableController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableData[indexPath.section][AnyIndex(indexPath.row)].dequeueCell(from: tableView, for: indexPath)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle,
                   forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        tableData[indexPath.section][AnyIndex(indexPath.row)].onDelete {
            if let error = $0 {
                GlobalAlerts.append(error: error)
            }
        }
    }
}

extension FilteredLogTableController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if tableView.cellForRow(at: indexPath)!.isSelected {
            tableView.deselectRow(at: indexPath, animated: true)
            VCController.dismissDetail()
            return nil
        } else {
            return indexPath
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        VCController.showDetail(tableData[indexPath.section][AnyIndex(indexPath.row)].logDetailPresentable)
    }
}

private protocol FilteredResultType {
    func dequeueCell(from tableView: UITableView, for indexPath: IndexPath) -> UITableViewCell
    func onDelete(completion completionHandler: @escaping (Error?) -> ())
}

private struct AnyFilteredResult: FilteredResultType {
    var logDetailPresentable: LogDetailPresentable {
        return base as! LogDetailPresentable
    }
    private let base: FilteredResultType
    
    init(_ base: FilteredResultType) {
        self.base = base
    }
    
    func dequeueCell(from tableView: UITableView, for indexPath: IndexPath) -> UITableViewCell {
        return base.dequeueCell(from: tableView, for: indexPath)
    }
    
    func onDelete(completion completionHandler: @escaping (Error?) -> ()) {
        base.onDelete(completion: completionHandler)
    }
}

extension Food: FilteredResultType {
    fileprivate func dequeueCell(from tableView: UITableView, for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FoodCell", for: indexPath)
        cell.textLabel!.text = name
        cell.detailTextLabel!.attributedText = ([("\(entries.count) entries", UIColor.darkText)]
            + tags.prefix(5).map { ($0.name, $0.color) }).attributedString
        return cell
    }
    
    fileprivate func onDelete(completion completionHandler: @escaping (Error?) -> ()) {
        func delete(_ foodEntries: [FoodEntry], _ objects: [Object], prune days: Set<Day>) {
            let hkIds = foodEntries.map { $0.id }
            let ckIds = [ckRecordId]
            DataStore.delete(objects) {
                if let error = $0 {
                    completionHandler(error)
                } else {
                    DataStore.delete(days.filter { $0.foodEntries.isEmpty }) {
                        if let error = $0 {
                            completionHandler(error)
                        } else {
                            HealthKitStore.delete(hkIds) {
                                if let error = $0 {
                                    completionHandler(error)
                                } else {
                                    CloudStore.delete(ckIds, completion: completionHandler)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        let (foodEntries, objects, days) = _deleteFood(self)
        if foodEntries.count > 0 {
            let warning = "Deleting this food item will also delete \(foodEntries.count) entries. This cannot be undone."
            GlobalAlerts.append(warning: warning, onConfirm: { delete(foodEntries, objects, prune: days) })
        } else {
            delete(foodEntries, objects, prune: days)
        }
    }
}

extension FoodEntry: FilteredResultType {
    fileprivate func dequeueCell(from tableView: UITableView, for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FoodEntryCell", for: indexPath)
            as! TitleSubtitleDetailTableViewCell
        cell.configureForFoodEntry(self, \.mediumDateShortTimeString)
        return cell
    }
    
    fileprivate func onDelete(completion completionHandler: @escaping (Error?) -> ()) {
        let _day = day
        let objects = _day.foodEntries.count <= 1 ? [self, _day] : [self]
        let hkIds = _day.foodEntries.map { $0.id } as Array
        let ckIds = _day.foodEntries.map { $0.ckRecordId } as Array
        DataStore.delete(objects) {
            if let error = $0 {
                completionHandler(error)
            } else {
                HealthKitStore.delete(hkIds) {
                    if let error = $0 {
                        completionHandler(error)
                    } else {
                        CloudStore.delete(ckIds, completion: completionHandler)
                    }
                }
            }
        }
    }
}

final class TitleSubtitleDetailTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel! {
        didSet {
            detailLabel.font = .monospacedDigitSystem17Regular
        }
    }
}

extension FoodEntry {
    fileprivate var detailLabelFont: UIFont {
        switch measurementRepresentation {
        case .decimal:  return .monospacedDigitSystem17Regular
        case .fraction: return .fractionSystem20Light
        }
    }
    
    fileprivate var measurementLabelText: String {
        guard let measurementString = measurementString else { return "?" }
        return measurementString+measurementUnit.shortSuffix
    }
}

extension Food.Unit {
    fileprivate var shortSuffix: String {
        switch self {
        case .none:         return ""
        case .gram:         return " g"
        case .milligram:    return " mg"
        case .ounce:        return " oz"
        case .milliliter:   return " mL"
        case .fluidOunce:   return " oz"
        }
    }
}

extension TitleSubtitleDetailTableViewCell {
    fileprivate func configureForFoodEntry(_ foodEntry: FoodEntry, _ dateStringKeyPath: KeyPath<Date, String>) {
        titleLabel.text = foodEntry.food!.name
        subtitleLabel.attributedText = ([(foodEntry.date[keyPath: dateStringKeyPath], UIColor.darkText)]
            + foodEntry.tags.prefix(5).map { ($0.name, $0.color) }).attributedString
        detailLabel.text = foodEntry.measurementLabelText
        let desiredDetailLabelFont = foodEntry.detailLabelFont
        if detailLabel.font !== desiredDetailLabelFont {
            detailLabel.font = desiredDetailLabelFont
        }
    }
}

private let _fractionSystem20Light: UIFont = {
    let descriptor = UIFont.systemFont(ofSize: 20.0, weight: .light).fontDescriptor.addingAttributes(
        [
            .featureSettings: [
                [
                    UIFontDescriptor.FeatureKey.featureIdentifier: kFractionsType,
                    UIFontDescriptor.FeatureKey.typeIdentifier: kDiagonalFractionsSelector
                ]
            ]
        ]
    )
    return UIFont(descriptor: descriptor, size: 0.0)
}()
private let _monospacedDigitSystem17Regular = UIFont.monospacedDigitSystemFont(ofSize: 17.0, weight: .regular)

extension UIFont {
    fileprivate static var fractionSystem20Light: UIFont {
        return _fractionSystem20Light
    }
    fileprivate static var monospacedDigitSystem17Regular: UIFont {
        return _monospacedDigitSystem17Regular
    }
}
