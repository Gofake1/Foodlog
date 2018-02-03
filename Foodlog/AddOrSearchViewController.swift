//
//  AddOrSearchViewController.swift
//  Foodlog
//
//  Created by David on 12/27/17.
//  Copyright © 2017 Gofake1. All rights reserved.
//

import RealmSwift
import UIKit

// TODO: iPhone X UI
class AddOrSearchViewController: PulleyDrawerViewController {
    @IBOutlet weak var suggestionTableController: SuggestionTableController!
    @IBOutlet weak var suggestionTableViewVisibilityController: SuggestionTableViewVisibilityController!
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
        searchBar.setShowsCancelButton(true, animated: true)
        suggestionTableViewVisibilityController.searchBarStateChanged(true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        suggestionTableViewVisibilityController.searchBarStateChanged(false)
        suggestionTableViewVisibilityController.searchTextChanged(searchBar.text)
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
    @IBOutlet weak var tableViewVisibilityController: SuggestionTableViewVisibilityController!
    
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

extension SuggestionTableController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if tableView.cellForRow(at: indexPath)!.isSelected {
            tableView.deselectRow(at: indexPath, animated: true)
            tableViewVisibilityController.filterStateChanged(false)
            VCController.clearLogFilter()
            return nil
        } else {
            return indexPath
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let food = suggestions[indexPath.row] as? Food else { return } //*
        tableViewVisibilityController.filterStateChanged(true)
        VCController.filterLog(food)
    }
}

class SuggestionTableViewVisibilityController: NSObject {
    @IBOutlet weak var tableView: UITableView!
    
    private var searchBarIsActive = false
    private var searchText: String?
    private var filterIsActive = false
    
    func searchBarStateChanged(_ isActive: Bool) {
        searchBarIsActive = isActive
        update()
    }
    
    func searchTextChanged(_ text: String?) {
        searchText = text
        update()
    }
    
    func filterStateChanged(_ isActive: Bool) {
        filterIsActive = isActive
        update()
    }
    
    private func update() {
        if !searchBarIsActive && searchText == "" && !filterIsActive {
            guard !tableView.isHidden else { return }
            UIView.animate(withDuration: 0.2, animations: { [weak self] in
                self?.tableView.alpha = 0.0
            }) { [weak self] _ in
                self?.tableView.isHidden = true
            }
        } else {
            guard tableView.isHidden else { return }
            tableView.alpha = 1.0
            tableView.isHidden = false
        }
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
