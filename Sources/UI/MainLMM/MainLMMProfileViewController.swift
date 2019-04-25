//
//  MainLMMProfileViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 15/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Nuke

class MainLMMProfileViewController: UIViewController
{
    var input: MainLMMProfileVMInput!
    
    var topVisibleBorderDistance: CGFloat = 0.0
    {
        didSet {
            self.handleTopBorderDistanceChange(self.topVisibleBorderDistance)
        }
    }
    
    var bottomVisibleBorderDistance: CGFloat = 0.0
    {
        didSet {
            self.handleBottomBorderDistanceChange(self.bottomVisibleBorderDistance)
        }
    }
    
    var currentIndex: BehaviorRelay<Int> = BehaviorRelay<Int>(value: 0)
    var onChatShow: ((LMMProfile, Photo, MainLMMProfileViewController?) -> ())?
    var onChatHide: ((LMMProfile, Photo, MainLMMProfileViewController?) -> ())?
    var onBlockOptionsWillShow: ((Int) -> ())?
    var onBlockOptionsWillHide: (() -> ())?
    
    fileprivate let diposeBag: DisposeBag = DisposeBag()
    fileprivate var viewModel: MainLMMProfileViewModel?
    fileprivate var pagesVC: UIPageViewController?
    fileprivate var photosVCs: [NewFacePhotoViewController] = []
    fileprivate let preheater = ImagePreheater(destination: .diskCache)
    
    @IBOutlet fileprivate weak var messageBtn: UIButton!
    @IBOutlet fileprivate weak var optionsBtn: UIButton!
    @IBOutlet fileprivate weak var messageBtnTopConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var profileIdLabel: UILabel!
    @IBOutlet fileprivate weak var seenLabel: UILabel!
    
    static func create(_ profile: LMMProfile, feedType: LMMType, initialIndex: Int, actionsManager: ActionsManager, profileManager: UserProfileManager, navigationManager: NavigationManager, scenarioManager: AnalyticsScenarioManager ) -> MainLMMProfileViewController
    {
        let storyboard = Storyboards.mainLMM()
        let vc = storyboard.instantiateViewController(withIdentifier: "lmm_profile") as! MainLMMProfileViewController
        vc.input = MainLMMProfileVMInput(profile: profile, feedType: feedType, initialIndex: initialIndex, actionsManager: actionsManager, profileManager: profileManager, navigationManager: navigationManager, scenarioManager: scenarioManager)
        
        return vc
    }
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        // TODO: Move logic inside view model
        self.setupBindings()
        
        guard !self.input.profile.isInvalidated else { return }
        
        self.updateMessageBtnOffset()
        self.messageBtn.setImage(UIImage(named: self.input.profile.state.iconName()), for: .normal)
        
        let input = NewFaceProfileVMInput(profile: self.input.profile, sourceType: self.input.feedType.sourceType(), actionsManager: self.input.actionsManager, profileManager: self.input.profileManager, navigationManager: self.input.navigationManager, scenarioManager: self.input.scenarioManager)
        self.photosVCs = self.input.profile.orderedPhotos().map({ photo in
            let vc = NewFacePhotoViewController.create()
            vc.photo = photo
            vc.input = input
            vc.onChatBlock = { [weak self] in
                self?.onChatSelected()
            }
            
            return vc
        })
        
        let index = self.input.initialIndex
        guard index < self.photosVCs.count else { return }
        
        let vc = self.photosVCs[index]
        self.pagesVC?.setViewControllers([vc], direction: .forward, animated: false, completion: nil)
        self.currentIndex.accept(index)
        
        #if STAGE
        self.profileIdLabel.text = "Profile: " + String(self.input.profile.id.suffix(4))
        self.profileIdLabel.isHidden = false
        self.seenLabel.text = self.viewModel?.input.profile.notSeen == true ? "Not seen" : "Seen"
        self.seenLabel.isHidden = false
        #endif
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "embed_pages" {
            self.pagesVC = segue.destination as? UIPageViewController
            self.pagesVC?.delegate = self
            self.pagesVC?.dataSource = self
        }
    }
    
    func showNotChatControls()
    {
        self.messageBtn.setImage(UIImage(named: self.input.profile.state.iconName()), for: .normal)
        UIManager.shared.chatModeEnabled.accept(false)
    }
    
    func hideNotChatControls()
    {
        UIManager.shared.chatModeEnabled.accept(true)
    }
    
    func preheatSecondPhoto()
    {
        guard self.input.profile.photos.count >= 2 else { return }
        
        if let url = self.input.profile.orderedPhotos()[1].filepath().url() {
            self.preheater.startPreheating(with: [url])
        }
    }
    
    func block(_ isChat: Bool)
    {
        guard self.input.actionsManager.checkConnectionState() else { return }
        
        weak var weakSelf = self
        let profile = self.input.profile
        self.onChatHide?(profile, profile.orderedPhotos()[self.currentIndex.value], weakSelf)
        self.showBlockOptions(isChat)
    }
    
    // MARK: - Actions
    
    @IBAction func onChatSelected()
    {
        guard self.input.actionsManager.checkConnectionState() else { return }
        
        weak var weakSelf = self
        let profile = self.input.profile
        
        guard !profile.isInvalidated else { return }
        
        self.onChatShow?(profile, profile.orderedPhotos()[self.currentIndex.value], weakSelf)
    }
    
    @IBAction func onBlock()
    {
        self.block(false)
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.viewModel = MainLMMProfileViewModel(self.input)
        
        UIManager.shared.blockModeEnabled.asObservable().subscribe(onNext: { [weak self] state in
            let isMessagingAvailable = self?.viewModel?.isMessaingAvailable.value ?? false
            
            self?.messageBtn.isHidden = !isMessagingAvailable || state
            self?.optionsBtn.isHidden = state
        }).disposed(by: self.diposeBag)
        
        UIManager.shared.chatModeEnabled.asObservable().subscribe(onNext: { [weak self] state in
            let isMessagingAvailable = self?.viewModel?.isMessaingAvailable.value ?? false
            
            self?.messageBtn.isHidden = !isMessagingAvailable || state
        }).disposed(by: self.diposeBag)
        
        self.viewModel?.isMessaingAvailable.asObservable().subscribe(onNext: { [weak self] state in
            self?.messageBtn.isHidden = !state
        }).disposed(by: self.diposeBag)
    }
    
    fileprivate func showBlockOptions(_ isChat: Bool)
    {
        UIManager.shared.blockModeEnabled.accept(true)
        onBlockOptionsWillShow?(self.currentIndex.value)
        
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertVC.addAction(UIAlertAction(title: "block_profile_button_block".localized(), style: .default, handler: { _ in
            UIManager.shared.blockModeEnabled.accept(false)
            self.onBlockOptionsWillHide?()
            self.viewModel?.block(at: self.currentIndex.value, reason: BlockReason(rawValue: 0)!)
            AnalyticsManager.shared.send(.blocked(0, self.input.feedType.sourceType().rawValue, isChat))
        }))
        alertVC.addAction(UIAlertAction(title: "block_profile_button_report".localized(), style: .default, handler: { _ in
            self.showBlockReasonOptions(isChat)
        }))
        alertVC.addAction(UIAlertAction(title: "button_cancel".localized(), style: .cancel, handler: { _ in
            self.onBlockOptionsWillHide?()
            UIManager.shared.blockModeEnabled.accept(false)
        }))
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
    fileprivate func showBlockReasonOptions(_ isChat: Bool)
    {
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let reasons = isChat ? BlockReason.reportChatResons() : BlockReason.reportResons()
        for reason in reasons {            
            alertVC.addAction(UIAlertAction(title: reason.title(), style: .default) { _ in
                self.showBlockReasonConfirmation(reason, isChat: isChat)
            })
        }
        
        alertVC.addAction(UIAlertAction(title: "button_cancel".localized(), style: .cancel, handler: { _ in
            self.onBlockOptionsWillHide?()
            UIManager.shared.blockModeEnabled.accept(false)
        }))
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
    fileprivate func showBlockReasonConfirmation(_ reason: BlockReason, isChat: Bool)
    {
        let alertVC = UIAlertController(
            title: nil,
            message: "block_profile_alert_title".localized() + " " + reason.title(),
            preferredStyle: .alert
        )
        alertVC.addAction(UIAlertAction(title: "block_profile_button_report".localized(), style: .default, handler: { _ in
            UIManager.shared.blockModeEnabled.accept(false)
            self.onBlockOptionsWillHide?()
            self.viewModel?.block(at: self.currentIndex.value, reason: reason)
            AnalyticsManager.shared.send(.blocked(reason.rawValue, self.input.feedType.sourceType().rawValue, isChat))
        }))
        alertVC.addAction(UIAlertAction(title: "button_cancel".localized(), style: .cancel, handler: { _ in
            self.onBlockOptionsWillHide?()
            UIManager.shared.blockModeEnabled.accept(false)
        }))
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
    fileprivate func updateMessageBtnOffset()
    {
        self.messageBtnTopConstraint.constant = self.input.feedType != .likesYou ? 138.0 : 228.0
    }
    
    fileprivate func handleTopBorderDistanceChange(_ value: CGFloat)
    {
        self.optionsBtn.alpha = self.discreetOpacity(for: self.topOpacityFor(self.optionsBtn.frame, offset: value) ?? 1.0)
        self.messageBtn.alpha = self.discreetOpacity(for: self.topOpacityFor(self.messageBtn.frame, offset: value) ?? 1.0)
    }
    
    fileprivate func handleBottomBorderDistanceChange(_ value: CGFloat)
    {
        if let optionBtnOpacity = self.bottomOpacityFor(self.optionsBtn.frame, offset: value) {
            self.optionsBtn.alpha = self.discreetOpacity(for: optionBtnOpacity)
        }
        
        if let messageBtnOpacity = self.bottomOpacityFor(self.messageBtn.frame, offset: value) {
            self.messageBtn.alpha = self.discreetOpacity(for: messageBtnOpacity)
        }
    }
    
    fileprivate func topOpacityFor(_ frame: CGRect, offset: CGFloat) -> CGFloat?
    {
        let y = frame.origin.y
        let inset = abs(offset)
        
        guard offset < 0.0 else { return nil }
        guard inset > y else { return nil }
        
        let t = 1.0 - (inset - y) / (frame.height / 2.0)
        
        guard t > 0.0 else { return 0.0 }
        
        return pow(t, 2.0)
    }
    
    fileprivate func bottomOpacityFor(_ frame: CGRect, offset: CGFloat) -> CGFloat?
    {
        let inset = abs(offset)
        let y = self.view.bounds.height - frame.maxY
        
        guard offset < 0.0 else { return nil }
        guard inset > frame.height else { return nil }
        
        let t = 1.0 - (inset - y) / (frame.height / 2.0)
        
        guard t > 0.0 else { return 0.0 }
        
        return pow(t, 2.0)
    }
    
    fileprivate func discreetOpacity(for opacity: CGFloat) -> CGFloat
    {
        return opacity < 0.5 ? 0.0 : 1.0
    }
}

extension MainLMMProfileViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource
{
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController])
    {
        self.input.scenarioManager.checkPhotoSwipe(self.input.feedType.sourceType())
        
        guard let urls = self.viewModel?.input.profile.orderedPhotos().map({ $0.filepath().url() }) else { return }
        
        self.preheater.startPreheating(with: urls.compactMap({ $0 }))
        UIManager.shared.feedsFabShouldBeHidden.accept(true)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController?
    {
        guard let vc = viewController as? NewFacePhotoViewController else { return nil }
        guard let index = self.photosVCs.index(of: vc) else { return nil }
        guard index > 0 else { return nil }
        
        return self.photosVCs[index-1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController?
    {
        guard let vc = viewController as? NewFacePhotoViewController else { return nil }
        guard let index = self.photosVCs.index(of: vc) else { return nil}
        guard index < (self.photosVCs.count - 1) else { return nil }
        
        return self.photosVCs[index+1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool)
    {
        guard let photoVC = pageViewController.viewControllers?.first as? NewFacePhotoViewController else { return }
        
        guard finished, completed else { return }
        guard let index = self.photosVCs.index(of: photoVC) else { return }
        
        self.currentIndex.accept(index)
    }
}

extension MessagingState
{
    func iconName() -> String
    {
        switch self {
        case .empty: return "feed_messages_empty"
        case .outcomingOnly: return "feed_messages"
        case .chatRead: return "feed_chat_read"
        case .chatUnread: return "feed_chat_unread"
        }
    }
}
