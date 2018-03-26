//
//  LogViewController.swift
//  Foodlog
//
//  Created by David on 12/12/17.
//  Copyright © 2017 Gofake1. All rights reserved.
//

import RealmSwift
import UIKit

class LogViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    private var currentLogTableController: Either<LogTableController>!
    private let defaultLogTableController = DefaultLogTableController()
    private let filteredLogTableController = FilteredLogTableController()
    
    override func viewDidLoad() {
        let onSwitchController: (LogTableController, LogTableController) -> () = { [weak self] in
            $0.tearDown()
            $1.setup(self!.tableView)
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

struct Either<T> {
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

class LogTableController: NSObject {
    func setup(_ tableView: UITableView) {}
    func tearDown() {}
}

class DefaultLogTableController: LogTableController {
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
        cell.displaysFraction = foodEntry.measurementValueRepresentation == .fraction
        cell.titleLabel?.text = foodEntry.food?.name ?? "Unnamed"
        cell.subtitleLabel?.attributedText = ([(foodEntry.date.noDateShortTimeString, UIColor.darkText)] +
            foodEntry.tags.prefix(5).map { ($0.name, $0.color) }).attributedString
        cell.detailLabel?.text = foodEntry.measurementLabelText ?? "?"
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle,
                   forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        FoodEntry.delete(sortedDays[indexPath.section].sortedFoodEntries[indexPath.row],
                         withoutNotifying: [daysChangeToken])
        {
            if $0 {
                tableView.deleteSections(IndexSet([indexPath.section]), with: .automatic)
            } else {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        }
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
    var sortedFoodEntries: Results<FoodEntry> {
        return foodEntries.sorted(byKeyPath: #keyPath(FoodEntry.date), ascending: false)
    }
}

class FilteredLogTableController: LogTableController {    
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
        let foodEntriesChangeToken = foodEntries.observe { [weak self] in
            switch $0 {
            case .initial:
                break
            case .update(_, let deletions, let insertions, let mods):
                let foodEntryResults = foodEntries.map(AnyFilteredResult.init)
                self!.tableData = [AnyRandomAccessCollection(foodEntryResults)]
                self!.tableView.performBatchUpdates({
                    self!.tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                    self!.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                    self!.tableView.reloadRows(at: mods.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                })
            case .error(let error):
                UIApplication.shared.alert(error: error)
            }
        }
        tableDataChangeTokens = [foodEntriesChangeToken]
        let foodEntryResults = foodEntries.map(AnyFilteredResult.init)
        tableData = [AnyRandomAccessCollection(foodEntryResults)]
        tableView.reloadData()
    }
    
    func filter(_ tag: Tag) {
        tableDataChangeTokens.forEach { $0.invalidate() }
        let foods = tag.foods.sorted(byKeyPath: #keyPath(Food.name))
        let foodEntries = tag.foodEntries.sorted(byKeyPath: #keyPath(FoodEntry.date), ascending: false)
        let foodsChangeToken = foods.observe { [weak self] in
            switch $0 {
            case .initial:
                break
            case .update(_, let deletions, let insertions, let mods):
                let foodResults = foods.map(AnyFilteredResult.init)
                self!.tableData[0] = AnyRandomAccessCollection(foodResults)
                self!.tableView.performBatchUpdates({
                    self!.tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                    self!.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                    self!.tableView.reloadRows(at: mods.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                })
            case .error(let error):
                UIApplication.shared.alert(error: error)
            }
        }
        let foodEntriesChangeToken = foodEntries.observe { [weak self] in
            switch $0 {
            case .initial:
                break
            case .update(_, let deletions, let insertions, let mods):
                let foodEntryResults = foodEntries.map(AnyFilteredResult.init)
                self!.tableData[1] = AnyRandomAccessCollection(foodEntryResults)
                self!.tableView.performBatchUpdates({
                    self!.tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 1) }, with: .automatic)
                    self!.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 1) }, with: .automatic)
                    self!.tableView.reloadRows(at: mods.map { IndexPath(row: $0, section: 1) }, with: .automatic)
                })
            case .error(let error):
                UIApplication.shared.alert(error: error)
            }
        }
        tableDataChangeTokens = [foodsChangeToken, foodEntriesChangeToken]
        let foodResults = foods.map(AnyFilteredResult.init)
        let foodEntryResults = foodEntries.map(AnyFilteredResult.init)
        tableData = [AnyRandomAccessCollection(foodResults), AnyRandomAccessCollection(foodEntryResults)]
        tableView.reloadData()
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
        tableData[indexPath.section][AnyIndex(indexPath.row)].filteredOnDelete()
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

protocol FilteredResultType {
    var filteredDetail: String { get }
    var filteredDetailDisplaysFraction: Bool { get }
    var filteredTitle: String { get }
    var filteredSubtitle: NSAttributedString { get }
    func filteredOnDelete()
}

struct AnyFilteredResult: FilteredResultType {
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
    
    func filteredOnDelete() {
        base.filteredOnDelete()
    }
}

extension Food: FilteredResultType {
    var filteredDetail: String {
        return ""
    }
    var filteredDetailDisplaysFraction: Bool {
        return false
    }
    var filteredTitle: String {
        return name
    }
    var filteredSubtitle: NSAttributedString {
        return ([(String(entries.count)+" entries", UIColor.darkText)] +
            tags.prefix(5).map { ($0.name, $0.color) }).attributedString
    }
    
    func filteredOnDelete() {
        if let (count, onConfirm) = Food.delete(self) {
            let warning = "Deleting this food item will also delete \(count) entries. This cannot be undone."
            UIApplication.shared.alert(warning: warning, confirm: onConfirm)
        }
    }
}

extension FoodEntry: FilteredResultType {
    var filteredDetail: String {
        return measurementLabelText ?? "?"
    }
    var filteredDetailDisplaysFraction: Bool {
        return measurementValueRepresentation == .fraction
    }
    var filteredTitle: String {
        return food!.name
    }
    var filteredSubtitle: NSAttributedString {
        return ([(date.mediumDateShortTimeString, UIColor.darkText)] +
            tags.prefix(5).map { ($0.name, $0.color) }).attributedString
    }
    
    func filteredOnDelete() {
        FoodEntry.delete(self)
    }
}

class DetailSubtitleTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel! {
        didSet {
            detailLabel.font = DetailSubtitleTableViewCell.defaultFont
        }
    }
    @IBOutlet weak var subtitleLabel: UILabel!
    
    private static let defaultFont = UIFont.monospacedDigitSystemFont(ofSize: 17.0, weight: .regular)
    private static let fractionFont: UIFont = {
        let descriptor = UIFont.systemFont(ofSize: 20.0, weight: .light).fontDescriptor.addingAttributes([
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

extension Array where Element == (String, UIColor) {
    var attributedString: NSAttributedString {
        guard count > 0 else { return NSAttributedString() }
        guard count > 1 else {
            let string = self[0].0, color = self[0].1
            let attrString = NSMutableAttributedString(string: string)
            attrString.addAttribute(.foregroundColor, value: color, range: NSRange(location: 0, length: string.count))
            return attrString
        }
        var interleaved = [(String, UIColor)]()
        for el in self[0..<count-1] {
            interleaved.append(el)
            interleaved.append((" · ", UIColor.darkText))
        }
        interleaved.append(self[count-1])
        assert(interleaved.count == count*2-1)
        var string = ""
        var ranges = [NSRange]()
        for (str, _) in interleaved {
            ranges.append(NSRange(location: string.count, length: str.count))
            string += str
        }
        let attrString = NSMutableAttributedString(string: string)
        for (color, range) in zip(interleaved.map({ $0.1 }), ranges) {
            attrString.addAttribute(.foregroundColor, value: color, range: range)
        }
        return attrString
    }
}

extension FoodEntry {
    var measurementLabelText: String? {
        guard let food = food, let measurementString = measurementString else { return nil }
        return measurementString+food.measurementRepresentation.shortSuffix
    }
}

extension Food.MeasurementRepresentation {
    var shortSuffix: String {
        switch self {
        case .serving:      return ""
        case .milligram:    return " mg"
        case .gram:         return " g"
        case .ounce:        return " oz"
        case .pound:        return " lb"
        case .fluidOunce:   return " oz"
        }
    }
}
