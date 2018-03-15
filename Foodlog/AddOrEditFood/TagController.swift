//
//  TagController.swift
//  Foodlog
//
//  Created by David on 2/23/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import UIKit

protocol Tagged {
    var tagSet: Set<Tag> { get }
    func toggleTag(_ name: String) -> Bool
}

extension Food: Tagged {
    var tagSet: Set<Tag> {
        return Set(tags)
    }
    
    func toggleTag(_ name: String) -> Bool {
        if let index = tags.index(where: { $0.name == name }) {
            tags.remove(at: index)
            return false
        } else {
            tags.append(DataStore.tags.first(where: { $0.name == name })!)
            return true
        }
    }
}

extension FoodEntry: Tagged {
    var tagSet: Set<Tag> {
        return Set(tags)
    }
    
    func toggleTag(_ name: String) -> Bool {
        if let index = tags.index(where: { $0.name == name }) {
            tags.remove(at: index)
            return false
        } else {
            tags.append(DataStore.tags.first(where: { $0.name == name })!)
            return true
        }
    }
}

// TODO: `FlowContainerView.intrinsicContentSize`
class TagController: NSObject {
    @IBOutlet weak var addOrEditVC: AddOrEditFoodViewController!
    @IBOutlet weak var entryTagsView: FlowContainerView!
    @IBOutlet weak var foodTagsView: FlowContainerView!
    
    private static let shadowDuration = 0.4
    private static let shadowRelativeDuration = shadowDuration / animationDuration
    private static let translationDuration = 0.4
    private static let translationRelativeDuration = translationDuration / animationDuration
    private static let animationDuration = shadowDuration + translationDuration
    private weak var activeTagsView: FlowContainerView!
    private var tagged: Tagged!
    private var fillForView = [FlowContainerView: ([Tag]) -> ()]()
    
    func setup(_ mode: AddOrEditFoodViewController.Mode) {
        func makeFill(for view: UIView, empty: @escaping () -> UIView, make: @escaping (Tag) -> UIView)
            -> ([Tag]) -> ()
        {
            return { [weak view] tags in
                if tags.count == 0 {
                    view!.addSubview(empty())
                } else {
                    for tag in tags {
                        view!.addSubview(make(tag))
                    }
                }
            }
        }
        
        fillForView[entryTagsView] = makeFill(for: entryTagsView, empty: {
            let button = UIButton(pill: "add tags", color: .lightGray)
            button.addTarget(self, action: #selector(TagController.foodEntryTagPressed), for: .touchUpInside)
            return button
        }, make: {
            let button = $0.plainButton
            button.addTarget(self, action: #selector(TagController.foodEntryTagPressed), for: .touchUpInside)
            return button
        })
        
        let empty: () -> UIView, make: (Tag) -> UIView
        switch mode {
        case .addEntryForExistingFood:
            empty = {
                let label = UILabel()
                label.textColor = .lightGray
                label.text = "no tags"
                return label
            }
            make = {
                let button = $0.plainButton
                button.isEnabled = false
                return button
            }
        case .addEntryForNewFood: fallthrough
        case .editEntry:
            empty = {
                let button = UIButton(pill: "add tags", color: .lightGray)
                button.addTarget(self, action: #selector(TagController.foodTagPressed), for: .touchUpInside)
                return button
            }
            make = {
                let button = $0.plainButton
                button.addTarget(self, action: #selector(TagController.foodTagPressed), for: .touchUpInside)
                return button
            }
        }
        fillForView[foodTagsView] = makeFill(for: foodTagsView, empty: empty, make: make)
        
        fillForView[entryTagsView]!(Array(addOrEditVC.foodEntry.tags))
        fillForView[foodTagsView]!(Array(addOrEditVC.foodEntry.food!.tags))
    }
    
    @objc func foodEntryTagPressed() {
        tagged = addOrEditVC.foodEntry
        showModal(tagView: entryTagsView)
    }
    
    @objc func foodTagPressed() {
        tagged = addOrEditVC.foodEntry.food!
        showModal(tagView: foodTagsView)
    }
    
    private func showModal(tagView: FlowContainerView) {
        activeTagsView = tagView
        let tagVC: TagViewController = VCController.makeVC(.tag)
        tagVC.delegate = self
        tagVC.modalPresentationStyle = .overCurrentContext
        tagVC.transitioningDelegate = self
        addOrEditVC.present(tagVC, animated: true, completion: nil)
    }
}

extension TagController: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return TagController.animationDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        func makeAnimatedView() -> UIView {
            let view = UIView()
            view.backgroundColor = .white
            view.layer.cornerRadius = 16.0
            view.layer.masksToBounds = false
            view.layer.shadowOffset = CGSize(width: 0.0, height: 4.0)
            view.layer.shadowOpacity = 0.2
            view.layer.shadowRadius = 16.0
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }
        
        func makeConstraints(view: UIView, left: CGFloat, right: CGFloat, height: CGFloat, centerY: CGFloat) ->
            (left: NSLayoutConstraint, right: NSLayoutConstraint, height: NSLayoutConstraint,
            centerY: NSLayoutConstraint)
        {
            return (NSLayoutConstraint(item: view, attribute: .left, relatedBy: .equal,
                                       toItem: transitionContext.containerView, attribute: .left,
                                       multiplier: 1.0, constant: left),
                    NSLayoutConstraint(item: view, attribute: .right, relatedBy: .equal,
                                       toItem: transitionContext.containerView, attribute: .right,
                                       multiplier: 1.0, constant: right),
                    NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal,
                                       toItem: nil, attribute: .notAnAttribute,
                                       multiplier: 1.0, constant: height),
                    NSLayoutConstraint(item: view, attribute: .centerY, relatedBy: .equal,
                                       toItem: transitionContext.containerView, attribute: .centerY,
                                       multiplier: 1.0, constant: centerY))
        }
        
        if let toVC = transitionContext.viewController(forKey: .to) as? TagViewController {
            let animatedView = makeAnimatedView()
            animatedView.alpha = 0.0
            transitionContext.containerView.addSubview(animatedView)
            
            let startFrame = activeTagsView.convert(activeTagsView.bounds, to: nil)
            let (leftConstraint, rightConstraint, heightConstraint, centerConstraint) =
                makeConstraints(view: animatedView, left: 4.0, right: -4.0, height: startFrame.height,
                                centerY: startFrame.midY - toVC.view.frame.height/2)
            NSLayoutConstraint.activate([leftConstraint, rightConstraint, heightConstraint, centerConstraint])
            transitionContext.containerView.layoutIfNeeded()
            
            UIView.animateKeyframes(withDuration: TagController.animationDuration, delay: 0.0, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0,
                                   relativeDuration: TagController.shadowRelativeDuration,
                                   animations: { animatedView.alpha = 1.0 })
                UIView.addKeyframe(withRelativeStartTime: TagController.shadowRelativeDuration,
                                   relativeDuration: TagController.translationRelativeDuration)
                {
                    heightConstraint.constant = 214.0
                    centerConstraint.constant = -23.0
                    transitionContext.containerView.layoutIfNeeded()
                }
            }) { _ in
                toVC.view.alpha = 0.0
                transitionContext.containerView.addSubview(toVC.view)
                animatedView.alpha = 0.0
                toVC.view.alpha = 1.0
                transitionContext.completeTransition(true)
            }
            
        } else if let fromVC = transitionContext.viewController(forKey: .from) as? TagViewController {
            transitionContext.containerView.subviews.forEach { $0.removeFromSuperview() }
            
            let animatedView = makeAnimatedView()
            transitionContext.containerView.addSubview(animatedView)
            
            let (leftConstraint, rightConstraint, heightConstraint, centerConstraint) =
                makeConstraints(view: animatedView, left: 4.0, right: -4.0, height: 214.0, centerY: -23.0)
            NSLayoutConstraint.activate([leftConstraint, rightConstraint, heightConstraint, centerConstraint])
            transitionContext.containerView.layoutIfNeeded()
            
            let endFrame = activeTagsView.convert(activeTagsView.bounds, to: nil)
            UIView.animateKeyframes(withDuration: TagController.animationDuration, delay: 0.0, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0,
                                   relativeDuration: TagController.translationRelativeDuration)
                {
                    heightConstraint.constant = endFrame.height
                    centerConstraint.constant = endFrame.midY - fromVC.view.frame.height/2
                    transitionContext.containerView.layoutIfNeeded()
                }
                UIView.addKeyframe(withRelativeStartTime: TagController.translationRelativeDuration,
                                   relativeDuration: TagController.shadowRelativeDuration,
                                   animations: { animatedView.alpha = 0.0 })
            }) { _ in
                transitionContext.completeTransition(true)
            }
        }
    }
}

extension TagController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
}

// TODO: Make filled close button
// TODO: Show confirm button if user (de)selected tags
class TagViewController: UIViewController {
    @IBOutlet weak var addNewTagTextField: UITextField!
    @IBOutlet weak var addNewTagView: UIView!
    @IBOutlet weak var centerYConstraint: NSLayoutConstraint!
    @IBOutlet weak var tagsView: FlowContainerView!
    
    weak var delegate: TagViewControllerDelegate!
    
    override func viewDidLoad() {
        for tag in DataStore.tags {
            let button = tag.makeControlButton(delegate.tags.contains(tag))
            button.addTarget(self, action: #selector(toggleTag(_:)), for: .touchUpInside)
            tagsView.addSubview(button)
        }
        let button = UIButton(pill: "add new tag", color: .lightGray)
        button.addTarget(self, action: #selector(startAddNewTag), for: .touchUpInside)
        tagsView.addSubview(button)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(_:)),
                                               name: .UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden),
                                               name: .UIKeyboardWillHide, object: nil)
    }
    
    @objc func keyboardWasShown(_ aNotification: NSNotification) {
        guard let userInfo = aNotification.userInfo,
            let keyboardFrame = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect
            else { return }
        centerYConstraint.constant -= keyboardFrame.height/2
        UIView.animate(withDuration: 0.3) { [weak self] in self?.view.layoutIfNeeded() }
    }
    
    @objc func keyboardWillBeHidden() {
        centerYConstraint.constant = -23
        UIView.animate(withDuration: 0.5) { [weak self] in self?.view.layoutIfNeeded() }
    }
    
    @objc func toggleTag(_ sender: DualLabelButton) {
        let isMember = delegate.toggleTag(name: sender.currentTitle!)
        let color = sender.backgroundColor
        UIView.animate(withDuration: 0.2, animations: { sender.backgroundColor = .white }) { _ in
            sender.setLeftTitle(isMember ? "×" : "+")
            UIView.animate(withDuration: 0.2, animations: { sender.backgroundColor = color })
        }
    }
    
    @objc func startAddNewTag() {
        addNewTagView.alpha = 0.0
        addNewTagView.isHidden = false
        UIView.animate(withDuration: 0.5, animations: { [weak self] in self?.addNewTagView.alpha = 1.0 },
                       completion: { [weak self] _ in self?.addNewTagTextField.becomeFirstResponder() })
    }
    
    @IBAction func cancelAddNewTag() {
        addNewTagTextField.resignFirstResponder()
        UIView.animate(withDuration: 0.5, animations: { [weak self] in self?.addNewTagView.alpha = 0.0 },
                       completion: { [weak self] _ in self?.addNewTagView.isHidden = true })
    }
    
    @IBAction func finishAddNewTag() {
        if addNewTagTextField.text != "" {
            do {
                let tag = try delegate.createTag(name: addNewTagTextField.text!)
                // TODO: Animate creation of new tag
                tagsView.addSubview(tag.makeControlButton(false))
            } catch {
                UIApplication.shared.alert(error: error)
            }
        }
        addNewTagTextField.resignFirstResponder()
        UIView.animate(withDuration: 0.5, animations: { [weak self] in self?.addNewTagView.alpha = 0.0 },
                       completion: { [weak self] _ in self?.addNewTagView.isHidden = true })
    }
    
    @IBAction func dismiss() {
        presentingViewController?.dismiss(animated: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

protocol TagViewControllerDelegate: class {
    var tags: Set<Tag> { get }
    func createTag(name: String) throws -> Tag
    func toggleTag(name: String) -> Bool
}

extension TagController: TagViewControllerDelegate {
    enum TagError: LocalizedError {
        case alreadyExists
        
        var localizedDescription: String {
            switch self {
            case .alreadyExists: return "A tag with this name already exists."
            }
        }
    }
    
    var tags: Set<Tag> {
        return tagged.tagSet
    }
    
    /// - precondition: `name` must not be an empty `String`
    func createTag(name: String) throws -> Tag {
        guard DataStore.tags.first(where: { $0.name == name }) == nil else { throw TagError.alreadyExists }
        let tag = Tag()
        tag.name = name
        tag.searchSuggestion = SearchSuggestion()
        tag.searchSuggestion?.kindRaw = SearchSuggestion.Kind.tag.rawValue
        tag.searchSuggestion?.text = name
        DataStore.update(tag)
        return tag
    }
    
    func toggleTag(name: String) -> Bool {
        activeTagsView.subviews.forEach { $0.removeFromSuperview() }
        defer { fillForView[activeTagsView]!(Array(tagged.tagSet)) }
        return tagged.toggleTag(name)
    }
}

private let _caseSensitiveFont: UIFont = {
    let descriptor = UIFont.systemFont(ofSize: 14.0).fontDescriptor.addingAttributes([
        .featureSettings: [
            [
                UIFontDescriptor.FeatureKey.featureIdentifier: kCaseSensitiveLayoutType,
                UIFontDescriptor.FeatureKey.typeIdentifier: kCaseSensitiveLayoutOnSelector
            ]
        ]
    ])
    return UIFont(descriptor: descriptor, size: 0.0)
}()

extension Tag {
    var plainButton: UIButton {
        return UIButton(pill: name, color: color)
    }
    var color: UIColor {
        switch ColorCode(rawValue: colorCodeRaw)! {
        case .lightGray:    return .lightGray
        case .red:          return .red
        case .orange:       return .orange
        case .yellow:       return .yellow
        case .green:        return .green
        case .blue:         return .blue
        case .purple:       return .purple
        }
    }
    
    func makeControlButton(_ isMember: Bool) -> DualLabelButton {
        return isMember ? DualLabelButton(pillLeft: "×", right: name, color: color, leftFont: _caseSensitiveFont) :
            DualLabelButton(pillLeft: "+", right: name, color: color, leftFont: _caseSensitiveFont)
    }
}

class DualLabelButton: UIButton {
    override var intrinsicContentSize: CGSize {
        let width = contentEdgeInsets.left + leftLabel.intrinsicContentSize.width + 3.0 +
            titleLabel!.intrinsicContentSize.width + contentEdgeInsets.right
        let height = contentEdgeInsets.bottom + titleLabel!.intrinsicContentSize.height + contentEdgeInsets.top
        return CGSize(width: width, height: height)
    }

    private let leftLabel = UILabel()
    
    convenience init(pillLeft left: String, right: String, color: UIColor, leftFont: UIFont) {
        self.init(pill: right, color: color)
        leftLabel.font = leftFont
        leftLabel.isUserInteractionEnabled = true
        leftLabel.text = left
        leftLabel.textColor = currentTitleColor
        addSubview(leftLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        leftLabel.frame = CGRect(origin: CGPoint(x: contentEdgeInsets.left, y: contentEdgeInsets.top),
                                 size: leftLabel.intrinsicContentSize)
        titleLabel?.frame = CGRect(origin: CGPoint(x: leftLabel.frame.origin.x+leftLabel.frame.width+3.0,
                                                   y: titleLabel!.frame.origin.y),
                                   size: titleLabel!.intrinsicContentSize)
    }
    
    func setLeftTitle(_ title: String) {
        leftLabel.text = title
        layoutIfNeeded()
    }
}

extension UIButton {
    convenience init(pill title: String, color: UIColor) {
        self.init(type: .custom)
        setTitle(title, for: .normal)
        backgroundColor = color
        contentEdgeInsets = .init(top: 4.0, left: 6.0, bottom: 4.0, right: 6.0)
        titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
        layer.cornerRadius = intrinsicContentSize.height / 2
    }
}
