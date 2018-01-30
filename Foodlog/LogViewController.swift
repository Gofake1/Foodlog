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
    
    private var notificationToken: NotificationToken?
    private let sortedFoodEntries = DataStore.objects(FoodEntry.self, sortedBy: #keyPath(FoodEntry.date))!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        VCController.logVC = self
    }
    
    override func viewDidLoad() {
        notificationToken = sortedFoodEntries.observe { [weak self] (changes) in
            guard let tableView = self?.tableView else { return }
            switch changes {
            case .initial:
                tableView.reloadData()
            case .update(_, let deletions, let insertions, let mods):
                tableView.performBatchUpdates({
                    tableView.deleteRows(at: deletions.map({ IndexPath(item: $0, section: 0) }), with: .automatic)
                    tableView.insertRows(at: insertions.map({ IndexPath(item: $0, section: 0) }), with: .automatic)
                    tableView.reloadRows(at: mods.map({ IndexPath(item: $0, section: 0) }), with: .automatic)
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
        notificationToken?.invalidate()
    }
}

extension LogViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedFoodEntries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Food", for: indexPath)
        let foodEntry = sortedFoodEntries[indexPath.item] //*
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
                    cell.detailTextLabel?.text = fraction+representation.short
                }
            case .decimal:
                if let decimal = value.to(Float.self).pretty {
                    cell.detailTextLabel?.text = decimal+representation.short
                }
            }
        }
        
        return cell
    }
}

extension LogViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let foodEntry = sortedFoodEntries[indexPath.item] //*
        VCController.selectFoodEntry(foodEntry)
    }
}

extension MeasurementRepresentation {
    var short: String {
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
