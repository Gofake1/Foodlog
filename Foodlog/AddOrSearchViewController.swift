//
//  AddOrSearchViewController.swift
//  Foodlog
//
//  Created by David on 12/27/17.
//  Copyright © 2017 Gofake1. All rights reserved.
//

import UIKit

class AddOrSearchViewController: PulleyDrawerViewController {
    @IBOutlet weak var scanBarcodeButton: UIButton!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
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
    
    func suggestionAdded(_ suggestion: SuggestionType) {
        let addFoodVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier:
            "AddOrEditFood") as! AddOrEditFoodViewController
        if let food = suggestion as? Food {
            addFoodVC.food = food
        }
        push(addFoodVC)
    }
}

class SuggestionTableViewCell: UITableViewCell {
    @IBOutlet weak var addOrSearchViewController: AddOrSearchViewController!
    @IBOutlet weak var label: UILabel!
    
    var suggestion: SuggestionType? {
        didSet {
            label.text = suggestion?.suggestionName
        }
    }
    var newSuggestionName = "" {
        didSet {
            label.text = "\"\(newSuggestionName)\""
        }
    }
    
    @IBAction func add() {
        if let suggestion = suggestion {
            addOrSearchViewController.suggestionAdded(suggestion)
        } else {
            let newFood = Food()
            newFood.name = newSuggestionName
            addOrSearchViewController.suggestionAdded(newFood)
        }
    }
}

protocol SuggestionType {
    var suggestionName: String { get }
}

extension Food: SuggestionType {
    var suggestionName: String {
        return name
    }
}

extension AddOrSearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        tableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        pulleyVC.setDrawerPosition(position: .open, animated: true)
        scanBarcodeButton.isHidden = true
        searchBar.setShowsCancelButton(true, animated: true)
        tableView.isHidden = false
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if searchBar.text == "" {
            scanBarcodeButton.isHidden = false
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

extension AddOrSearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let searchText = searchBar.text else { return 0 }
        return searchText == "" ? 0 : 1 + 1 //*
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Suggestion", for: indexPath)
            as! SuggestionTableViewCell
        if indexPath.item == 0 {
            cell.newSuggestionName = searchBar.text!
        } else {
            //*
        }
        return cell
    }
}
