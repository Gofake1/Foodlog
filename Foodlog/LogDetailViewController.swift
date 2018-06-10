//
//  LogDetailViewController.swift
//  Foodlog
//
//  Created by David on 1/6/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import UIKit

final class LogDetailViewController: PulleyDrawerViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var tagsView: FlowContainerView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    
    var detailPresentable: LogDetailPresentable!
    private lazy var detailTextAttributes: [NSAttributedStringKey: Any] = {
        var attributes = textView.attributedText.attributes(at: 0, effectiveRange: nil)
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        let location = textView.bounds.width - textView.textContainer.lineFragmentPadding * 2
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .right, location: location)]
        attributes[.paragraphStyle] = paragraphStyle
        return attributes
    }()
    private var valueRepresentation = NutritionKind.ValueRepresentation.real
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        titleLabel.text = detailPresentable.logDetailTitle
        subtitleLabel.text = detailPresentable.logDetailSubtitle
        tagsView.subviews.forEach { $0.removeFromSuperview() }
        detailPresentable.fillTagView(tagsView)
        resetLogDetailText()
        
        textViewHeight.constant = textView.sizeThatFits(CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude)).height
    }
    
    @IBAction func edit() {
        detailPresentable.editDetailPresentable()
    }
    
    @IBAction func cancel() {
        VCController.clearLogSelection()
        VCController.pop()
    }
    
    @IBAction func toggleValueRepresentation(_ sender: UITapGestureRecognizer) {
        switch valueRepresentation {
        case .percentage:   valueRepresentation = .real
        case .real:         valueRepresentation = .percentage
        }
        resetLogDetailText()
    }
    
    private func resetLogDetailText() {
        let textViewString = detailPresentable.makeDetailText(valueRepresentation)
        textView.attributedText = NSAttributedString(string: textViewString, attributes: detailTextAttributes)
    }
}

protocol LogDetailPresentable {
    var logDetailTitle: String { get }
    var logDetailSubtitle: String { get }
    func editDetailPresentable()
    func fillTagView(_ view: FlowContainerView)
    func makeDetailText(_ representation: NutritionKind.ValueRepresentation) -> String
}

extension Food: LogDetailPresentable {
    var logDetailTitle: String {
        return name
    }
    var logDetailSubtitle: String {
        return String(entries.count)+" entries"
    }
    
    func editDetailPresentable() {
        VCController.editFood(self)
    }
    
    func fillTagView(_ view: FlowContainerView) {
        tags.map({ $0.disabledButton }).forEach({ view.addSubview($0) })
    }
    
    func makeDetailText(_ representation: NutritionKind.ValueRepresentation) -> String {
        let servingText: String
        if servingSizeUnit != .none, servingSize > 0.0, let pretty = servingSize.pretty {
            servingText = "Per Serving (\(pretty+servingSizeUnit.suffix)):\n"
        } else {
            servingText = "Per Serving:\n"
        }
        return servingText + makeNutritionText(representation, { $0 })
    }
}

extension FoodEntry: LogDetailPresentable {
    var logDetailTitle: String {
        guard let food = food, let measurementString = measurementString else { return "Error: No Information" }
        return "\(measurementString)\(measurementUnit.detailSuffix) \(food.name)"
    }
    var logDetailSubtitle: String {
        return date.mediumDateShortTimeString
    }
    
    func editDetailPresentable() {
        VCController.editFoodEntry(self)
    }
    
    func fillTagView(_ view: FlowContainerView) {
        tags.map({ $0.disabledButton }).forEach({ view.addSubview($0) })
    }
    
    func makeDetailText(_ representation: NutritionKind.ValueRepresentation) -> String {
        guard let food = food else { return "Error: No Information" }
        do {
            let factor = try conversionFactor()
            return food.makeNutritionText(representation, { $0 * factor })
        } catch ConversionError.illegal {
            return "Error: Could not convert from \(measurementUnit) to \(food.servingSizeUnit)"
        } catch ConversionError.zeroServingSize {
            return "Error: Serving size can not be 0 \(food.servingSizeUnit)"
        } catch {
            fatalError()
        }
    }
}

extension Food {
    /// - parameters:
    ///   - transform: Block to convert nutrition's value per serving
    fileprivate func makeNutritionText(_ representation: NutritionKind.ValueRepresentation,
                                       _ transform: @escaping (Float) -> Float) -> String
    {
        let makeLine: (NutritionKind) -> String?
        switch representation {
        case .percentage:
            makeLine = {
                let real = self[keyPath: $0.keyPath]
                guard real != 0.0 else { return nil }
                if let percentage = real.dailyValuePercentageFromReal($0) {
                    return $0.title+"\t"+transform(percentage).pretty!+"%"
                } else {
                    return $0.title+"\t"+transform(real).pretty!+$0.unit.suffix
                }
            }
        case .real:
            makeLine = {
                let real = self[keyPath: $0.keyPath]
                guard real != 0.0 else { return nil }
                return $0.title+"\t"+transform(real).pretty!+$0.unit.suffix
            }
        }
        let str = [NutritionKind.calories, .totalFat, .saturatedFat, .monounsaturatedFat, .polyunsaturatedFat,
                   .transFat, .cholesterol, .sodium, .totalCarbohydrate, .dietaryFiber, .sugars, .protein, .biotin,
                   .caffeine, .calcium, .chloride, .chromium, .copper, .folate, .iodine, .iron, .magnesium,
                   .manganese, .molybdenum, .niacin, .pantothenicAcid, .phosphorus, .potassium, .riboflavin,
                   .selenium, .thiamin, .vitaminA, .vitaminB6, .vitaminB12, .vitaminC, .vitaminD, .vitaminE,
                   .vitaminK, .zinc]
            .compactMap(makeLine).joined(separator: "\n")
        return str == "" ? "No Information" : str
    }
}

extension Food.Unit {
    fileprivate var detailSuffix: String {
        switch self {
        case .none:         return "×"
        case .gram:         return " g"
        case .milligram:    return " mg"
        case .ounce:        return " oz"
        case .milliliter:   return " mL"
        case .fluidOunce:   return " oz"
        }
    }
}
