//
//  AddOrSearchViewController.swift
//  Foodlog
//
//  Created by David on 12/27/17.
//  Copyright © 2017 Gofake1. All rights reserved.
//

import RealmSwift
import UIKit

protocol SuggestionType {
    var addAction: () -> () { get }
    var canBeAddedToLog: Bool { get }
    var canBeDeleted: Bool { get }
    var labelText: String { get }
}

extension Food: SuggestionType {
    var addAction: () -> () {
        return {
            let foodEntry = FoodEntry()
            foodEntry.food = self
            VCController.addFoodEntry(foodEntry, isNew: false)
        }
    }
    var canBeAddedToLog: Bool {
        return true
    }
    var canBeDeleted: Bool {
        return entries.count == 0
    }
    var labelText: String {
        return name
    }
}

extension Tag: SuggestionType {
    var addAction: () -> () {
        return {}
    }
    var canBeAddedToLog: Bool {
        return false
    }
    var canBeDeleted: Bool {
        return foods.count == 0 && foodEntries.count == 0
    }
    var labelText: String {
        return name
    }
}

extension FoodGroupingTemplate: SuggestionType {
    var addAction: () -> () {
        return {}
    }
    var canBeAddedToLog: Bool {
        return true
    }
    var canBeDeleted: Bool {
        return false
    }
    var labelText: String {
        return name
    }
}

// TODO: iPhone X UI
// TODO: Filter LogViewController
class AddOrSearchViewController: PulleyDrawerViewController {
    @IBOutlet weak var suggestionTableController: SuggestionTableController!
    @IBOutlet weak var buttonsView: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        VCController.drawers.append(self)
        VCController.drawerState.append(.addOrSearch)
        suggestionTableController.update()
    }
        
    func drawerPositionDidChange(drawer: PulleyViewController, bottomSafeArea: CGFloat) {
        switch drawer.drawerPosition {
        case .closed:
            fatalError("`drawerPosition` can not be `closed`")
        case .collapsed:
            searchBar.resignFirstResponder()
        case .open:
            break
        case .partiallyRevealed:
            searchBar.resignFirstResponder()
        }
    }
}

extension AddOrSearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard let searchText = searchBar.text else { return }
        suggestionTableController.searchText = searchText
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        VCController.pulleyVC.setDrawerPosition(position: .open, animated: true)
        buttonsView.isHidden = true
        searchBar.setShowsCancelButton(true, animated: true)
        tableView.isHidden = false
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if searchBar.text == "" {
            buttonsView.isHidden = false
            tableView.isHidden = true
        }
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

class SuggestionTableController: NSObject {
    class NewFoodPlaceholder: SuggestionType {
        var name: String
        var addAction: () -> () {
            return { [weak self] in
                let foodEntry = FoodEntry()
                foodEntry.food = Food()
                foodEntry.food!.name = self!.name
                VCController.addFoodEntry(foodEntry, isNew: true)
            }
        }
        var canBeAddedToLog: Bool {
            return true
        }
        var canBeDeleted: Bool {
            return false
        }
        var labelText: String {
            return "\"\(name)\""
        }
        
        init(name: String) {
            self.name = name
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var searchText = "" {
        didSet {
            update()
        }
    }
    private var suggestions = [SuggestionType]()
    private let sortedFoodEntries = DataStore.objects(FoodEntry.self, sortedBy: #keyPath(FoodEntry.date))!
    
    func update() {
        if searchText == "" {
            var foods = Set<Food>()
            for foodEntry in sortedFoodEntries {
                if foods.count >= 5 {
                    break
                }
                guard let food = foodEntry.food else { continue }
                foods.insert(food)
            }
            suggestions = Array(foods)
        } else {
            guard let tags = DataStore.objects(Tag.self)?.filter("name BEGINSWITH %@", searchText),
                let foods = DataStore.objects(Food.self)?.filter("name BEGINSWITH %@", searchText),
                let groups = DataStore.objects(FoodGroupingTemplate.self)?.filter("name BEGINSWITH %@", searchText)
                else { return }
            var results: [SuggestionType] = [NewFoodPlaceholder(name: searchText)]
            for tag in tags {
                if results.count >= 5 { break }
                results.append(tag)
            }
            for food in foods {
                if results.count >= 15 { break }
                results.append(food)
            }
            for group in groups {
                if results.count >= 20 { break }
                results.append(group)
            }
            suggestions = results
        }
        tableView.reloadData()
    }
}

extension SuggestionTableController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return suggestions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Suggestion", for: indexPath)
            as! SuggestionTableViewCell
        cell.suggestion = suggestions[indexPath.item]
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return suggestions[indexPath.row].canBeDeleted
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle,
                   forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        DataStore.delete(suggestions[indexPath.row] as! Object, withoutNotifying: [])
        suggestions.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
}

class SuggestionTableViewCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var addButton: UIButton!
    
    var suggestion: SuggestionType! {
        didSet {
            label.text = suggestion.labelText
            addButton.isHidden = !suggestion.canBeAddedToLog
        }
    }
    
    @IBAction func add() {
        suggestion.addAction()
    }
}
