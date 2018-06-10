//
//  LogViewController.swift
//  Foodlog
//
//  Created by David on 12/12/17.
//  Copyright © 2017 Gofake1. All rights reserved.
//

import RealmSwift
import UIKit

// TODO: Bold title of foods
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
                UIApplication.shared.alert(error: error)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! DetailSubtitleTableViewCell
        let foodEntry = sortedDays[indexPath.section].sortedFoodEntries[indexPath.row]
        cell.displaysFraction = foodEntry.measurementRepresentation == .fraction
        cell.titleLabel?.text = foodEntry.food?.name ?? "Unnamed"
        cell.subtitleLabel?.attributedText = ([(foodEntry.date.noDateShortTimeString, UIColor.darkText)] +
            foodEntry.tags.prefix(5).map { ($0.name, $0.color) }).attributedString
        cell.detailLabel?.text = foodEntry.measurementLabelText ?? "?"
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle,
                   forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let day = sortedDays[indexPath.section]
        let foodEntry = day.sortedFoodEntries[indexPath.row]
        let (objects, delete) = day.foodEntries.count <= 1 ?
            (foodEntry.objectsToDelete + [day], {
                tableView.deleteSections(.init([indexPath.section]), with: .automatic)}) :
            (foodEntry.objectsToDelete, {
                tableView.deleteRows(at: [indexPath], with: .automatic )})
        let hkIds = [foodEntry.id]
        let ckIds = [foodEntry.ckRecordId]
        DataStore.delete(objects, withoutNotifying: [daysChangeToken]) {
            if let error = $0 {
                UIApplication.shared.alert(error: error)
            } else {
                HealthKitStore.delete(hkIds) {
                    if let error = $0 {
                        UIApplication.shared.alert(error: error)
                    } else {
                        CloudStore.delete(ckIds) {
                            if let error = $0 {
                                UIApplication.shared.alert(error: error)
                            }
                        }
                    }
                }
            }
        }
        delete()
    }
}

extension DefaultLogTableController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if tableView.cellForRow(at: indexPath)!.isSelected {
            tableView.deselectRow(at: indexPath, animated: true)
            assert(VCController.drawerStack.last?.state == .detail)
            VCController.pop()
            return nil
        } else {
            return indexPath
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        VCController.showDetail(sortedDays[indexPath.section].sortedFoodEntries[indexPath.row])
    }
}

extension Day {
    fileprivate var sortedFoodEntries: Results<FoodEntry> {
        return foodEntries.sorted(byKeyPath: #keyPath(FoodEntry.date), ascending: false)
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
                updateTableData(AnyRandomAccessCollection(results.map(AnyFilteredResult.init)))
                tableView!.performBatchUpdates({
                    tableView!.deleteRows(at: deletes.map { .init(row: $0, section: section) }, with: .automatic)
                    tableView!.insertRows(at: inserts.map { .init(row: $0, section: section) }, with: .automatic)
                    tableView!.reloadRows(at: reloads.map { .init(row: $0, section: section) }, with: .automatic)
                })
            case .error(let error):
                UIApplication.shared.alert(error: error)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! DetailSubtitleTableViewCell
        let item = tableData[indexPath.section][AnyIndex(indexPath.row)]
        cell.displaysFraction = item.filteredDetailDisplaysFraction
        cell.titleLabel?.text = item.filteredTitle
        cell.subtitleLabel?.attributedText = item.filteredSubtitle
        cell.detailLabel?.text = item.filteredDetail
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle,
                   forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        tableData[indexPath.section][AnyIndex(indexPath.row)].filteredOnDelete {
            if let error = $0 {
                UIApplication.shared.alert(error: error)
            }
        }
    }
}

extension FilteredLogTableController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if tableView.cellForRow(at: indexPath)!.isSelected {
            tableView.deselectRow(at: indexPath, animated: true)
            assert(VCController.drawerStack.last?.state == .detail)
            VCController.pop()
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
    var filteredDetail: String { get }
    var filteredDetailDisplaysFraction: Bool { get }
    var filteredTitle: String { get }
    var filteredSubtitle: NSAttributedString { get }
    func filteredOnDelete(completion completionHandler: @escaping (Error?) -> ())
}

private struct AnyFilteredResult: FilteredResultType {
    var filteredDetail: String {
        return base.filteredDetail
    }
    var filteredDetailDisplaysFraction: Bool {
        return base.filteredDetailDisplaysFraction
    }
    var filteredTitle: String {
        return base.filteredTitle
    }
    var filteredSubtitle: NSAttributedString {
        return base.filteredSubtitle
    }
    var logDetailPresentable: LogDetailPresentable {
        return base as! LogDetailPresentable
    }
    private let base: FilteredResultType
    
    init(_ base: FilteredResultType) {
        self.base = base
    }
    
    func filteredOnDelete(completion completionHandler: @escaping (Error?) -> ()) {
        base.filteredOnDelete(completion: completionHandler)
    }
}

extension Food: FilteredResultType {
    fileprivate var filteredDetail: String {
        return ""
    }
    fileprivate var filteredDetailDisplaysFraction: Bool {
        return false
    }
    fileprivate var filteredTitle: String {
        return name
    }
    fileprivate var filteredSubtitle: NSAttributedString {
        return ([(String(entries.count)+" entries", UIColor.darkText)] +
            tags.prefix(5).map { ($0.name, $0.color) }).attributedString
    }
    
    fileprivate func filteredOnDelete(completion completionHandler: @escaping (Error?) -> ()) {
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
            UIApplication.shared.alert(warning: warning, confirm: { delete(foodEntries, objects, prune: days) })
        } else {
            delete(foodEntries, objects, prune: days)
        }
    }
}

extension FoodEntry: FilteredResultType {
    fileprivate var filteredDetail: String {
        return measurementLabelText ?? "?"
    }
    fileprivate var filteredDetailDisplaysFraction: Bool {
        return measurementRepresentation == .fraction
    }
    fileprivate var filteredTitle: String {
        return food!.name
    }
    fileprivate var filteredSubtitle: NSAttributedString {
        return ([(date.mediumDateShortTimeString, UIColor.darkText)] +
            tags.prefix(5).map { ($0.name, $0.color) }).attributedString
    }
    
    fileprivate func filteredOnDelete(completion completionHandler: @escaping (Error?) -> ()) {
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

final class DetailSubtitleTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel! {
        didSet {
            detailLabel.font = DetailSubtitleTableViewCell.defaultFont
        }
    }
    @IBOutlet weak var subtitleLabel: UILabel!
    
    private static let defaultFont = UIFont.monospacedDigitSystemFont(ofSize: 17.0, weight: .regular)
    private static let fractionFont: UIFont = {
        let descriptor = UIFont.systemFont(ofSize: 20.0, weight: .light).fontDescriptor.addingAttributes(
            [
                .featureSettings: [
                    [
                        UIFontDescriptor.FeatureKey.featureIdentifier: kFractionsType,
                        UIFontDescriptor.FeatureKey.typeIdentifier: kDiagonalFractionsSelector
                    ]
                ]
            ])
        return UIFont(descriptor: descriptor, size: 0.0)
    }()
    
    var displaysFraction = false {
        didSet {
            guard displaysFraction != oldValue else { return }
            if displaysFraction {
                detailLabel.font = DetailSubtitleTableViewCell.fractionFont
            } else {
                detailLabel.font = DetailSubtitleTableViewCell.defaultFont
            }
        }
    }
}

extension FoodEntry {
    fileprivate var measurementLabelText: String? {
        guard let measurementString = measurementString else { return nil }
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
