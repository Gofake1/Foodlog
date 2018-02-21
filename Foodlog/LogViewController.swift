//
//  LogViewController.swift
//  Foodlog
//
//  Created by David on 12/12/17.
//  Copyright © 2017 Gofake1. All rights reserved.
//

import RealmSwift
import UIKit

// TODO: Make Realm and HealthKit transactions atomic
class LogViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var defaultLogTableController: DefaultLogTableController!
    @IBOutlet weak var filteredLogTableController: FilteredLogTableController!
    
    private var currentLogTableController: LogTableController!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        VCController.logVC = self
    }
    
    override func viewDidLoad() {
        currentLogTableController = defaultLogTableController
        currentLogTableController.setup(tableView)
        
        tableView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 64.0, right: 0.0)
        tableView.scrollIndicatorInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 64.0, right: 0.0)
    }
    
    func clearTableSelection() {
        guard let indexPath = tableView.indexPathForSelectedRow else { return }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func filter(_ food: Food) {
        if currentLogTableController != filteredLogTableController {
            currentLogTableController = filteredLogTableController
            defaultLogTableController.tearDown()
            filteredLogTableController.setup(tableView)
        }
        filteredLogTableController.filter(food)
    }
    
    func clearFilter() {
        if currentLogTableController != defaultLogTableController {
            currentLogTableController = defaultLogTableController
            filteredLogTableController.tearDown()
            defaultLogTableController.setup(tableView)
        }
    }
}

class LogTableController: NSObject {
    func setup(_ tableView: UITableView) {}
    func tearDown() {}
}

class DefaultLogTableController: LogTableController {
    private var daysChangeToken: NotificationToken!
    private let sortedDays = DataStore.days.sorted(byKeyPath: #keyPath(Day.startOfDay))

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
        cell.displayFraction = foodEntry.measurementValueRepresentation ==
            FoodEntry.MeasurementValueRepresentation.fraction
        cell.titleLabel?.text = foodEntry.food?.name ?? "Unnamed"
        cell.subtitleLabel?.text = foodEntry.date.noDateShortTimeString
        cell.detailLabel?.text = foodEntry.measurementLabelText ?? "?"
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle,
                   forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        if sortedDays[indexPath.section].sortedFoodEntries.count <= 1 {
            HealthKitStore.shared.delete([sortedDays[indexPath.section].sortedFoodEntries[indexPath.row].id], {})
            DataStore.delete(sortedDays[indexPath.section].sortedFoodEntries[indexPath.row],
                             withoutNotifying: [daysChangeToken])
            DataStore.delete(sortedDays[indexPath.section], withoutNotifying: [daysChangeToken])
            tableView.deleteSections(IndexSet([indexPath.section]), with: .automatic)
        } else {
            HealthKitStore.shared.delete([sortedDays[indexPath.section].sortedFoodEntries[indexPath.row].id], {})
            DataStore.delete(sortedDays[indexPath.section].sortedFoodEntries[indexPath.row],
                             withoutNotifying: [daysChangeToken])
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}

extension DefaultLogTableController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if tableView.cellForRow(at: indexPath)!.isSelected {
            tableView.deselectRow(at: indexPath, animated: true)
            VCController.pop()
            return nil
        } else {
            return indexPath
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let foodEntry = sortedDays[indexPath.section].sortedFoodEntries[indexPath.row]
        VCController.selectFoodEntry(foodEntry)
    }
}

class FilteredLogTableController: LogTableController {
    private weak var tableView: UITableView!
    private var foodEntriesChangeToken: NotificationToken!
    private var sortedFilteredFoodEntries: Results<FoodEntry>!
    
    override func setup(_ tableView: UITableView) {
        self.tableView = tableView
        tableView.dataSource = self
        tableView.delegate = nil
    }
    
    override func tearDown() {
        foodEntriesChangeToken.invalidate()
    }
    
    // TODO: Composable filtering
    func filter(_ food: Food) {
        sortedFilteredFoodEntries = DataStore.foodEntries.filter("food == %@", food)
            .sorted(byKeyPath: #keyPath(FoodEntry.date), ascending: false)
        foodEntriesChangeToken = sortedFilteredFoodEntries.observe { [weak self] in
            switch $0 {
            case .initial:
                self?.tableView.reloadData()
            case .update(_, let deletes, let inserts, let mods):
                self?.tableView.performBatchUpdates({
                    self?.tableView.deleteRows(at: deletes.map({ IndexPath(row: $0, section: 0) }), with: .automatic)
                    self?.tableView.insertRows(at: inserts.map({ IndexPath(row: $0, section: 0) }), with: .automatic)
                    self?.tableView.reloadRows(at: mods.map({ IndexPath(row: $0, section: 0) }), with: .automatic)
                })
            case .error(let error):
                UIApplication.shared.alert(error: error)
            }
        }
    }
}

extension FilteredLogTableController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedFilteredFoodEntries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! DetailSubtitleTableViewCell
        let foodEntry = sortedFilteredFoodEntries[indexPath.row]
        cell.displayFraction = foodEntry.measurementValueRepresentation ==
            FoodEntry.MeasurementValueRepresentation.fraction
        cell.titleLabel?.text = foodEntry.food?.name
        cell.subtitleLabel?.text = foodEntry.date.mediumDateShortTimeString
        cell.detailLabel?.text = foodEntry.measurementLabelText ?? "?"
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle,
                   forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        HealthKitStore.shared.delete([sortedFilteredFoodEntries[indexPath.row].id], {})
        DataStore.delete(sortedFilteredFoodEntries[indexPath.row], withoutNotifying: [foodEntriesChangeToken])
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
}

private let _defaultFont = UIFont.monospacedDigitSystemFont(ofSize: 17.0, weight: .regular)
private let _fractionFont: UIFont = {
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

class DetailSubtitleTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel! {
        didSet {
            detailLabel.font = _defaultFont
        }
    }
    @IBOutlet weak var subtitleLabel: UILabel!
    
    var displayFraction = false {
        didSet {
            guard displayFraction != oldValue else { return }
            if displayFraction {
                detailLabel.font = _fractionFont
            } else {
                detailLabel.font = _defaultFont
            }
        }
    }
}

extension Day {
    var sortedFoodEntries: Results<FoodEntry> {
        return foodEntries.sorted(byKeyPath: #keyPath(FoodEntry.date), ascending: false)
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
