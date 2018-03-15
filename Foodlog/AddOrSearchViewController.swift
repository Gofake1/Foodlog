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
    var suggestionCanBeAddedToLog: Bool { get }
    var suggestionCanBeDeleted: Bool { get }
    var suggestionCanBeSearched: Bool { get }
    var suggestionLabelText: String { get }
    func suggestionOnAdd()
    func suggestionOnDelete()
    func suggestionOnSearch()
}

class SuggestionTableController: NSObject {
    class NewFoodPlaceholder: SuggestionType {
        var name: String
        var suggestionCanBeAddedToLog: Bool {
            return true
        }
        var suggestionCanBeDeleted: Bool {
            return false
        }
        var suggestionCanBeSearched: Bool {
            return true
        }
        var suggestionLabelText: String {
            return "\"\(name)\""
        }
        
        func suggestionOnAdd() {
            let foodEntry = FoodEntry()
            foodEntry.food = Food()
            foodEntry.food!.name = name
            VCController.addFoodEntry(foodEntry, isNew: true)
        }
        
        func suggestionOnDelete() {
            assert(false)
        }
        
        func suggestionOnSearch() {
            // TODO
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
    private var tableData = [AnyRandomAccessCollection<SuggestionType>]()
    private var suggestionsChangeToken: NotificationToken!
    
    func update() {
        suggestionsChangeToken?.invalidate()
        if searchText == "" {
            let suggestions = DataStore.searchSuggestions
                .sorted(byKeyPath: #keyPath(SearchSuggestion.lastUsed), ascending: false)
            suggestionsChangeToken = suggestions.observe { [weak self] in
                switch $0 {
                case .initial:
                    break
                case .update(_, let deletes, let inserts, let mods):
                    let suggestionResults = suggestions.map { $0.value }
                    self!.tableData = [AnyRandomAccessCollection(suggestionResults)]
                    self!.tableView.performBatchUpdates({
                        self!.tableView.deleteRows(at: deletes.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                        self!.tableView.insertRows(at: inserts.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                        self!.tableView.reloadRows(at: mods.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                    })
                case .error(let error):
                    UIApplication.shared.alert(error: error)
                }
            }
            let suggestionResults = suggestions.map { $0.value }
            tableData = [AnyRandomAccessCollection(suggestionResults)]
        } else {
            let newSuggestion = [NewFoodPlaceholder(name: searchText)]
            let suggestions = DataStore.searchSuggestions
                .filter("text CONTAINS[cd] %@", searchText)
                .sorted(byKeyPath: #keyPath(SearchSuggestion.lastUsed), ascending: false)
            suggestionsChangeToken = suggestions.observe { [weak self] in
                switch $0 {
                case .initial:
                    break
                case .update(_, let deletes, let inserts, let mods):
                    let suggestionResults = suggestions.map { $0.value }
                    self!.tableData[1] = AnyRandomAccessCollection(suggestionResults)
                    self!.tableView.performBatchUpdates({
                        self!.tableView.deleteRows(at: deletes.map { IndexPath(row: $0, section: 1) }, with: .automatic)
                        self!.tableView.insertRows(at: inserts.map { IndexPath(row: $0, section: 1) }, with: .automatic)
                        self!.tableView.reloadRows(at: mods.map { IndexPath(row: $0, section: 1) }, with: .automatic)
                    })
                case .error(let error):
                    UIApplication.shared.alert(error: error)
                }
            }
            let suggestionResults = suggestions.map { $0.value }
            tableData = [AnyRandomAccessCollection(newSuggestion), AnyRandomAccessCollection(suggestionResults)]
        }
        tableView.reloadData()
    }
}

extension SuggestionTableController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Suggestion", for: indexPath)
            as! SuggestionTableViewCell
        cell.suggestion = tableData[indexPath.section][AnyIndex(indexPath.row)]
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return tableData[indexPath.section][AnyIndex(indexPath.row)].suggestionCanBeDeleted
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle,
                   forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        tableData[indexPath.section][AnyIndex(indexPath.row)].suggestionOnDelete()
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
            return tableData[indexPath.section][AnyIndex(indexPath.row)].suggestionCanBeDeleted ? indexPath : nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableData[indexPath.section][AnyIndex(indexPath.row)].suggestionOnSearch()
        tableViewVisibilityController.filterStateChanged(true)
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
            label.text = suggestion.suggestionLabelText
            addButton.isHidden = !suggestion.suggestionCanBeAddedToLog
        }
    }
    
    @IBAction func add() {
        suggestion.suggestionOnAdd()
    }
}

extension Food: SuggestionType {
    var suggestionCanBeAddedToLog: Bool {
        return true
    }
    var suggestionCanBeDeleted: Bool {
        return true
    }
    var suggestionCanBeSearched: Bool {
        return true
    }
    var suggestionLabelText: String {
        return name
    }
    
    func suggestionOnAdd() {
        let foodEntry = FoodEntry()
        foodEntry.food = self
        VCController.addFoodEntry(foodEntry, isNew: false)
    }
    
    // TODO: Refactor into common function
    func suggestionOnDelete() {
        func warningString(_ count: Int) -> String {
            return "Deleting this food item will also delete \(count) entries. This cannot be undone."
        }
        
        if entries.count > 0 {
            UIApplication.shared.alert(warning: warningString(entries.count)) {
                self.entries.forEach { DataStore.delete($0) }
                DataStore.delete(self.searchSuggestion!)
                DataStore.delete(self)
            }
        } else {
            entries.forEach { DataStore.delete($0) }
            DataStore.delete(searchSuggestion!)
            DataStore.delete(self)
        }
    }
    
    func suggestionOnSearch() {
        VCController.filterLog(self)
    }
}

extension FoodGroupingTemplate: SuggestionType {
    var suggestionCanBeAddedToLog: Bool {
        return true
    }
    var suggestionCanBeDeleted: Bool {
        return true
    }
    var suggestionCanBeSearched: Bool {
        return false
    }
    var suggestionLabelText: String {
        return name
    }
    
    func suggestionOnAdd() {
        // TODO
    }
    
    func suggestionOnDelete() {
        DataStore.delete(searchSuggestion!)
        DataStore.delete(self)
    }
    
    func suggestionOnSearch() {
        assert(false)
    }
}

extension Tag: SuggestionType {
    var suggestionCanBeAddedToLog: Bool {
        return false
    }
    var suggestionCanBeDeleted: Bool {
        return true
    }
    var suggestionCanBeSearched: Bool {
        return true
    }
    var suggestionLabelText: String {
        return name
    }
    
    func suggestionOnAdd() {
        assert(false)
    }
    
    func suggestionOnDelete() {
        DataStore.delete(searchSuggestion!)
        DataStore.delete(self)
    }
    
    func suggestionOnSearch() {
        VCController.filterLog(self)
    }
}

extension SearchSuggestion {
    var value: SuggestionType {
        switch SearchSuggestion.Kind(rawValue: kindRaw)! {
        case .food:     return foods.first!
        case .group:    return groups.first!
        case .tag:      return tags.first!
        }
    }
}
