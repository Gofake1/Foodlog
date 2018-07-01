//
//  AddOrEditTagViewController.swift
//  Foodlog
//
//  Created by David on 6/22/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import UIKit

class AddOrEditTagViewController: UIViewController {
    @IBOutlet weak var actionTitleLabel: UILabel!
    @IBOutlet weak var colorsView: FlowContainerView!
    @IBOutlet weak var commitButton: UIButton!
    @IBOutlet weak var nameField: UITextField!
    
    var context: AddOrEditTagContextType!
    private let currentColorSelectionLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.white.cgColor
        let rect = CGRect(origin: .init(x: 7.0, y: 7.0), size: .init(width: 30.0, height: 30.0))
        layer.path = UIBezierPath(ovalIn: rect).cgPath
        return layer
    }()
    
    override func viewDidLoad() {
        actionTitleLabel.text = context.actionTitle
        commitButton.setTitle(context.commitTitle, for: .normal)
        nameField.text = context.name
        
        let colorViews: [UIView] = [Tag.ColorCode.gray, .red, .orange, .yellow, .green, .blue, .purple].map {
            [weak self] in
            let view = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 44.0, height: 44.0))
            view.backgroundColor = $0.color
            view.layer.cornerRadius = 22.0
            view.tag = $0.rawValue
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(colorWasTapped(_:)))
            view.addGestureRecognizer(tapRecognizer)
            return view
        }
        colorViews[context.colorCode.rawValue].layer.addSublayer(currentColorSelectionLayer)
        colorViews.forEach({ [colorsView] in colorsView!.addSubview($0) })
    }
    
    @IBAction func changedNameText(_ sender: UITextField) {
        context.name = sender.text!
    }
    
    @IBAction func commit() {
        context.commit(dismiss: self) { [weak self] in
            if let error = $0 {
                self!.alert(error: error)
            }
        }
    }
    
    @IBAction func dismiss() {
        context.cancel(dismiss: self)
    }
    
    @objc private func colorWasTapped(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view, let colorCode = Tag.ColorCode(rawValue: view.tag) else { return }
        currentColorSelectionLayer.removeFromSuperlayer()
        context.colorCode = colorCode
        view.layer.addSublayer(currentColorSelectionLayer)
    }
}

protocol AddOrEditTagContextType {
    var actionTitle: String { get }
    var colorCode: Tag.ColorCode { get set }
    var commitTitle: String { get }
    var name: String { get set }
    
    func cancel(dismiss vc: AddOrEditTagViewController)
    func commit(dismiss vc: AddOrEditTagViewController, completion completionHandler: @escaping (Error?) -> ())
}

final class AddTagContext: AddOrEditTagContextType {
    var actionTitle: String {
        return "Add New Tag"
    }
    var colorCode: Tag.ColorCode {
        get { return tag.colorCode }
        set { tag.colorCode = newValue }
    }
    var commitTitle: String {
        return "Add"
    }
    var name = ""
    private let tag = Tag()
    
    func cancel(dismiss vc: AddOrEditTagViewController) {
        VCController.dismissAddTag(vc, newTag: nil)
    }
    
    func commit(dismiss vc: AddOrEditTagViewController, completion completionHandler: @escaping (Error?) -> ()) {
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if name == "" {
            completionHandler(TagError.illegalName)
        } else if DataStore.tags.filter("name == %@", name).count == 0 {
            tag.name = name
            tag.localCKRecord = CloudKitRecord()
            tag.localCKRecord!.kind = .tag
            tag.localCKRecord!.recordName = tag.id
            tag.searchSuggestion = SearchSuggestion()
            tag.searchSuggestion!.id = tag.id
            tag.searchSuggestion!.kind = .tag
            tag.searchSuggestion!.lastUsed = Date()
            tag.searchSuggestion!.text = name
            let ckRecords = [tag.ckRecord(from: Tag.changedAll)]
            DataStore.update([tag]) {
                if let error = $0 {
                    completionHandler(error)
                } else {
                    CloudStore.save(ckRecords, completion: completionHandler)
                }
            }
            VCController.dismissAddTag(vc, newTag: tag)
        } else {
            completionHandler(TagError.alreadyExists)
        }
    }
}

final class EditTagContext: AddOrEditTagContextType {
    var actionTitle: String {
        return "Edit Tag"
    }
    var colorCode: Tag.ColorCode {
        get { return tag.colorCode }
        set {
            changes.insert(change: \Tag.colorCodeRaw)
            tag.colorCode = newValue
        }
    }
    var commitTitle: String {
        return "Save"
    }
    var name: String {
        get { return tag.name }
        set {
            guard newValue != oldName else { return }
            changes.insert(change: \Tag.name)
            tag.name = newValue
            tag.searchSuggestion!.text = newValue
        }
    }
    private let changes = Changes<Tag>()
    private let oldName: String
    private let tag: Tag
    
    init(_ tag: Tag) {
        oldName = tag.name
        self.tag = Tag(value: tag)
        self.tag.searchSuggestion! = SearchSuggestion(value: tag.searchSuggestion!)
    }
    
    func cancel(dismiss vc: AddOrEditTagViewController) {
        VCController.dismissEditTag(vc)
    }
    
    func commit(dismiss vc: AddOrEditTagViewController, completion completionHandler: @escaping (Error?) -> ()) {
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if name == "" {
            completionHandler(TagError.illegalName)
        } else if name == oldName || DataStore.tags.filter("name == %@", name).count == 0 {
            let ckRecords = [tag.ckRecord(from: changes)]
            DataStore.update([tag]) {
                if let error = $0 {
                    completionHandler(error)
                } else {
                    CloudStore.save(ckRecords, completion: completionHandler)
                }
            }
            VCController.dismissEditTag(vc)
        } else {
            completionHandler(TagError.alreadyExists)
        }
    }
}

extension Tag {
    fileprivate static var changedAll: Changes<Tag> {
        let keyPaths = Set(arrayLiteral: \Tag.colorCodeRaw,
                           \Tag.lastUsed,
                           \Tag.name)
        return Changes(keyPaths)
    }
}
