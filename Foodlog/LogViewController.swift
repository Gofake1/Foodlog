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
    
    private var daysChangeToken: NotificationToken!
    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .none
        return df
    }()
    private let sortedDays = DataStore.objects(Day.self, sortedBy: #keyPath(Day.startOfDay))!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        VCController.logVC = self
    }
    
    override func viewDidLoad() {
        daysChangeToken = sortedDays.observe { [weak self] (changes) in
            guard let tableView = self?.tableView else { return }
            switch changes {
            case .initial:
                tableView.reloadData()
            case .update(_, let deletes, let inserts, let mods):
                tableView.performBatchUpdates({
                    tableView.deleteSections(IndexSet(deletes), with: .automatic)
                    tableView.insertSections(IndexSet(inserts), with: .automatic)
                    tableView.reloadSections(IndexSet(mods), with: .automatic)
                })
            case .error(let error):
                UIApplication.shared.alert(error: error)
            }
        }
    }
    
    func clearTableSelection() {
        guard let indexPath = tableView.indexPathForSelectedRow else { return }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    deinit {
        daysChangeToken?.invalidate()
    }
}

extension LogViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sortedDays.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return LogViewController.dateFormatter.string(from: sortedDays[section].startOfDay)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedDays[section].sortedFoodEntries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Food", for: indexPath)
        let foodEntry = sortedDays[indexPath.section].sortedFoodEntries[indexPath.row]
        cell.textLabel?.text = foodEntry.food?.name ?? "Unnamed"
        cell.detailTextLabel?.text = "?"
        
        let valueRepresentationRaw = foodEntry.measurementValueRepresentationRaw
        if let valueRepresentation = MeasurementValueRepresentation(rawValue: valueRepresentationRaw),
            let representtionRaw = foodEntry.food?.measurementRepresentationRaw,
            let representation = MeasurementRepresentation(rawValue: representtionRaw)
        {
            let value = foodEntry.measurementValue
            switch valueRepresentation {
            case .fraction:
                if let fraction = Fraction.decode(from: value)?.description {
                    cell.detailTextLabel?.text = fraction+representation.suffix
                }
            case .decimal:
                if let decimal = value.to(Float.self).pretty {
                    cell.detailTextLabel?.text = decimal+representation.suffix
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle,
                   forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        if sortedDays[indexPath.section].sortedFoodEntries.count <= 1 {
            DataStore.delete(sortedDays[indexPath.section], withoutNotifying: [daysChangeToken])
            tableView.deleteSections(IndexSet([indexPath.section]), with: .automatic)
        } else {
            DataStore.delete(sortedDays[indexPath.section].sortedFoodEntries[indexPath.row],
                             withoutNotifying: [daysChangeToken])
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}

extension LogViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let foodEntry = sortedDays[indexPath.section].sortedFoodEntries[indexPath.row]
        VCController.selectFoodEntry(foodEntry)
    }
}

extension Day {
    var sortedFoodEntries: Results<FoodEntry> {
        return foodEntries.sorted(byKeyPath: #keyPath(FoodEntry.date), ascending: false)
    }
}

extension MeasurementRepresentation {
    var suffix: String {
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
