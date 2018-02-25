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
// TODO: Update suggestions after adding food entry
class AddOrSearchViewController: PulleyDrawerViewController {
    @IBOutlet weak var suggestionTableController: SuggestionTableController!
    @IBOutlet weak var suggestionTableViewVisibilityController: SuggestionTableViewVisibilityController!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
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
        suggestionTableViewVisibilityController.filterStateChanged(false)
        VCController.clearLogFilter()
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

protocol SuggestionType {
    var addAction: () -> () { get }
    var canBeAddedToLog: Bool { get }
    var canBeDeleted: Bool { get }
    var labelText: String { get }
    var searchObject: SearchSuggestion! { get }
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
        var searchObject: SearchSuggestion! {
            return nil
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
    
    func update() {
        if searchText == "" {
            suggestions = DataStore.searchSuggestions
                .sorted(byKeyPath: #keyPath(SearchSuggestion.lastUsed), ascending: false)
                .compactMap { $0.value }
        } else {
            suggestions = [NewFoodPlaceholder(name: searchText)] +
                DataStore.searchSuggestions.filter("text CONTAINS[cd] %@", searchText)
                    .sorted(byKeyPath: #keyPath(SearchSuggestion.lastUsed), ascending: false)
                    .compactMap { $0.value }
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
        let suggestion = suggestions[indexPath.row]
        DataStore.delete(suggestion.searchObject, withoutNotifying: [])
        DataStore.delete(suggestion as! Object, withoutNotifying: [])
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

extension Food: SuggestionType {
    var addAction: () -> () {
        return { [weak self] in
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
    var searchObject: SearchSuggestion! {
        return searchSuggestion
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
    var searchObject: SearchSuggestion! {
        return searchSuggestion
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
    var searchObject: SearchSuggestion! {
        return searchSuggestion
    }
}

extension SearchSuggestion {
    var value: SuggestionType? {
        switch SearchSuggestion.Kind(rawValue: kind)! {
        case .food:     return foods.first
        case .group:    return groups.first
        case .tag:      return tags.first
        }
    }
}
