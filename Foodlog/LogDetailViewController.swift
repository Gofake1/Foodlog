//
//  LogDetailViewController.swift
//  Foodlog
//
//  Created by David on 1/6/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import UIKit

class LogDetailViewController: PulleyDrawerViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    
    var detailPresentable: LogDetailPresentable!
    private var detailTextAttributes: [NSAttributedStringKey: Any]!
    private var valueRepresentation = NutritionKind.ValueRepresentation.real
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        titleLabel.text = detailPresentable.logDetailTitle
        subtitleLabel.text = detailPresentable.logDetailSubtitle
        
        detailTextAttributes = textView.attributedText.attributes(at: 0, effectiveRange: nil)
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        let location = textView.bounds.width - textView.textContainer.lineFragmentPadding * 2
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .right, location: location)]
        detailTextAttributes[.paragraphStyle] = paragraphStyle
        
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
    func makeDetailText(_ representation: NutritionKind.ValueRepresentation) -> String
}

struct NutritionPrinter {
    var print: String {
        var str = ""
        str += makeLine(.calories, food.calories)
        str += makeLine(.totalFat, food.totalFat)
        str += makeLine(.saturatedFat, food.saturatedFat)
        str += makeLine(.monounsaturatedFat, food.monounsaturatedFat)
        str += makeLine(.polyunsaturatedFat, food.polyunsaturatedFat)
        str += makeLine(.transFat, food.transFat)
        str += makeLine(.cholesterol, food.cholesterol)
        str += makeLine(.sodium, food.sodium)
        str += makeLine(.totalCarbohydrate, food.totalCarbohydrate)
        str += makeLine(.dietaryFiber, food.dietaryFiber)
        str += makeLine(.sugars, food.sugars)
        str += makeLine(.protein, food.protein)
        str += makeLine(.vitaminA, food.vitaminA)
        str += makeLine(.vitaminB6, food.vitaminB6)
        str += makeLine(.vitaminB12, food.vitaminB12)
        str += makeLine(.vitaminC, food.vitaminC)
        str += makeLine(.vitaminD, food.vitaminD)
        str += makeLine(.vitaminE, food.vitaminE)
        str += makeLine(.vitaminK, food.vitaminK)
        str += makeLine(.calcium, food.calcium)
        str += makeLine(.iron, food.iron)
        str += makeLine(.magnesium, food.magnesium)
        str += makeLine(.potassium, food.potassium)
        if str == "" {
            str = "No Information\n"
        }
        return str
    }
    private let food: Food
    private let makeLine: (NutritionKind, Float) -> String
    
    init(_ food: Food, _ representation: NutritionKind.ValueRepresentation, _ transform: @escaping (Float) -> Float) {
        self.food = food
        switch representation {
        case .percentage:
            makeLine = { kind, real in
                guard real != 0.0 else { return "" }
                if let percentage = real.dailyValuePercentageFromReal(kind) {
                    return kind.description+"\t"+transform(percentage).pretty!+"%\n"
                } else {
                    return kind.description+"\t"+transform(real).pretty!+kind.unit.suffix+"\n"
                }
            }
        case .real:
            makeLine = { kind, real in
                guard real != 0.0 else { return "" }
                return kind.description+"\t"+transform(real).pretty!+kind.unit.suffix+"\n"
            }
        }
    }
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
    
    func makeDetailText(_ representation: NutritionKind.ValueRepresentation) -> String {
        return "Per \(measurementRepresentation.singular):\n" + NutritionPrinter(self, representation, { $0 }).print
    }
}

extension FoodEntry: LogDetailPresentable {
    var logDetailTitle: String {
        guard let food = food, let measurementString = measurementString else { return "Error: Log Detail Title" }
        return "\(measurementString)\(food.measurementRepresentation.longSuffix) \(food.name)"
    }
    var logDetailSubtitle: String {
        return date.mediumDateShortTimeString
    }
    
    func editDetailPresentable() {
        VCController.editFoodEntry(self)
    }
    
    func makeDetailText(_ representation: NutritionKind.ValueRepresentation) -> String {
        return NutritionPrinter(food!, representation, { [measurementFloat] in $0 * measurementFloat }).print
    }
}

extension Food.MeasurementRepresentation {
    var longSuffix: String {
        switch self {
        case .serving:      return "×"
        case .milligram:    return " mg"
        case .gram:         return " g"
        case .ounce:        return " oz"
        case .pound:        return " lb"
        case .fluidOunce:   return " oz"
        }
    }
}
