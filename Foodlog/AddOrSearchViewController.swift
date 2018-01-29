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
    var canBeAddedToLog: Bool { get }
    var isPlaceholder: Bool { get }
    var suggestionName: String { get }
}

extension Food: SuggestionType {
    var canBeAddedToLog: Bool {
        return true
    }
    var isPlaceholder: Bool {
        return false
    }
    var suggestionName: String {
        return name
    }
}

// TODO: iPhone X UI
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
    
    func suggestionAdded(_ suggestion: SuggestionType, isNew: Bool) {
        guard let food = suggestion as? Food else { return }
        let foodEntry = FoodEntry()
        foodEntry.food = food
        VCController.addFoodEntry(foodEntry, isNew: isNew)
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
    struct NewFoodPlaceholder: SuggestionType {
        var name: String
        var canBeAddedToLog: Bool {
            return true
        }
        var isPlaceholder: Bool {
            return true
        }
        var suggestionName: String {
            return name
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var searchText = "" {
        didSet {
            update()
        }
    }
    private var suggestions = [SuggestionType]()
    
    func update() {
        if searchText == "" {
            guard let foodEntries = DataStore.objects(FoodEntry.self) else { return }
            var foods = Set<Food>()
            for foodEntry in foodEntries {
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
                if results.count >= 5 {
                    break
                }
                results.append(tag)
            }
            for food in foods {
                if results.count >= 15 {
                    break
                }
                results.append(food)
            }
            for group in groups {
                if results.count >= 20 {
                    break
                }
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
}

class SuggestionTableViewCell: UITableViewCell {
    @IBOutlet weak var addOrSearchVC: AddOrSearchViewController!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var addButton: UIButton!
    
    var suggestion: SuggestionType! {
        didSet {
            label.text = suggestion.isPlaceholder ? "\"\(suggestion.suggestionName)\"" : suggestion.suggestionName
            addButton.isHidden = !suggestion.canBeAddedToLog
        }
    }
    
    @IBAction func add() {
        if suggestion.isPlaceholder {
            let newFood = Food()
            newFood.name = suggestion.suggestionName
            addOrSearchVC.suggestionAdded(newFood, isNew: true)
        } else {
            addOrSearchVC.suggestionAdded(suggestion, isNew: false)
        }
    }
}
