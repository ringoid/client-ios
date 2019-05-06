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

enum SelectionState {
    case search
    case like
    case profile
    case messages
    
    case searchAndFetch
    case profileAndPick
    case profileAndFetch
    case likeAndFetch
}

class MainViewController: BaseViewController
{
    var input: MainVMInput!
    var defaultState: SelectionState = .like
    
    fileprivate var viewModel: MainViewModel?
    fileprivate var containerVC: ContainerViewController!
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    fileprivate var menuVCCache: [SelectionState: UIViewController] = [:]
    
    @IBOutlet fileprivate weak var searchBtn: UIButton!
    @IBOutlet fileprivate weak var likeBtn: UIButton!
    @IBOutlet fileprivate weak var profileBtn: UIButton!
    @IBOutlet fileprivate weak var messagesBtn: UIButton!
    @IBOutlet fileprivate weak var profileIndicatorView: UIView!
    @IBOutlet fileprivate weak var lmmNotSeenIndicatorView: UIView!
    @IBOutlet fileprivate weak var messagesNotSeenIndicatorView: UIView!
    @IBOutlet fileprivate weak var effectsView: MainEffectsView!
    @IBOutlet fileprivate weak var buttonsStackView: UIView!
    @IBOutlet fileprivate weak var bottomShadowView: UIView!
    
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
        
//        #if STAGE
//        let recognizer = UITapGestureRecognizer(target: self, action: #selector(showDebugLikes))
//        recognizer.numberOfTapsRequired = 3
//        self.likeBtn.gestureRecognizers = [recognizer]
//        #endif
    }
    
    #if STAGE
    @objc func showDebugLikes()
    {
        let alertVC = UIAlertController(title: "Simulate likes", message: nil, preferredStyle: .alert)
        alertVC.addTextField(configurationHandler: { textField in
            textField.keyboardType = .numberPad
        })
        alertVC.addAction(UIAlertAction(title: "Simulate", style: .default, handler: { _ in
            guard let text = alertVC.textFields?.first?.text, let count = Int(text) else { return }
            
            let size = self.likeBtn.bounds.size
            let center = CGPoint(x: size.width - 25.0, y: size.height / 2.0 - 30.0)
            let position = self.likeBtn.convert(center, to: nil)
            self.effectsView.animateLikes(count, from: position)
            self.effectsView.animateMatches(Int(Double(count) / 5.0), from: position)
            self.effectsView.animateMessages(Int(Double(count) / 10.0), from: position)
        }))
        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        
        self.present(alertVC, animated: true, completion: nil)
    }
    #endif
    
    override func updateTheme()
    {
        self.view.backgroundColor = BackgroundColor().uiColor()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "embed_container"
        {
            self.containerVC = segue.destination as? ContainerViewController
        }
    }
    
    @IBAction func onSearchSelected()
    {
        self.viewModel?.moveToSearch()
    }
    
    @IBAction func onLikeSelected()
    {
        self.viewModel?.moveToLike()
    }
    
    @IBAction func onProfileSelected()
    {
        self.viewModel?.moveToProfile()
    }
    
    @IBAction func onMessagesSelected()
    {
        self.viewModel?.moveToMessages()
    }
    
    // MARK: -
    
    fileprivate func select(_ to: SelectionState)
    {
        self.input.actionsManager.commit()
        
        switch to {
        case .search:
            self.searchBtn.setImage(UIImage(named: "main_bar_search_selected"), for: .normal)
            self.likeBtn.setImage(UIImage(named: "main_bar_like"), for: .normal)
            self.profileBtn.setImage(UIImage(named: "main_bar_profile"), for: .normal)
            self.messagesBtn.setImage(UIImage(named: "main_bar_messages"), for: .normal)
            self.embedNewFaces()
            break
            
        case .like:
            self.searchBtn.setImage(UIImage(named: "main_bar_search"), for: .normal)
            self.likeBtn.setImage(UIImage(named: "main_bar_like_selected"), for: .normal)
            self.profileBtn.setImage(UIImage(named: "main_bar_profile"), for: .normal)
            self.messagesBtn.setImage(UIImage(named: "main_bar_messages"), for: .normal)
            self.embedMainLMM()
            break
            
        case .profile:
            self.messagesBtn.setImage(UIImage(named: "main_bar_messages"), for: .normal)
            self.searchBtn.setImage(UIImage(named: "main_bar_search"), for: .normal)
            self.likeBtn.setImage(UIImage(named: "main_bar_like"), for: .normal)
            self.profileBtn.setImage(UIImage(named: "main_bar_profile_selected"), for: .normal)
            self.embedUserProfile()
            break
            
        case .messages:
            self.searchBtn.setImage(UIImage(named: "main_bar_search"), for: .normal)
            self.likeBtn.setImage(UIImage(named: "main_bar_like"), for: .normal)
            self.profileBtn.setImage(UIImage(named: "main_bar_profile"), for: .normal)
            self.messagesBtn.setImage(UIImage(named: "main_bar_messages_selected"), for: .normal)
            self.embedMessages()
            break
            
        case .profileAndPick:
            self.searchBtn.setImage(UIImage(named: "main_bar_search"), for: .normal)
            self.likeBtn.setImage(UIImage(named: "main_bar_like"), for: .normal)
            self.profileBtn.setImage(UIImage(named: "main_bar_profile_selected"), for: .normal)
            self.messagesBtn.setImage(UIImage(named: "main_bar_messages"), for: .normal)
            self.embedUserProfileAndPick()
            break
            
        case .profileAndFetch:
            self.searchBtn.setImage(UIImage(named: "main_bar_search"), for: .normal)
            self.likeBtn.setImage(UIImage(named: "main_bar_like"), for: .normal)
            self.profileBtn.setImage(UIImage(named: "main_bar_profile_selected"), for: .normal)
            self.messagesBtn.setImage(UIImage(named: "main_bar_messages"), for: .normal)
            self.embedUserProfileAndFetch()
            break
            
        case .searchAndFetch:
            self.searchBtn.setImage(UIImage(named: "main_bar_search_selected"), for: .normal)
            self.likeBtn.setImage(UIImage(named: "main_bar_like"), for: .normal)
            self.profileBtn.setImage(UIImage(named: "main_bar_profile"), for: .normal)
            self.messagesBtn.setImage(UIImage(named: "main_bar_messages"), for: .normal)
            self.embedNewFacesAndFetch()
            break
            
        case .likeAndFetch:
            self.searchBtn.setImage(UIImage(named: "main_bar_search"), for: .normal)
            self.likeBtn.setImage(UIImage(named: "main_bar_like_selected"), for: .normal)
            self.profileBtn.setImage(UIImage(named: "main_bar_profile"), for: .normal)
            self.messagesBtn.setImage(UIImage(named: "main_bar_messages"), for: .normal)
            self.embedMainLMMAndFetch()
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
        
        self.containerVC.embed(vc)
        DispatchQueue.main.async {
            vc.reload()
        }
    }
    
    fileprivate func embedMainLMM()
    {
        guard let vc = self.getMainLMMVC() else { return }
        self.containerVC.embed(vc)
    }
    
    fileprivate func embedMessages()
    {
        guard let vc = self.getMessages() else { return }
        self.containerVC.embed(vc)
    }
    
    fileprivate func embedUserProfile()
    {
        guard let vc = self.getUserProfileVC() else { return }
        
        self.containerVC.embed(vc)
    }
    
    fileprivate func embedUserProfileAndPick()
    {
        guard let vc = self.getUserProfileVC() else { return }
        
        self.containerVC.embed(vc)
        
        vc.showPhotoPicker()
    }
    
    fileprivate func embedUserProfileAndFetch()
    {
        guard let vc = self.getUserProfileVC() else { return }
        
        self.containerVC.embed(vc)
        
        vc.reload()
    }
    
    fileprivate func embedMainLMMAndFetch()
    {
        guard let vc = self.getMainLMMVC() else { return }
        
        self.containerVC.embed(vc)
        
        DispatchQueue.main.async {
            vc.reload()
        }
    }
    
    fileprivate func getMainLMMVC() -> MainLMMContainerViewController?
    {
        if let vc = self.menuVCCache[.like] {
            self.containerVC.embed(vc)
            
            return nil
        }
        
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
            transition: self.input.transition
        )
        
        self.menuVCCache[.like] = vc
        
        return vc
    }
    
    fileprivate func getMessages() -> MainLMMMessagesContainerViewController?
    {
        if let vc = self.menuVCCache[.messages] {
            self.containerVC.embed(vc)
            
            return nil
        }
        
        let storyboard = Storyboards.mainLMM()
        guard let vc = storyboard.instantiateViewController(withIdentifier: "messages_vc") as? MainLMMMessagesContainerViewController else { return nil }
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
            transition: self.input.transition
        )
        
        self.menuVCCache[.messages] = vc
        
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
            scenario: self.input.scenario
        )
        
        self.menuVCCache[.profile] = vc
        
        return vc
    }
    
    fileprivate func getNewFacesVC() -> NewFacesViewController?
    {
        if let vc = self.menuVCCache[.search] as? NewFacesViewController { return vc }
        
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
            transition: self.input.transition
        )
        
        self.menuVCCache[.search] = vc
        
        return vc
    }
    
    fileprivate func setupBindings()
    {
        self.viewModel = MainViewModel(self.input)
        self.viewModel?.input.navigationManager.mainItem.skip(1).asObservable().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] item in
            self?.select(item.selectionState())
        }).disposed(by: self.disposeBag)
        
        self.viewModel?.availablePhotosCount.subscribe(onNext: { [weak self] count in
            self?.profileIndicatorView.isHidden = count != 0
        }).disposed(by: self.disposeBag)
        
        self.viewModel?.isNotSeenProfilesAvailable.asObservable().subscribe(onNext: { [weak self] state in
            self?.lmmNotSeenIndicatorView.isHidden = !state
        }).disposed(by: self.disposeBag)
        
        self.viewModel?.isNotSeenInboxAvailable.asObservable().subscribe(onNext: { [weak self] state in
            self?.messagesNotSeenIndicatorView.isHidden = !state
        }).disposed(by: self.disposeBag)
        
        self.viewModel?.incomingLikesCount.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] count in
            guard let `self` = self else { return }
            
            let size = self.likeBtn.bounds.size
            let center = CGPoint(x: size.width - 25.0, y: size.height / 2.0 - 30.0)
            let position = self.likeBtn.convert(center, to: nil)
            self.effectsView.animateLikes(count, from: position)
        }).disposed(by: self.disposeBag)
        
        self.viewModel?.incomingMatches.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] count in
            guard let `self` = self else { return }
            
            let size = self.likeBtn.bounds.size
            let center = CGPoint(x: size.width - 25.0, y: size.height / 2.0 - 30.0)
            let position = self.likeBtn.convert(center, to: nil)
            self.effectsView.animateMatches(count, from: position)
        }).disposed(by: self.disposeBag)
        
        self.viewModel?.incomingHellos.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] count in
            guard let `self` = self else { return }
            
            let size = self.likeBtn.bounds.size
            let center = CGPoint(x: size.width - 25.0, y: size.height / 2.0 - 30.0)
            let position = self.likeBtn.convert(center, to: nil)
            self.effectsView.animateMessages(count, from: position)
        }).disposed(by: self.disposeBag)
        
        self.viewModel?.incomingInbox.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] count in
            guard let `self` = self else { return }
            
            let size = self.messagesBtn.bounds.size
            let center = CGPoint(x: size.width - 25.0, y: size.height / 2.0 - 30.0)
            let position = self.messagesBtn.convert(center, to: nil)
            self.effectsView.animateMessages(count, from: position)
        }).disposed(by: self.disposeBag)
        
        UIManager.shared.lmmRefreshModeEnabled.asObservable().subscribe(onNext: { [weak self] state in
            let alpha:CGFloat = state ? 0.0 : 1.0            
            self?.lmmNotSeenIndicatorView.alpha = alpha
            self?.messagesNotSeenIndicatorView.alpha = alpha
        }).disposed(by: self.disposeBag)
        
        UIManager.shared.chatModeEnabled.asObservable().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] state in
            self?.buttonsStackView.isHidden = state
            self?.profileIndicatorView.alpha = state ? 0.0 : 1.0
            self?.lmmNotSeenIndicatorView.alpha = state ? 0.0 : 1.0
            self?.messagesNotSeenIndicatorView.alpha = state ? 0.0 : 1.0
            self?.bottomShadowView.isHidden = state
        }).disposed(by: self.disposeBag)
        
        UIManager.shared.blockModeEnabled.asObservable().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] state in
            self?.buttonsStackView.isHidden = state
            self?.profileIndicatorView.alpha = state ? 0.0 : 1.0
            self?.lmmNotSeenIndicatorView.alpha = state ? 0.0 : 1.0
            self?.messagesNotSeenIndicatorView.alpha = state ? 0.0 : 1.0
            self?.bottomShadowView.isHidden = state
        }).disposed(by: self.disposeBag)
    }
}

extension MainNavigationItem
{
    func selectionState() -> SelectionState
    {
        switch self {
        case .search: return .search
        case .like: return .like
        case .profile: return .profile
        case .messages: return .messages
        
        case .profileAndFetch: return .profileAndFetch
        case .profileAndPick: return .profileAndPick
        case .searchAndFetch: return .searchAndFetch
        case .likeAndFetch: return .likeAndFetch
        }
    }
}
