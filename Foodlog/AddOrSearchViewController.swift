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
}

@objc protocol SuggestionTableViewCellDelegate {
    func suggestionAdded(_ name: String)
}

class SuggestionTableViewCell: UITableViewCell {
    @IBOutlet weak var delegate: SuggestionTableViewCellDelegate!
    @IBOutlet weak var label: UILabel!
    
    var isInQuotations = false
    var suggestionName = "" {
        didSet {
            label.text = isInQuotations ? "\"\(suggestionName)\"" : suggestionName
        }
    }
    
    @IBAction func add() {
        delegate.suggestionAdded(suggestionName)
    }
}

extension AddOrSearchViewController: SuggestionTableViewCellDelegate {
    func suggestionAdded(_ name: String) {
        let addFoodVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier:
            "AddFoodViewController") as! AddFoodViewController
        addFoodVC.foodName = name
        push(addFoodVC)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "SuggestionCell", for: indexPath)
            as! SuggestionTableViewCell
        if indexPath.item == 0 {
            cell.isInQuotations = true
            cell.suggestionName = searchBar.text!
        } else {
            //*
        }
        return cell
    }
}
