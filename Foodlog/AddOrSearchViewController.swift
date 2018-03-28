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
        let insets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 20.0, right: 0.0)
        tableView.contentInset = insets
        tableView.scrollIndicatorInsets = insets
        suggestionTableController.update()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(_:)),
                                               name: .UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(_:)),
                                               name: .UIKeyboardWillHide, object: nil)
    }
    
    @objc func keyboardWasShown(_ aNotification: NSNotification) {
        guard let userInfo = aNotification.userInfo,
            let keyboardFrame = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect
            else { return }
        let insets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardFrame.height+20.0, right: 0.0)
        tableView.contentInset = insets
        tableView.scrollIndicatorInsets = insets
    }
    
    @objc func keyboardWillBeHidden(_ aNotification: NSNotification) {
        let insets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 20.0, right: 0.0)
        tableView.contentInset = insets
        tableView.scrollIndicatorInsets = insets
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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

class SuggestionTableController: NSObject {
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
        return tableData[indexPath.section][AnyIndex(indexPath.row)].suggestionCell(from: tableView, for: indexPath)
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

class DefaultSuggestionTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var addButton: MyButton!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        subtitleLabel.text = ""
        addButton.removeTarget(nil, action: nil, for: .touchUpInside)
    }
}

class TagSuggestionTableViewCell: UITableViewCell {
    @IBOutlet weak var padderView: UIView!
    @IBOutlet weak var label: UILabel!
}

protocol SuggestionType {
    var suggestionCanBeDeleted: Bool { get }
    var suggestionCanBeSearched: Bool { get }
    func suggestionCell(from tableView: UITableView, for indexPath: IndexPath) -> UITableViewCell
    func suggestionOnDelete()
    func suggestionOnSearch()
}

extension SuggestionTableController {
    class NewFoodPlaceholder: SuggestionType {
        var name: String
        var suggestionCanBeDeleted: Bool {
            return false
        }
        var suggestionCanBeSearched: Bool {
            return true
        }
        
        func suggestionCell(from tableView: UITableView, for indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DefaultSuggestion", for: indexPath)
                as! DefaultSuggestionTableViewCell
            cell.titleLabel.text = "\""+name+"\""
            cell.addButton.onTouchUpInside { [name] in
                let foodEntry = FoodEntry()
                foodEntry.food = Food()
                foodEntry.food!.name = name
                VCController.addEntryForNewFood(foodEntry)
            }
            return cell
        }
        
        func suggestionOnDelete() {
            assert(false)
        }
        
        func suggestionOnSearch() {
            // TODO: Search foods and entries using text
        }
        
        init(name: String) {
            self.name = name
        }
    }
}

extension Food: SuggestionType {
    var suggestionCanBeDeleted: Bool {
        return true
    }
    var suggestionCanBeSearched: Bool {
        return true
    }
    
    func suggestionCell(from tableView: UITableView, for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DefaultSuggestion", for: indexPath)
            as! DefaultSuggestionTableViewCell
        cell.titleLabel.text = name
        cell.subtitleLabel.attributedText = tags.prefix(5).map({ ($0.name, $0.color) }).attributedString
        cell.addButton.onTouchUpInside {
            let foodEntry = FoodEntry()
            foodEntry.food = self
            VCController.addEntryForExistingFood(foodEntry)
        }
        return cell
    }
    
    func suggestionOnDelete() {
        if let (count, onConfirm) = Food.delete(self) {
            let warning = "Deleting this food item will also delete \(count) entries. This cannot be undone."
            UIApplication.shared.alert(warning: warning, confirm: onConfirm)
        }
    }
    
    func suggestionOnSearch() {
        VCController.filterLog(self)
    }
}

extension FoodGroupingTemplate: SuggestionType {
    var suggestionCanBeDeleted: Bool {
        return true
    }
    var suggestionCanBeSearched: Bool {
        return false
    }
    
    func suggestionCell(from tableView: UITableView, for indexPath: IndexPath) -> UITableViewCell {
        fatalError("TODO: FoodGroupingTemplate")
    }
    
    func suggestionOnDelete() {
        FoodGroupingTemplate.delete(self)
    }
    
    func suggestionOnSearch() {
        assert(false)
    }
}

extension Tag: SuggestionType {
    var suggestionCanBeDeleted: Bool {
        return true
    }
    var suggestionCanBeSearched: Bool {
        return true
    }
    
    func suggestionCell(from tableView: UITableView, for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TagSuggestion", for: indexPath)
            as! TagSuggestionTableViewCell
        cell.padderView.backgroundColor = color
        cell.label.text = name
        return cell
    }
    
    func suggestionOnDelete() {
        Tag.delete(self)
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

class MyButton: UIButton {
    private var touchUpInside: () -> () = {}
    
    func onTouchUpInside(_ handler: @escaping () -> ()) {
        touchUpInside = handler
        addTarget(self, action: #selector(didTouchUpOnside), for: .touchUpInside)
    }
    
    @objc func didTouchUpOnside() {
        touchUpInside()
    }
}
