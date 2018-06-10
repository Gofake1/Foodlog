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
final class AddOrSearchViewController: PulleyDrawerViewController {
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
    
    @objc private func keyboardWasShown(_ aNotification: NSNotification) {
        guard let userInfo = aNotification.userInfo,
            let keyboardFrame = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect
            else { return }
        let insets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardFrame.height+20.0, right: 0.0)
        tableView.contentInset = insets
        tableView.scrollIndicatorInsets = insets
    }
    
    @objc private func keyboardWillBeHidden(_ aNotification: NSNotification) {
        let insets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 20.0, right: 0.0)
        tableView.contentInset = insets
        tableView.scrollIndicatorInsets = insets
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

final class SuggestionTableController: NSObject {
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
            let suggestionResults = suggestions.map { $0.suggestion }
            tableData = [AnyRandomAccessCollection(suggestionResults)]
            suggestionsChangeToken = observe(suggestions, section: 0) { [weak self] in self!.tableData[0] = $0 }
        } else {
            let newSuggestion = [NewFoodPlaceholder(name: searchText)]
            let suggestions = DataStore.searchSuggestions
                .filter("text CONTAINS[cd] %@", searchText)
                .sorted(byKeyPath: #keyPath(SearchSuggestion.lastUsed), ascending: false)
            let suggestionResults = suggestions.map { $0.suggestion }
            tableData = [AnyRandomAccessCollection(newSuggestion), AnyRandomAccessCollection(suggestionResults)]
            suggestionsChangeToken = observe(suggestions, section: 1) { [weak self] in self!.tableData[1] = $0 }
        }
        tableView.reloadData()
    }
    
    private func observe(_ results: Results<SearchSuggestion>, section: Int,
        updateTableData: @escaping (AnyRandomAccessCollection<SuggestionType>) -> ()) -> NotificationToken
    {
        return results.observe { [tableView] in
            switch $0 {
            case .initial:
                break
            case .update(_, let deletes, let inserts, let reloads):
                updateTableData(AnyRandomAccessCollection(results.map { $0.suggestion }))
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

extension SuggestionTableController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableData[indexPath.section][AnyIndex(indexPath.row)].dequeueCell(from: tableView, for: indexPath)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return tableData[indexPath.section][AnyIndex(indexPath.row)].canBeDeleted
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle,
                   forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        tableData[indexPath.section][AnyIndex(indexPath.row)].onDelete {
            if let error = $0 {
                UIApplication.shared.alert(error: error)
            }
        }
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
            return tableData[indexPath.section][AnyIndex(indexPath.row)].canBeDeleted ? indexPath : nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableData[indexPath.section][AnyIndex(indexPath.row)].onSearch()
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
            UIView.animate(withDuration: 0.2, animations: { [tableView] in tableView!.alpha = 0.0 }) { [tableView] _ in
                tableView!.isHidden = true
            }
        } else {
            guard tableView.isHidden else { return }
            tableView.alpha = 1.0
            tableView.isHidden = false
        }
    }
}

final class DefaultSuggestionTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var addButton: MyButton!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        subtitleLabel.text = nil
        addButton.removeTarget(nil, action: nil, for: .touchUpInside)
    }
}

final class TagSuggestionTableViewCell: UITableViewCell {
    @IBOutlet weak var padderView: UIView!
    @IBOutlet weak var label: UILabel!
}

private protocol SuggestionType {
    var canBeDeleted: Bool { get }
    var canBeSearched: Bool { get }
    func dequeueCell(from tableView: UITableView, for indexPath: IndexPath) -> UITableViewCell
    func onDelete(completion completionHandler: @escaping (Error?) -> ())
    func onSearch()
}

extension SuggestionTableController {
    fileprivate class NewFoodPlaceholder: SuggestionType {
        var name: String
        var canBeDeleted: Bool {
            return false
        }
        var canBeSearched: Bool {
            return false
        }
        
        func dequeueCell(from tableView: UITableView, for indexPath: IndexPath) -> UITableViewCell {
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
        
        func onDelete(completion completionHandler: @escaping (Error?) -> ()) {
            fatalError()
        }
        
        func onSearch() {
            fatalError()
        }
        
        init(name: String) {
            // TODO: Limit name to 256 chars
            self.name = name
        }
    }
}

extension Food: SuggestionType {
    fileprivate var canBeDeleted: Bool {
        return true
    }
    fileprivate var canBeSearched: Bool {
        return true
    }
    
    fileprivate func dequeueCell(from tableView: UITableView, for indexPath: IndexPath) -> UITableViewCell {
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
    
    fileprivate func onDelete(completion completionHandler: @escaping (Error?) -> ()) {
        func delete(_ foodEntries: [FoodEntry], _ objects: [Object], prune days: Set<Day>) {
            let hkIds = foodEntries.map { $0.id }
            let ckRecordIds = foodEntries.map { $0.ckRecordId } + [ckRecordId]
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
                                    CloudStore.delete(ckRecordIds, completion: completionHandler)
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
            UIApplication.shared.alert(warning: warning, confirm: { delete(foodEntries, objects, prune: days ) })
        } else {
            delete(foodEntries, objects, prune: days)
        }
    }
    
    fileprivate func onSearch() {
        VCController.filterLog(self)
    }
}

extension FoodGroupingTemplate: SuggestionType {
    fileprivate var canBeDeleted: Bool {
        return true
    }
    fileprivate var canBeSearched: Bool {
        return false
    }
    
    fileprivate func dequeueCell(from tableView: UITableView, for indexPath: IndexPath) -> UITableViewCell {
        fatalError("TODO: FoodGroupingTemplate")
    }
    
    fileprivate func onDelete(completion completionHandler: @escaping (Error?) -> ()) {
        let ckIds = [ckRecordId]
        DataStore.delete([self]) {
            if let error = $0 {
                completionHandler(error)
            } else {
                CloudStore.delete(ckIds, completion: completionHandler)
            }
        }
    }
    
    fileprivate func onSearch() {
        fatalError()
    }
}

extension Tag: SuggestionType {
    fileprivate var canBeDeleted: Bool {
        return true
    }
    fileprivate var canBeSearched: Bool {
        return true
    }
    
    fileprivate func dequeueCell(from tableView: UITableView, for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TagSuggestion", for: indexPath)
            as! TagSuggestionTableViewCell
        cell.padderView.backgroundColor = color
        cell.label.text = name
        return cell
    }
    
    fileprivate func onDelete(completion completionHandler: @escaping (Error?) -> ()) {
        let ckIds = [ckRecordId]
        DataStore.delete(objectsToDelete) {
            if let error = $0 {
                completionHandler(error)
            } else {
                CloudStore.delete(ckIds, completion: completionHandler)
            }
        }
    }
    
    fileprivate func onSearch() {
        VCController.filterLog(self)
    }
}

extension SearchSuggestion {
    fileprivate var suggestion: SuggestionType {
        switch kind {
        case .food:     return foods.first!
        case .group:    return groups.first!
        case .tag:      return tags.first!
        }
    }
}

final class MyButton: UIButton {
    private var touchUpInside: () -> () = {}
    
    func onTouchUpInside(_ handler: @escaping () -> ()) {
        touchUpInside = handler
        addTarget(self, action: #selector(didTouchUpOnside), for: .touchUpInside)
    }
    
    @objc private func didTouchUpOnside() {
        touchUpInside()
    }
}
