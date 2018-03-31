//
//  TagController.swift
//  Foodlog
//
//  Created by David on 2/23/18.
//  Copyright © 2018 Gofake1. All rights reserved.
//

import UIKit

// TODO: UI to choose tag color
class TagController: NSObject {
    @IBOutlet weak var scrollController: ScrollController!
    @IBOutlet weak var foodEntryTagsView: FlowContainerView!
    @IBOutlet weak var foodTagsView: FlowContainerView!
    
    private static let shadowDuration = 0.4
    private static let shadowRelativeDuration = shadowDuration / animationDuration
    private static let translationDuration = 0.4
    private static let translationRelativeDuration = translationDuration / animationDuration
    private static let animationDuration = shadowDuration + translationDuration
    private weak var activeTagsView: FlowContainerView!
    private var context: TagControllerContext!
    private var fillForView = [FlowContainerView: (AnyCollection<Tag>) -> ()]()
    
    func setup(_ context: TagControllerContext) {
        func makeFill(for view: UIView, empty: @escaping () -> UIView, make: @escaping (Tag) -> UIView)
            -> (AnyCollection<Tag>) -> ()
        {
            return { [weak view] tags in
                if tags.count == 0 {
                    view!.addSubview(empty())
                } else {
                    tags.map({ make($0) }).forEach({ view!.addSubview($0) })
                }
            }
        }
        
        fillForView[foodEntryTagsView] = makeFill(for: foodEntryTagsView, empty: {
            let button = UIButton(pillFilled: "add tags to entry", color: .lightGray)
            button.addTarget(self, action: #selector(TagController.foodEntryTagPressed), for: .touchUpInside)
            return button
        }, make: {
            let button = $0.activeButton
            button.addTarget(self, action: #selector(TagController.foodEntryTagPressed), for: .touchUpInside)
            return button
        })
        
        if context.disableFoodTagsView {
            fillForView[foodTagsView] = makeFill(for: foodTagsView, empty: {
                let label = UILabel()
                label.textColor = .lightGray
                label.text = "no tags"
                label.translatesAutoresizingMaskIntoConstraints = false
                let padderView = UIView()
                padderView.translatesAutoresizingMaskIntoConstraints = false
                padderView.addSubview(label)
                let left = padderView.leftAnchor.constraint(equalTo: label.leftAnchor, constant: -6.0)
                let right = padderView.rightAnchor.constraint(equalTo: label.rightAnchor)
                let top = padderView.topAnchor.constraint(equalTo: label.topAnchor)
                let bottom = padderView.bottomAnchor.constraint(equalTo: label.bottomAnchor)
                NSLayoutConstraint.activate([left, right, top, bottom])
                return padderView
            }, make: {
                $0.disabledButton
            })
        } else {
            fillForView[foodTagsView] = makeFill(for: foodTagsView, empty: {
                let button = UIButton(pillFilled: "add tags to food", color: .lightGray)
                button.addTarget(self, action: #selector(TagController.foodTagPressed), for: .touchUpInside)
                return button
            }, make: {
                let button = $0.activeButton
                button.addTarget(self, action: #selector(TagController.foodTagPressed), for: .touchUpInside)
                return button
            })
        }
        
        self.context = context
        context.onDismissModal = { [weak self] tags in
            self!.activeTagsView.subviews.forEach { $0.removeFromSuperview() }
            self!.fillForView[self!.activeTagsView]!(tags)
        }
        fillForView[foodEntryTagsView]!(context.tags.0)
        fillForView[foodTagsView]!(context.tags.1)
    }
    
    @objc func foodEntryTagPressed() {
        showModal(tagView: foodEntryTagsView, delegate: context.vcDelegates.0)
    }
    
    @objc func foodTagPressed() {
        showModal(tagView: foodTagsView, delegate: context.vcDelegates.1)
    }
    
    private func showModal(tagView: FlowContainerView, delegate: TagViewControllerDelegate) {
        // Workaround: Disable scroll behavior when creating new tag
        scrollController.scrollToView(nil)
        
        activeTagsView = tagView
        let tagVC: TagViewController = VCController.makeVC(.tag)
        tagVC.delegate = delegate
        tagVC.modalPresentationStyle = .overCurrentContext
        tagVC.transitioningDelegate = self
        UIApplication.shared.keyWindow?.rootViewController?.present(tagVC, animated: true)
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
            let view2 = transitionContext.containerView
            return (view.leftAnchor.constraint(equalTo: view2.leftAnchor, constant: left),
                    view.rightAnchor.constraint(equalTo: view2.rightAnchor, constant: right),
                    view.heightAnchor.constraint(equalToConstant: height),
                    view.centerYAnchor.constraint(equalTo: view2.centerYAnchor, constant: centerY))
        }
        
        if let toVC = transitionContext.viewController(forKey: .to) as? TagViewController {
            let animatedView = makeAnimatedView()
            animatedView.alpha = 0.0
            transitionContext.containerView.addSubview(animatedView)
            
            let startFrame = activeTagsView.convert(activeTagsView.bounds, to: nil)
            let (left, right, height, centerY) =
                makeConstraints(view: animatedView, left: 4.0, right: -4.0, height: startFrame.height,
                                centerY: startFrame.midY - toVC.view.frame.height/2)
            NSLayoutConstraint.activate([left, right, height, centerY])
            transitionContext.containerView.layoutIfNeeded()
            
            UIView.animateKeyframes(withDuration: TagController.animationDuration, delay: 0.0, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0,
                                   relativeDuration: TagController.shadowRelativeDuration,
                                   animations: { animatedView.alpha = 1.0 })
                UIView.addKeyframe(withRelativeStartTime: TagController.shadowRelativeDuration,
                                   relativeDuration: TagController.translationRelativeDuration)
                {
                    height.constant = 214.0
                    centerY.constant = -23.0
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
            
            let (left, right, height, centerY) =
                makeConstraints(view: animatedView, left: 4.0, right: -4.0, height: 214.0, centerY: -23.0)
            NSLayoutConstraint.activate([left, right, height, centerY])
            transitionContext.containerView.layoutIfNeeded()
            
            let endFrame = activeTagsView.convert(activeTagsView.bounds, to: nil)
            UIView.animateKeyframes(withDuration: TagController.animationDuration, delay: 0.0, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0,
                                   relativeDuration: TagController.translationRelativeDuration)
                {
                    height.constant = endFrame.height
                    centerY.constant = endFrame.midY - fromVC.view.frame.height/2
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

protocol TagControllerContext: class {
    var disableFoodTagsView: Bool { get }
    var onDismissModal: (AnyCollection<Tag>) -> () { get set }
    var tags: (AnyCollection<Tag>, AnyCollection<Tag>) { get }
    var vcDelegates: (TagViewControllerDelegate, TagViewControllerDelegate) { get }
}

final class AddEntryForExistingFoodTagControllerContext: TagControllerContext {
    var disableFoodTagsView: Bool {
        return true
    }
    var onDismissModal: (AnyCollection<Tag>) -> () = { _ in }
    var tags: (AnyCollection<Tag>, AnyCollection<Tag>) {
        return (AnyCollection(foodEntry.tags), AnyCollection(foodEntry.food!.tags))
    }
    var vcDelegates: (TagViewControllerDelegate, TagViewControllerDelegate) {
        return (FoodEntryTagViewControllerDelegate(self, foodEntry), FoodTagViewControllerDelegate(self, foodEntry.food!))
    }
    private let foodEntry: FoodEntry
    
    init(_ foodEntry: FoodEntry) {
        self.foodEntry = foodEntry
    }
}

final class AddEntryForNewFoodTagControllerContext: TagControllerContext {
    var disableFoodTagsView: Bool {
        return false
    }
    var onDismissModal: (AnyCollection<Tag>) -> () = { _ in }
    var tags: (AnyCollection<Tag>, AnyCollection<Tag>) {
        return (AnyCollection(foodEntry.tags), AnyCollection(foodEntry.food!.tags))
    }
    var vcDelegates: (TagViewControllerDelegate, TagViewControllerDelegate) {
        return (FoodEntryTagViewControllerDelegate(self, foodEntry), FoodTagViewControllerDelegate(self, foodEntry.food!))
    }
    private let foodEntry: FoodEntry
    
    init(_ foodEntry: FoodEntry) {
        self.foodEntry = foodEntry
    }
}

final class EditFoodTagControllerContext: TagControllerContext {
    var disableFoodTagsView: Bool {
        return false
    }
    var onDismissModal: (AnyCollection<Tag>) -> () = { _ in }
    var tags: (AnyCollection<Tag>, AnyCollection<Tag>) {
        return (AnyCollection([]), AnyCollection(food.tags))
    }
    var vcDelegates: (TagViewControllerDelegate, TagViewControllerDelegate) {
        return (DummyTagViewControllerDelegate(), FoodTagViewControllerDelegate(self, food, foodInfoChanged))
    }
    private let food: Food
    private let foodInfoChanged: Ref<Bool>
    
    init(_ food: Food, _ foodInfoChanged: Ref<Bool>) {
        self.food = food
        self.foodInfoChanged = foodInfoChanged
    }
}

final class EditFoodEntryTagControllerContext: TagControllerContext {
    var disableFoodTagsView: Bool {
        return false
    }
    var onDismissModal: (AnyCollection<Tag>) -> () = { _ in }
    var tags: (AnyCollection<Tag>, AnyCollection<Tag>) {
        return (AnyCollection(foodEntry.tags), AnyCollection(foodEntry.food!.tags))
    }
    var vcDelegates: (TagViewControllerDelegate, TagViewControllerDelegate) {
        return (FoodEntryTagViewControllerDelegate(self, foodEntry, foodEntryInfoChanged),
                FoodTagViewControllerDelegate(self, foodEntry.food!, foodInfoChanged))
    }
    private let foodEntry: FoodEntry
    private let foodEntryInfoChanged: Ref<Bool>
    private let foodInfoChanged: Ref<Bool>
    
    init(_ foodEntry: FoodEntry, _ foodEntryInfoChanged: Ref<Bool>, _ foodInfoChanged: Ref<Bool>) {
        self.foodEntry = foodEntry
        self.foodEntryInfoChanged = foodEntryInfoChanged
        self.foodInfoChanged = foodInfoChanged
    }
}

class TagViewController: UIViewController {
    @IBOutlet weak var addNewTagTextField: UITextField!
    @IBOutlet weak var addNewTagView: UIView!
    @IBOutlet weak var centerYConstraint: NSLayoutConstraint!
    @IBOutlet weak var tagsView: FlowContainerView!
    
    var delegate: TagViewControllerDelegate!
    
    override func viewDidLoad() {
        for tag in DataStore.tags {
            tagsView.addSubview(tag.makeControlButton(delegate.tags.contains(tag), self, #selector(toggleTag(_:))))
        }
        let button = UIButton(pillFilled: "add new tag", color: .lightGray)
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
                tagsView.addSubview(tag.makeControlButton(false, self, #selector(toggleTag(_:))))
            } catch {
                UIApplication.shared.alert(error: error)
            }
        }
        addNewTagTextField.resignFirstResponder()
        UIView.animate(withDuration: 0.5, animations: { [weak self] in self?.addNewTagView.alpha = 0.0 }) {
            [weak self] _ in
            self?.addNewTagView.isHidden = true
            self?.addNewTagTextField.text = nil
        }
    }
    
    @IBAction func dismiss() {
        delegate.willBeDismissed()
        presentingViewController?.dismiss(animated: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

protocol TagViewControllerDelegate {
    var tags: AnyCollection<Tag> { get }
    func createTag(name: String) throws -> Tag
    func toggleTag(name: String) -> Bool
    func willBeDismissed()
}

enum TagError: LocalizedError {
    case alreadyExists
    
    var localizedDescription: String {
        switch self {
        case .alreadyExists: return "A tag with this name already exists."
        }
    }
}

extension TagViewControllerDelegate {
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
}

final class DummyTagViewControllerDelegate: TagViewControllerDelegate {
    var tags: AnyCollection<Tag> {
        fatalError()
    }
    
    func createTag(name: String) throws -> Tag {
        fatalError()
    }
    
    func toggleTag(name: String) -> Bool {
        fatalError()
    }
    
    func willBeDismissed() {
        fatalError()
    }
}

final class FoodTagViewControllerDelegate: TagViewControllerDelegate {
    var tags: AnyCollection<Tag> {
        return AnyCollection(food.tags)
    }
    private weak var context: TagControllerContext!
    private let food: Food
    private let foodInfoChanged: Ref<Bool>?
    
    init(_ context: TagControllerContext, _ food: Food, _ foodInfoChanged: Ref<Bool>? = nil) {
        self.context = context
        self.food = food
        self.foodInfoChanged = foodInfoChanged
    }
    
    func toggleTag(name: String) -> Bool {
        foodInfoChanged?.value = true
        if let index = food.tags.index(where: { $0.name == name }) {
            food.tags.remove(at: index)
            return false
        } else {
            let tag = Tag(value: DataStore.tags.first(where: { $0.name == name })!)
            tag.searchSuggestion! = SearchSuggestion(value: tag.searchSuggestion!)
            tag.searchSuggestion!.lastUsed = Date()
            food.tags.append(tag)
            return true
        }
    }
    
    func willBeDismissed() {
        context.onDismissModal(tags)
    }
}

final class FoodEntryTagViewControllerDelegate: TagViewControllerDelegate {
    var tags: AnyCollection<Tag> {
        return AnyCollection(foodEntry.tags)
    }
    private weak var context: TagControllerContext!
    private let foodEntry: FoodEntry
    private let foodEntryInfoChanged: Ref<Bool>?
    
    init(_ context: TagControllerContext, _ foodEntry: FoodEntry, _ foodEntryInfoChanged: Ref<Bool>? = nil) {
        self.context = context
        self.foodEntry = foodEntry
        self.foodEntryInfoChanged = foodEntryInfoChanged
    }
    
    func toggleTag(name: String) -> Bool {
        foodEntryInfoChanged?.value = true
        if let index = foodEntry.tags.index(where: { $0.name == name }) {
            foodEntry.tags.remove(at: index)
            return false
        } else {
            let tag = Tag(value: DataStore.tags.first(where: { $0.name == name })!)
            tag.searchSuggestion! = SearchSuggestion(value: tag.searchSuggestion!)
            tag.searchSuggestion!.lastUsed = Date()
            foodEntry.tags.append(tag)
            return true
        }
    }
    
    func willBeDismissed() {
        context.onDismissModal(tags)
    }
}

extension Tag {
    func makeControlButton(_ isMember: Bool, _ target: Any, _ action: Selector) -> DualLabelButton {
        let button = isMember ? DualLabelButton(pillLeft: "×", right: name, color: color) :
            DualLabelButton(pillLeft: "+", right: name, color: color)
        button.addTarget(target, action: action, for: .touchUpInside)
        return button
    }
}

class DualLabelButton: UIButton {
    override var intrinsicContentSize: CGSize {
        let width = contentEdgeInsets.left + leftLabel.intrinsicContentSize.width + 3.0 +
            titleLabel!.intrinsicContentSize.width + contentEdgeInsets.right
        let height = contentEdgeInsets.bottom + titleLabel!.intrinsicContentSize.height + contentEdgeInsets.top
        return CGSize(width: width, height: height)
    }

    private static let caseSensitiveFont: UIFont = {
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
    private let leftLabel = UILabel()
    
    convenience init(pillLeft left: String, right: String, color: UIColor) {
        self.init(pillFilled: right, color: color)
        leftLabel.font = DualLabelButton.caseSensitiveFont
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
