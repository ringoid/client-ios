//
//  MainViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 09/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

enum CachedUIState
{
    case discover
    case likes
    case chats
    case profile
}

enum RemoteFeedType: String
{
    case unknown = "unknown"
    case likesYou = "NEW_LIKE_PUSH_TYPE"
    case matches = "NEW_MATCH_PUSH_TYPE"
    case messages = "NEW_MESSAGE_PUSH_TYPE"
}

class MainViewController: BaseViewController
{
    var input: MainVMInput!
    var defaultState: SelectionState = .searchAndFetch
    
    fileprivate var viewModel: MainViewModel?
    fileprivate var containerVC: ContainerViewController!
    fileprivate weak var containedVC: UIViewController?
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    fileprivate var menuVCCache: [CachedUIState: UIViewController] = [:]
    fileprivate var prevState: SelectionState? = nil
    fileprivate var isBannerClosedManually: Bool = false
    
    fileprivate var preshownLikesCount: Int = 0
    fileprivate var preshownMatchesCount: Int = 0
    fileprivate var preshownMessagesCount: Int = 0
    
    @IBOutlet fileprivate weak var searchBtn: UIButton!
    @IBOutlet fileprivate weak var likeBtn: UIButton!
    @IBOutlet fileprivate weak var chatsBtn: UIButton!
    @IBOutlet fileprivate weak var profileBtn: UIButton!
    @IBOutlet fileprivate weak var profileIndicatorView: UIView!
    @IBOutlet fileprivate weak var effectsView: MainEffectsView!
    @IBOutlet fileprivate weak var buttonsStackView: UIView!
    @IBOutlet fileprivate weak var bottomShadowView: UIView!
    
    @IBOutlet fileprivate weak var likesYouIndicatorView: UIView!
    @IBOutlet fileprivate weak var chatIndicatorView: UIView!
    
    @IBOutlet fileprivate weak var notificationsBannerView: UIView!
    @IBOutlet fileprivate weak var notificationsBannerLabel: UILabel!
    @IBOutlet fileprivate weak var notificationsBannerSubLabel: UILabel!

    
    static func create() -> MainViewController
    {
        let storyboard = Storyboards.main()
        
        return storyboard.instantiateInitialViewController() as! MainViewController
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        GlobalAnimationManager.shared.animationView = self.effectsView
        
        self.setupBindings()
        
//        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(showDebugRateUsAlert))
//        tapRecognizer.numberOfTapsRequired = 2
//        self.likeBtn.addGestureRecognizer(tapRecognizer)
    }
    
    #if STAGE
    @objc func showDebugRateUsAlert()
    {
        RateUsManager.shared.showAlert(self)
    }
    
    @objc func showDebugLikesCount()
    {
        let size = self.likeBtn.bounds.size
        let center = self.likeBtn.convert(CGPoint(x: size.width / 2.0, y: size.height / 2.0), to: nil)
        let position = CGPoint(x: 44.0, y: center.y + 16.0)
        self.effectsView.animateLikes(5, from: position)
        
        self.effectsView.animateLikesDelta(20)
    }
    
    @objc func showDebugLikes()
    {
        let alertVC = UIAlertController(title: "Simulate likes", message: nil, preferredStyle: .alert)
        alertVC.addTextField(configurationHandler: { textField in
            textField.keyboardType = .numberPad
        })
        alertVC.addAction(UIAlertAction(title: "Simulate", style: .default, handler: { _ in
            guard let text = alertVC.textFields?.first?.text, let count = Int(text) else { return }
            
            let size = self.likeBtn.bounds.size
            let center = self.likeBtn.convert(CGPoint(x: size.width / 2.0, y: size.height / 2.0), to: nil)
            let position = CGPoint(x: 44.0, y: center.y + 16.0)
            self.effectsView.animateLikes(count, from: position)
            self.effectsView.animateMatches(Int(Double(count) / 3.0), from: position)
            self.effectsView.animateMessages(Int(Double(count) / 2.0), from: position)
        }))
        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        
        self.present(alertVC, animated: true, completion: nil)
    }
    #endif
    
    override func updateTheme()
    {
        self.view.backgroundColor = BackgroundColor().uiColor()
    }
    
    override func updateLocale()
    {
        self.notificationsBannerLabel.text = "settings_notifications_banner_title".localized()
        self.notificationsBannerSubLabel.text = "settings_notifications_banner_subtitle".localized()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "embed_container"
        {
            self.containerVC = segue.destination as? ContainerViewController
        }
        
        if segue.identifier == "embed_visual_notifications"
        {
            let vc = segue.destination as? VisualNotificationsViewController
            vc?.input = VisualNotificationsVMInput(
                manager: self.input.visualNotificationsManager,
                navigation: self.input.navigationManager
            )
        }
    }
    
    // MARK: - Actions
    
    @IBAction func onSearchSelected()
    {
        self.viewModel?.moveToSearch()
    }
    
    @IBAction func onLikeSelected()
    {
        self.viewModel?.moveToLikes()
    }
    
    @IBAction func onProfileSelected()
    {
        self.viewModel?.moveToProfile()
    }
    
    @IBAction func onChatsSelected()
    {
        self.viewModel?.moveToChats()
    }
    
    @IBAction fileprivate func onBannerTap()
    {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
        
        self.closeBanner()
    }
    
    @IBAction fileprivate func onBannerClose()
    {
        self.isBannerClosedManually = true
        
        self.closeBanner()
    }
    
    fileprivate func closeBanner()
    {
        let animator = UIViewPropertyAnimator(duration: 0.1, curve: .easeIn) { [weak self] in
            self?.notificationsBannerView.alpha = 0.0
        }
        
        animator.addCompletion { [weak self] _ in
            self?.notificationsBannerView.isHidden = true
            self?.notificationsBannerView.alpha = 1.0
        }
        
        animator.startAnimation()
    }
    
    // MARK: -
    
    fileprivate func select(_ to: SelectionState)
    {
        self.input.actionsManager.commit()
        
        if let prevState = self.prevState, prevState == to { return }
        
        switch to {
        case .chat(_):
            self.prevState = .chats
            break
            
        default:
            self.prevState = to
            break
        }
        
        ModalUIManager.shared.hide(animated: false)
        
        switch to {
        case .search:
            self.searchBtn.setImage(UIImage(named: "main_bar_search_selected"), for: .normal)
            self.likeBtn.setImage(UIImage(named: "main_bar_like"), for: .normal)
            self.chatsBtn.setImage(UIImage(named: "main_bar_messages"), for: .normal)
            self.profileBtn.setImage(UIImage(named: "main_bar_profile"), for: .normal)
            self.embedNewFaces()
            break
            
        case .likes:
            self.searchBtn.setImage(UIImage(named: "main_bar_search"), for: .normal)
            self.likeBtn.setImage(UIImage(named: "main_bar_like_selected"), for: .normal)
            self.chatsBtn.setImage(UIImage(named: "main_bar_messages"), for: .normal)
            self.profileBtn.setImage(UIImage(named: "main_bar_profile"), for: .normal)
            self.embedLikes()
            break
            
        case .chats:
            self.chatsBtn.setImage(UIImage(named: "main_bar_messages_selected"), for: .normal)
            self.searchBtn.setImage(UIImage(named: "main_bar_search"), for: .normal)
            self.likeBtn.setImage(UIImage(named: "main_bar_like"), for: .normal)
            self.profileBtn.setImage(UIImage(named: "main_bar_profile"), for: .normal)
            self.embedChats()
            break
            
        case .profile:
            self.searchBtn.setImage(UIImage(named: "main_bar_search"), for: .normal)
            self.likeBtn.setImage(UIImage(named: "main_bar_like"), for: .normal)
            self.chatsBtn.setImage(UIImage(named: "main_bar_messages"), for: .normal)
            self.profileBtn.setImage(UIImage(named: "main_bar_profile_selected"), for: .normal)
            self.embedUserProfile()
            break
            
        case .profileAndPick:
            self.searchBtn.setImage(UIImage(named: "main_bar_search"), for: .normal)
            self.likeBtn.setImage(UIImage(named: "main_bar_like"), for: .normal)
            self.chatsBtn.setImage(UIImage(named: "main_bar_messages"), for: .normal)
            self.profileBtn.setImage(UIImage(named: "main_bar_profile_selected"), for: .normal)
            self.embedUserProfileAndPick()
            break
            
        case .profileAndFetch:
            self.searchBtn.setImage(UIImage(named: "main_bar_search"), for: .normal)
            self.likeBtn.setImage(UIImage(named: "main_bar_like"), for: .normal)
            self.chatsBtn.setImage(UIImage(named: "main_bar_messages"), for: .normal)
            self.profileBtn.setImage(UIImage(named: "main_bar_profile_selected"), for: .normal)
            self.embedUserProfileAndFetch()
            break
            
        case .profileAndAsk:
            self.searchBtn.setImage(UIImage(named: "main_bar_search"), for: .normal)
            self.likeBtn.setImage(UIImage(named: "main_bar_like"), for: .normal)
            self.chatsBtn.setImage(UIImage(named: "main_bar_messages"), for: .normal)
            self.profileBtn.setImage(UIImage(named: "main_bar_profile_selected"), for: .normal)
            self.embedUserProfileAndAsk()
            break
            
        case .searchAndFetch:
            self.searchBtn.setImage(UIImage(named: "main_bar_search_selected"), for: .normal)
            self.likeBtn.setImage(UIImage(named: "main_bar_like"), for: .normal)
            self.chatsBtn.setImage(UIImage(named: "main_bar_messages"), for: .normal)
            self.profileBtn.setImage(UIImage(named: "main_bar_profile"), for: .normal)
            self.embedNewFacesAndFetch()
            break
            
        case .searchAndFetchFirstTime:
            self.searchBtn.setImage(UIImage(named: "main_bar_search_selected"), for: .normal)
            self.likeBtn.setImage(UIImage(named: "main_bar_like"), for: .normal)
            self.chatsBtn.setImage(UIImage(named: "main_bar_messages"), for: .normal)
            self.profileBtn.setImage(UIImage(named: "main_bar_profile"), for: .normal)
            self.embedNewFacesAndFetchFirstTime()
            break
            
        case .likeAndFetch:
            self.searchBtn.setImage(UIImage(named: "main_bar_search"), for: .normal)
            self.likeBtn.setImage(UIImage(named: "main_bar_like_selected"), for: .normal)
            self.chatsBtn.setImage(UIImage(named: "main_bar_messages"), for: .normal)
            self.profileBtn.setImage(UIImage(named: "main_bar_profile"), for: .normal)
            self.embedMainLMMAndFetch()
            break
            
        case .chat(let profileId):
            self.chatsBtn.setImage(UIImage(named: "main_bar_messages_selected"), for: .normal)
            self.searchBtn.setImage(UIImage(named: "main_bar_search"), for: .normal)
            self.likeBtn.setImage(UIImage(named: "main_bar_like"), for: .normal)
            self.profileBtn.setImage(UIImage(named: "main_bar_profile"), for: .normal)
            self.embedChat(profileId)
            break
        }
    }
    
    fileprivate func embedNewFaces()
    {
        guard let vc = self.getNewFacesVC() else { return }
        self.containerVC.embed(vc)
    }
    
    fileprivate func embedNewFacesAndFetch()
    {
        guard let vc = self.getNewFacesVC() else { return }
        
        self.containedVC = vc
        self.containerVC.embed(vc)
        DispatchQueue.main.async {
            vc.reload(false)
        }
    }
    
    fileprivate func embedNewFacesAndFetchFirstTime()
    {
        guard let vc = self.getNewFacesVC() else { return }
        
        self.containedVC = vc
        self.containerVC.embed(vc)
        DispatchQueue.main.async {
            vc.reload(false)
            vc.showFilterFromFeed()
        }
    }
    
    fileprivate func embedLikes()
    {
        if let vc = self.menuVCCache[.likes] as? MainLMMContainerViewController {
            self.containedVC = vc
            self.containerVC.embed(vc)
            
            return
        }
        
        guard let vc = self.getMainLMMVC() else { return }
        self.containedVC = vc
        self.containerVC.embed(vc)
        
        self.menuVCCache[.likes] = vc
        
        DispatchQueue.main.async {
            vc.toggle(.likesYou)
        }
    }
    
    fileprivate func embedChats()
    {
        if let vc = self.menuVCCache[.chats] as? MainLMMContainerViewController {
            self.containedVC = vc
            self.containerVC.embed(vc)
            
            return
        }
        
        guard let vc = self.getMainLMMVC() else { return }
        self.containedVC = vc
        self.containerVC.embed(vc)
        
        self.menuVCCache[.chats] = vc
        
        DispatchQueue.main.async {
            vc.toggle(.messages)
        }
    }
    
    fileprivate func embedChat(_ profileId: String)
    {
        if let vc = self.menuVCCache[.chats] as? MainLMMContainerViewController {
            self.containedVC = vc
            self.containerVC.embed(vc)
            vc.openChat(profileId)
            
            return
        }
        
        guard let vc = self.getMainLMMVC() else { return }
        self.containedVC = vc
        self.containerVC.embed(vc)
        
        self.menuVCCache[.chats] = vc
        
        DispatchQueue.main.async {
            vc.toggle(.messages)
            vc.openChat(profileId)
        }
    }
    
    fileprivate func embedUserProfile()
    {
        guard let vc = self.getUserProfileVC() else { return }
        
        self.containedVC = vc
        self.containerVC.embed(vc)
    }
    
    fileprivate func embedUserProfileAndPick()
    {
        guard let vc = self.getUserProfileVC() else { return }
        
        self.containedVC = vc
        self.containerVC.embed(vc)
        
        vc.showPhotoPicker()
    }
    
    fileprivate func embedUserProfileAndFetch()
    {
        guard let vc = self.getUserProfileVC() else { return }
        
        self.containedVC = vc
        self.containerVC.embed(vc)
        
        vc.reload()
    }
    
    fileprivate func embedUserProfileAndAsk()
    {
        guard let vc = self.getUserProfileVC() else { return }
        
        self.containedVC = vc
        self.containerVC.embed(vc)
        
        vc.askIfNeeded()
    }
    
    fileprivate func embedMainLMMAndFetch()
    {
        guard let vc = self.getMainLMMVC() else { return }
        
        self.containedVC = vc
        self.containerVC.embed(vc)
        
        DispatchQueue.main.async {
            vc.reload()
        }
    }
    
    fileprivate func getMainLMMVC() -> MainLMMContainerViewController?
    {
        let storyboard = Storyboards.mainLMM()
        guard let vc = storyboard.instantiateInitialViewController() as? MainLMMContainerViewController else { return nil }
        vc.input = MainLMMVMInput(
            lmmManager: self.input.lmmManager,
            actionsManager: self.input.actionsManager,
            chatManager: self.input.chatManager,
            profileManager: self.input.profileManager,
            navigationManager: self.input.navigationManager,
            newFacesManager: self.input.newFacesManager,
            notifications: self.input.notifications,
            location: self.input.location,
            scenario: self.input.scenario,
            transition: self.input.transition,
            settings: self.input.settingsManager,
            filter: self.input.filter,
            externalLinkManager: self.input.externalLinkManager
        )
        
        return vc
    }
    
    fileprivate func getUserProfileVC() -> UserProfilePhotosViewController?
    {
        if let vc = self.menuVCCache[.profile] as? UserProfilePhotosViewController { return vc }
        
        let storyboard = Storyboards.userProfile()
        guard let vc = storyboard.instantiateInitialViewController() as? UserProfilePhotosViewController else { return nil }
        vc.input = UserProfilePhotosVCInput(
            profileManager: self.input.profileManager,
            lmmManager: self.input.lmmManager,
            settingsManager: self.input.settingsManager,
            navigationManager: self.input.navigationManager,
            newFacesManager: self.input.newFacesManager,
            actionsManager: self.input.actionsManager,
            errorsManager: self.input.errorsManager,
            promotionManager: self.input.promotionManager,
            device: self.input.device,
            location: self.input.location,
            scenario: self.input.scenario,
            db: self.input.db,
            filter: self.input.filter,
            externalLinkManager: self.input.externalLinkManager
        )
        
        self.menuVCCache[.profile] = vc
        
        return vc
    }
    
    fileprivate func getNewFacesVC() -> NewFacesViewController?
    {
        if let vc = self.menuVCCache[.discover] as? NewFacesViewController { return vc }
        
        let storyboard = Storyboards.newFaces()
        guard let vc = storyboard.instantiateInitialViewController() as? NewFacesViewController else { return nil }
        vc.input = NewFacesVMInput(
            newFacesManager: self.input.newFacesManager,
            actionsManager: self.input.actionsManager,
            profileManager: self.input.profileManager,
            lmmManager: self.input.lmmManager,
            navigationManager: self.input.navigationManager,
            notifications: self.input.notifications,
            location: self.input.location,
            scenario: self.input.scenario,
            transition: self.input.transition,
            filter: self.input.filter,
            externalLinkManager: self.input.externalLinkManager
        )
        
        self.menuVCCache[.discover] = vc
        
        return vc
    }
    
    fileprivate func setupBindings()
    {
        self.viewModel = MainViewModel(self.input)
        self.viewModel?.input.navigationManager.mainItem.skip(1).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] item in
            UIView.performWithoutAnimation {
                self?.select(item.selectionState())
            }
        }).disposed(by: self.disposeBag)
        
        self.viewModel?.availablePhotosCount.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] count in
            self?.profileIndicatorView.isHidden = count != 0
        }).disposed(by: self.disposeBag)
         self.viewModel?.notSeenProfilesTotalCount.observeOn(MainScheduler.instance).subscribe(onNext: { value in
            UIApplication.shared.applicationIconBadgeNumber = value
        }).disposed(by: self.disposeBag)
        
        self.viewModel?.incomingLikesCount.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] count in
            guard let `self` = self else { return }
            
            let countToShow: Int = count - self.preshownLikesCount
            if countToShow > 0 {
                self.preshownLikesCount = 0
            } else {
                self.preshownLikesCount -= count
                
                return
            }
            
            let size = self.likeBtn.bounds.size
            let center = self.likeBtn.convert(CGPoint(x: size.width / 2.0, y: size.height / 2.0), to: nil)
            let position = CGPoint(x: 44.0, y: center.y + 16.0)            
            self.effectsView.animateLikes(countToShow, from: position)
            self.input.achivement.addLikes(countToShow)
            //self.effectsView.animateLikesDelta(countToShow)
        }).disposed(by: self.disposeBag)
        
        self.viewModel?.incomingMatches.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] count in
            guard let `self` = self else { return }
            
            let countToShow: Int = count - self.preshownMatchesCount
            if countToShow > 0 {
                self.preshownMatchesCount = 0
            } else {
                self.preshownMatchesCount -= count
                
                return
            }
            
            let size = self.likeBtn.bounds.size
            let center = self.likeBtn.convert(CGPoint(x: size.width / 2.0, y: size.height / 2.0), to: nil)
            let position = CGPoint(x: 44.0, y: center.y + 16.0)
            self.effectsView.animateMatches(countToShow, from: position)
            self.input.achivement.addLikes(countToShow)
        }).disposed(by: self.disposeBag)
        
        self.viewModel?.incomingMessages.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] count in
            guard let `self` = self else { return }
            
            let countToShow: Int = count - self.preshownMessagesCount
            if countToShow > 0 {
                self.preshownMessagesCount = 0
            } else {
                self.preshownMessagesCount -= count
                
                return
            }
            
            let size = self.likeBtn.bounds.size
            let center = self.likeBtn.convert(CGPoint(x: size.width / 2.0, y: size.height / 2.0), to: self.view)
            let position = CGPoint(x: 44.0, y: center.y + 16.0)
            self.effectsView.animateMessages(countToShow, from: position)
        }).disposed(by: self.disposeBag)
        
        self.input.notifications.notificationData.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] userInfo in
            guard let `self` = self else { return }
            
            guard let typeStr = userInfo["type"] as? String else { return }
            guard let remoteFeed = RemoteFeedType(rawValue: typeStr) else { return }
            guard let profileId = userInfo["oppositeUserId"] as? String else { return }
            guard self.viewModel?.isBlocked(profileId) == false else { return }
            guard ChatViewController.openedProfileId != profileId else { return }
            
            let size = self.likeBtn.bounds.size
            let center = self.likeBtn.convert(CGPoint(x: size.width / 2.0, y: size.height / 2.0), to: self.view)
            let position = CGPoint(x: 44.0, y: center.y + 16.0)
            
            switch remoteFeed {
            case .likesYou:
                self.preshownLikesCount += 1
                self.fireImpact()
                self.effectsView.animateLikes(1, from: position)
                self.input.achivement.addLikes(1)
                
                break
                
            case .matches:
                guard !self.input.lmmManager.messages.value.map({ $0.id }).contains(profileId) else { return }
                
                self.preshownMatchesCount += 1
                self.fireImpact()
                self.input.achivement.addLikes(1)
                self.effectsView.animateMatches(1, from: position)
                
                break
                                
            case .messages:
                if self.viewModel?.isMessageProcessed(profileId) == true { return }
                
                self.preshownMessagesCount += 1
                self.fireImpact()
                self.effectsView.animateMessages(1, from: position)
                
                DispatchQueue.main.async {
                    self.viewModel?.markMessageAsProcessed(profileId)
                }
                
                break
 
            default: return
            }
            
        }).disposed(by: self.disposeBag)

        UIManager.shared.chatModeEnabled.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] state in
            guard let `self` = self else { return }
            
            self.buttonsStackView.isHidden = state
            self.profileIndicatorView.alpha = state ? 0.0 : 1.0
            self.likesYouIndicatorView.alpha = state ? 0.0 : 1.0
            self.bottomShadowView.isHidden = state
            
            if state  {
                self.notificationsBannerView.isHidden = true
            } else {
                if self.input.notifications.isRegistered {
                    self.notificationsBannerView.isHidden = self.input.notifications.isGranted.value || self.isBannerClosedManually
                }
            }
        }).disposed(by: self.disposeBag)
        
        
        UIManager.shared.wakeUpDelayTriggered.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] state in
            guard let `self` = self else { return }
            guard state else { return }
            
            if self.input.notifications.isRegistered {
                self.notificationsBannerView.isHidden = self.input.notifications.isGranted.value
            }
        }).disposed(by: self.disposeBag)
        
        UIManager.shared.blockModeEnabled.asObservable().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] state in
            self?.buttonsStackView.isHidden = state
            self?.profileIndicatorView.alpha = state ? 0.0 : 1.0
            self?.likesYouIndicatorView.alpha = state ? 0.0 : 1.0
            self?.bottomShadowView.isHidden = state
        }).disposed(by: self.disposeBag)
        
        self.input.notifications.responses.asObservable().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] response in
            guard let `self` = self else { return }
            
            let userInfo = response.notification.request.content.userInfo
            guard let typeStr = userInfo["type"] as? String else {
                self.input.navigationManager.mainItem.accept(.searchAndFetch)
                
                return
            }
            
            guard let type = RemoteFeedType(rawValue: typeStr) else { return }
            
            switch type {
            case .unknown: break
            case .likesYou:
                self.input.navigationManager.mainItem.accept(.likes)
                DispatchQueue.main.async {
                    let vc = self.containedVC as? MainLMMContainerViewController
                    vc?.prepareForNavigation()
                    vc?.reload()
                }
                break
                
            case .matches:
                self.input.navigationManager.mainItem.accept(.chats)
                DispatchQueue.main.async {
                    let vc = self.containedVC as? MainLMMContainerViewController
                    vc?.prepareForNavigation()
                    vc?.reload()
                }
                break
            
            case .messages:
                self.input.navigationManager.mainItem.accept(.chats)
                DispatchQueue.main.async {
                    let vc = self.containedVC as? MainLMMContainerViewController
                    //vc?.toggle(.messages)
                    vc?.prepareForNavigation()
                    vc?.reload()
                }
                break
            }
            
        }).disposed(by: self.disposeBag)
        
        self.input.notifications.isGranted.observeOn(MainScheduler.instance).subscribe(onNext:{ [weak self] _ in
            guard let `self` = self else { return }
            guard self.input.notifications.isRegistered else { return }
            guard !UIManager.shared.wakeUpDelayTriggered.value else { return }
            
            self.notificationsBannerView.isHidden = self.input.notifications.isGranted.value || self.isBannerClosedManually
        }).disposed(by: self.disposeBag)
        
        // Counters
        
//        self.input.lmmManager.allLikesYouProfilesCount.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] count in
//            let title: String? = count != 0 ? "\(count)" : nil
//            self?.likeBtn.setTitle(title, for: .normal)
//        }).disposed(by: self.disposeBag)
        
//        self.input.lmmManager.allMessagesProfilesCount.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] count in
//            let title: String? = count != 0 ? "\(count)" : nil
//            self?.chatsBtn.setTitle(title, for: .normal)
//        }).disposed(by: self.disposeBag)
        
        // Not seen profiles indicators
        
        self.input.lmmManager.notSeenLikesYouCount.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] count in
            guard let `self` = self else { return }
            
            self.likesYouIndicatorView.isHidden = count == 0
        }).disposed(by: self.disposeBag)
                
        self.input.lmmManager.notSeenMessagesCount.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] count in
            guard let `self` = self else { return }
            
            self.chatIndicatorView.isHidden = !(count != 0 || self.input.lmmManager.notSeenMatchesCount.value != 0)
        }).disposed(by: self.disposeBag)
        
        self.input.lmmManager.notSeenMatchesCount.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] count in
            guard let `self` = self else { return }
            
            self.chatIndicatorView.isHidden = !(count != 0 || self.input.lmmManager.notSeenMessagesCount.value != 0)
        }).disposed(by: self.disposeBag)
        
        UIManager.shared.lmmRefreshModeEnabled.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] state in
            let alpha: CGFloat = state ? 0.0 : 1.0
            self?.likesYouIndicatorView.alpha = alpha
            self?.chatIndicatorView.alpha = alpha
        }).disposed(by: self.disposeBag)
        
        self.input.achivement.text.skip(1).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] text in
            self?.effectsView.animateAchivementText(text)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func fireImpact()
    {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
            self.input.impact.perform(.light)
        })
    }
}

extension MainNavigationItem
{
    func selectionState() -> SelectionState
    {
        switch self {
        case .search: return .search
        case .likes: return .likes
        case .chats: return .chats
        case .profile: return .profile
        
        case .profileAndFetch: return .profileAndFetch
        case .profileAndPick: return .profileAndPick
        case .profileAndAsk: return .profileAndAsk
        case .searchAndFetch: return .searchAndFetch
        case .searchAndFetchFirstTime: return .searchAndFetchFirstTime
        case .likeAndFetch: return .likeAndFetch
        case .chat(let profileId): return .chat(profileId)
        }
    }
}
