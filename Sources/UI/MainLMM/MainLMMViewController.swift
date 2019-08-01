//
//  MainLMMViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 14/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa
import Nuke

fileprivate struct FeedState
{
    var offset: CGFloat = 0.0
}

fileprivate enum LMMFeedActivityState
{
    case initial;
    case fetching
    case empty
    case contentAvailable
}

class MainLMMViewController: BaseViewController
{
    var input: MainLMMVMInput!
    var type: BehaviorRelay<LMMType> = BehaviorRelay<LMMType>(value: .likesYou)
    
    fileprivate static var feedsState: [LMMType: FeedState] = [
        .likesYou: FeedState(),        
        .messages: FeedState(),
        .inbox: FeedState(),
        .sent: FeedState()
    ]
    
    fileprivate static var photoIndexes: [String: Int] = [:]
    fileprivate var isDragged: Bool = false    
    
    fileprivate var viewModel: MainLMMViewModel?
    fileprivate var feedDisposeBag: DisposeBag = DisposeBag()
    fileprivate var disposeBag: DisposeBag = DisposeBag()
    fileprivate var prevScrollingOffset: CGFloat = 0.0
    fileprivate var isScrollTopVisible: Bool = false
    fileprivate var isChatShown: Bool = false
    fileprivate var lastFeedIds: [String] = []
    fileprivate var lastUpdateFeedType: LMMType = .likesYou
    fileprivate var currentActivityState: LMMFeedActivityState = .initial
    fileprivate let preheater = ImagePreheater(destination: .diskCache)
    fileprivate var isTabSwitched: Bool = false
    fileprivate var isUpdateBtnVisible: Bool = false
    
    @IBOutlet fileprivate weak var emptyFeedLabel: UILabel!
    @IBOutlet fileprivate weak var feedTitleLabel: UILabel!
    @IBOutlet fileprivate weak var chatContainerView: ContainerView!
    @IBOutlet fileprivate weak var scrollTopBtn: UIButton!
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet fileprivate weak var emptyFeedActivityView: UIActivityIndicatorView!
    @IBOutlet fileprivate weak var blockContainerView: UIView!
    @IBOutlet fileprivate weak var blockPhotoView: UIImageView!
    @IBOutlet fileprivate weak var blockPhotoAspectConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var updateBtn: UIButton!
    @IBOutlet fileprivate weak var tapBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var topBarOffsetConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var feedBottomView: UIView!
    @IBOutlet fileprivate weak var feedBottomLabel: UILabel!
    @IBOutlet fileprivate weak var feedTitleBtn: UIButton!
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        self.toggleActivity(.initial)
        
        self.tableView.estimatedSectionHeaderHeight = 0.0
        self.tableView.estimatedSectionFooterHeight = 0.0
        
        let cellHeight = UIScreen.main.bounds.width * AppConfig.photoRatio
        self.tableView.rowHeight = cellHeight
        self.tableView.estimatedRowHeight = cellHeight
        self.tableView.contentInset = UIEdgeInsets(
            top: 64.0,
            left: 0.0,
            bottom: UIScreen.main.bounds.height - cellHeight,
            right: 0.0
        )
        self.tableView.tableFooterView = self.feedBottomView
        
        self.blockPhotoAspectConstraint.constant = AppConfig.photoRatio

        UIManager.shared.blockModeEnabled.accept(false)
        UIManager.shared.chatModeEnabled.accept(false)

        self.setupBindings()
        self.setupReloader()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        self.feedTitleLabel.isHidden = true
        self.isTabSwitched = true
        self.updateFeed(true)
        self.checkForUpdates()            
        self.showTopBar(false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.isTabSwitched = false
        self.feedTitleLabel.isHidden = false
    }
    
    override func viewWillLayoutSubviews()
    {
        super.viewWillLayoutSubviews()
        
        self.tapBarHeightConstraint.constant = self.view.safeAreaInsets.top + 64.0
    }
    
    override func updateTheme()
    {
        self.view.backgroundColor = BackgroundColor().uiColor()
        self.blockContainerView.backgroundColor = BackgroundColor().uiColor()
    }
    
    override func updateLocale()
    {
        self.toggleActivity(self.currentActivityState)
        self.updateFeedTitle()
        
        self.updateBtn.setTitle("feed_tap_to_refresh".localized(), for: .normal)
    }
    
    fileprivate var isInitialLayout: Bool = true    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
        // Applying offset after view size is set
        guard isInitialLayout else { return }
        
        self.isInitialLayout = false
        self.updateFeed(true)
    }
    
    // MARK: - Actions
    
    @IBAction func onScrollTop()
    {
        self.hideScrollToTopOption()
        self.showTopBar(true)
        self.updateBtn.alpha = 1.0
        let topOffset = self.view.safeAreaInsets.top + self.tableView.contentInset.top
        self.tableView.setContentOffset(CGPoint(x: 0.0, y: -topOffset), animated: false)
        MainLMMViewController.feedsState[self.type.value]?.offset = 0.0
        self.input.actionsManager.commit()
    }
    
    @IBAction func onRefresh()
    {
        AnalyticsManager.shared.send(.tapToRefresh(self.type.value.sourceType().rawValue))
        
        self.hideScrollToTopOption()
        self.showTopBar(true)
        self.reload(true)
    }
    
    @IBAction func onShowFilter()
    {
        self.showFilter()
    }
    
    @IBAction func onShowFilterFromBottom()
    {
        // TODO: add proper model check
        guard self.feedBottomLabel.text != nil else { return }
        
        self.showFilter()
        self.showTopBar(true)
    }
    
    @IBAction func onShowFilterFromEmptyFeed()
    {
        self.showFilter()
        self.showTopBar(true)
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.viewModel = MainLMMViewModel(self.input)

        self.type.asObservable().subscribe(onNext:{ [weak self] type in
            self?.toggle(type)
        }).disposed(by: self.disposeBag)
        
        self.viewModel?.isFetching.asObservable().skip(1).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] state in
            if state {
                MainLMMViewController.resetStates()
                self?.toggleActivity(.fetching)
                self?.tableView.dataSource = EmptyFeed.shared
                self?.lastFeedIds.removeAll()
                self?.tableView.reloadData()
                self?.updateBtn.isHidden = true
                self?.isUpdateBtnVisible = false
                UIManager.shared.lmmRefreshModeEnabled.accept(true)
            } else {
                UIManager.shared.lmmRefreshModeEnabled.accept(false)
                let isEmpty = self?.profiles()?.value.count == 0
                self?.toggleActivity(isEmpty ? .empty : .contentAvailable)
                self?.tableView.dataSource = self
                self?.updateFeed(true)
                self?.checkForUpdates()
            }
        }).disposed(by: self.disposeBag)
        
        UIManager.shared.feedsFabShouldBeHidden.asObservable().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] state in
            guard state else { return }
            
            self?.hideScrollToTopOption()
            self?.updateBtn.alpha = 0.0
        }).disposed(by: self.disposeBag)
        
        UIManager.shared.lcTopBarShouldBeHidden.asObservable().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] state in
            guard let `self` = self else { return }
            guard state else { return }
            guard self.tableView.contentOffset.y > topTrashhold else { return }
            
            self.hideTopBar()
        }).disposed(by: self.disposeBag)
        
        self.input.transition.destination.subscribe(onNext: { feedType in
            guard let lmmType = feedType.lmmType() else { return }
            
            MainLMMViewController.feedsState[lmmType] = FeedState()
        }).disposed(by: self.disposeBag)
        
        self.input.chatManager.lastSentProfileId.subscribe(onNext: { [weak self] profileId in
            guard let id = profileId else { return }
            
            MainLMMViewController.feedsState[.sent] = FeedState()
            self?.input.lmmManager.topOrder(id, type: .sent)
        }).disposed(by: self.disposeBag)
        
        self.input.lmmManager.likesYouUpdatesAvailable.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self ] _ in
            guard self?.type.value == .likesYou else { return }
            
            self?.checkForUpdates()
        }).disposed(by: self.disposeBag)
                
        self.input.lmmManager.messagesUpdatesAvailable.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self ] _ in
            guard self?.type.value == .messages else { return }
            
            self?.checkForUpdates()
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func updateBindings()
    {
        self.feedDisposeBag = DisposeBag()
        self.profiles()?.asObservable().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
            if let type = self?.type.value, type == .inbox || type == .sent {
                self?.updateFeed(true)
                
                return
            }
            
            self?.updateFeedTitle()
            self?.updateFeed(false)
            self?.feedBottomLabel.text = self?.bottomLabelTitle()
        }).disposed(by: self.feedDisposeBag)
        
        if self.type.value == .likesYou {
            self.input.lmmManager.allLikesYouProfilesCount.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                guard self.type.value == .likesYou else { return }
                
                self.updateFeedLabel()
            }).disposed(by: self.feedDisposeBag)
            
            self.input.lmmManager.filteredLikesYouProfilesCount.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                guard self.type.value == .likesYou else { return }
                
                self.updateFeedLabel()
                self.updateFeedTitle()
            }).disposed(by: self.feedDisposeBag)
        }
        
        if self.type.value == .messages {
            self.input.lmmManager.allMessagesProfilesCount.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                guard self.type.value == .messages else { return }
                
                self.updateFeedLabel()
            }).disposed(by: self.feedDisposeBag)
            
            self.input.lmmManager.filteredMessagesProfilesCount.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                guard self.type.value == .messages else { return }
                
                self.updateFeedLabel()
                self.updateFeedTitle()
            }).disposed(by: self.feedDisposeBag
            )
        }
    }
    
    fileprivate func setupReloader()
    {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        self.tableView.refreshControl = refreshControl
    }
    
    func prepareForNavigation()
    {
        self.presentedViewController?.dismiss(animated: false, completion: nil)
        
        self.isChatShown = false
        self.chatContainerView.isHidden = true
        self.chatContainerView.remove()
        self.blockContainerView.isHidden = true
        
        self.onScrollTop()
        
        UIManager.shared.blockModeEnabled.accept(false)
        UIManager.shared.chatModeEnabled.accept(false)
    }
    
    func reload(_ isFilterEnabled: Bool)
    {
        AnalyticsManager.shared.send(.pullToRefresh(self.type.value.sourceType().rawValue))
        
        self.input.lmmManager.likesYouUpdatesAvailable.accept(false)
        self.input.lmmManager.matchesUpdatesAvailable.accept(false)
        self.input.lmmManager.messagesUpdatesAvailable.accept(false)
        
        self.tableView.panGestureRecognizer.isEnabled = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.tableView.refreshControl?.endRefreshing()
        }
        
        guard self.viewModel?.isLocationDenied != true else {
            self.showLocationsSettingsAlert()
            self.tableView.panGestureRecognizer.isEnabled = true
            
            return
        }
        
        guard self.viewModel?.registerLocationsIfNeeded() == true else {
            self.tableView.panGestureRecognizer.isEnabled = true
            
            return
        }
        
        if self.viewModel?.isPhotosAdded == false {
            self.showAddPhotosOptions()
            self.tableView.panGestureRecognizer.isEnabled = true
            
            return
        }
        
        self.viewModel?.registerPushesIfNeeded()
        
        // TODO: move "finishViewActions" logic inside view model
        self.input.actionsManager.finishViewActions(for: self.profiles()?.value ?? [], source: self.type.value.sourceType())
        
        self.viewModel?.refresh(self.type.value, isFilterEnabled: isFilterEnabled).subscribe(
            onNext: { [weak self ] _ in
                self?.tableView.panGestureRecognizer.isEnabled = true                
            }, onError:{ [weak self] error in
                guard let `self` = self else { return }
                
                self.tableView.panGestureRecognizer.isEnabled = true
                showError(error, vc: self)
        }).disposed(by: self.disposeBag)
        
        if isFilterEnabled {
            self.input.newFacesManager.refreshInBackground()
        }
    }
    
    fileprivate func toggle(_ type: LMMType)
    {
        self.input.actionsManager.commit()
        
        self.updateFeedTitle()
        self.updateBindings()
        
        self.checkForUpdates()
    }
    
    fileprivate func updateFeedTitle()
    {
        switch self.type.value {
        case .likesYou:
            var title = "lmm_tab_likes".localized()
            if let count = self.profiles()?.value.count {
                if count != self.input.lmmManager.allLikesYouProfilesCount.value {
                    title += String(format: "filter_range".localized(), count, self.input.lmmManager.allLikesYouProfilesCount.value)
                } else if self.input.lmmManager.allLikesYouProfilesCount.value != 0 {
                    title += " (\(count))"
                }
            }
            
            self.feedTitleLabel.text = title
            break
            
        case .messages:
            var title = "lmm_tab_messages".localized()
            if let count = self.profiles()?.value.count {
                if count != self.input.lmmManager.allMessagesProfilesCount.value {
                title += String(format: "filter_range".localized(), count, self.input.lmmManager.allMessagesProfilesCount.value)
                } else if self.input.lmmManager.allMessagesProfilesCount.value != 0 {
                    title += " (\(count))"
                }
            }
            
            self.feedTitleLabel.text = title
            break
            
        default: return
        }
    }
    
    fileprivate func profiles() -> BehaviorRelay<[LMMProfile]>?
    {
        switch self.type.value {
        case .likesYou:
            return self.viewModel?.likesYou
            
        case .messages:
            return self.viewModel?.messages
            
        case .inbox:
            return self.viewModel?.inbox
            
        case .sent:
            return self.viewModel?.sent
        }
    }
    
    fileprivate func isUpdatesAvailable() -> Bool
    {
        switch self.type.value {
        case .likesYou: return self.input.lmmManager.likesYouUpdatesAvailable.value
        case .messages:
            let isUpdated = self.input.lmmManager.messagesUpdatesAvailable.value ||
                self.input.lmmManager.matchesUpdatesAvailable.value
            return isUpdated
            
        default: return false
        }
    }
    
    fileprivate func updateFeed(_ force: Bool)
    {
        guard self.tableView.dataSource !== EmptyFeed.shared else { return }
        guard !self.isChatShown else { return } // Chat updates should not reload feed
        
        guard let updatedProfiles = self.profiles()?.value.filter({ !$0.isInvalidated }) else { return }
        
        // Analytics
        if self.type.value == .likesYou && updatedProfiles.count > 0 {
            self.input.scenario.checkLikesYou(self.type.value.sourceType())
        }
        
        defer {
            self.lastFeedIds = updatedProfiles.map { $0.id }
            self.lastUpdateFeedType = self.type.value
            
            let offset = self.tableView.contentOffset.y
            self.updateVisibleCellsBorders(offset)
            self.input.transition.afterTransition = false
        }
        
        let totalCount = updatedProfiles.count
        let isEmpty = updatedProfiles.isEmpty
        
        if isEmpty && self.currentActivityState != .fetching {
            if self.currentActivityState == .contentAvailable {
                self.toggleActivity(.initial)
            } else if self.currentActivityState != .initial{
                self.toggleActivity(.empty)
            }
        }
        
        if !isEmpty {
            self.toggleActivity(.contentAvailable)
        }

        // Checking for blocking scenario
        if totalCount == self.lastFeedIds.count - 1, (self.lastFeedIds.count > 1 || self.input.transition.afterTransition), self.lastUpdateFeedType == self.type.value {
            var diffCount: Int = 0
            var diffIndex: Int = 0
            var j: Int = 0
            
            for i in 0..<totalCount {
                let profile = updatedProfiles[i]
                if profile.isInvalidated { break } // Deprecated profiles
                if j >= self.lastFeedIds.count { break }

                if profile.id != self.lastFeedIds[j] {
                    diffIndex = i
                    diffCount += 1
                    j = j + 1
                }
                
                j = j + 1
            }
            
            // Blocking scenario confirmed
            if diffCount == 1 {
                self.tableView.performBatchUpdates({
                    self.tableView.deleteRows(at: [IndexPath(row: diffIndex, section: 0)], with: .top)
                }, completion: nil)
                self.tableView.layer.removeAllAnimations()

                return
            } else if diffCount == 0 { // Last profile should be removed
                if totalCount > 0 {
                    self.tableView.isUserInteractionEnabled = false
                    self.tableView.scrollToRow(at:  IndexPath(row: totalCount - 1, section: 0), at: .top, animated: true)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    self.tableView.isUserInteractionEnabled = true
                    
                    if self.profiles()?.value.count == totalCount - 1 {
                        self.tableView.performBatchUpdates({
                            self.tableView.deleteRows(at: [IndexPath(row: totalCount, section: 0)], with: .top)
                        }, completion: nil)
                    } else {
                        self.tableView.reloadData()
                    }
                }
                
                return
            }
            
            // Returning to default scenario
        }
        
        // No changes scenario check
        if  totalCount > 0, self.lastFeedIds.count == totalCount {
            var checkIds = self.lastFeedIds
            updatedProfiles.forEach { profile in
                guard let index = checkIds.firstIndex(of: profile.id) else { return }
                
                checkIds.remove(at: index)
            }
            
            if checkIds.count == 0 && !force { return }
        }
        
        // Default scenario - reloading and applying stored offset
        let offset = MainLMMViewController.feedsState[self.type.value]?.offset
        
        self.tableView.reloadData()
        if var cachedOffset = offset {
            if abs(cachedOffset) < 0.1 {
                cachedOffset = -1.0 * (self.view.safeAreaInsets.top + self.tableView.contentInset.top)
            }
            
            self.tableView.layoutIfNeeded()
            self.tableView.setContentOffset(CGPoint(x: 0.0, y: cachedOffset), animated: false)
            
            if cachedOffset > 75.0 && totalCount > 0 && totalCount > 0{
                self.scrollTopBtn.alpha = 1.0
                self.isScrollTopVisible = true
            } else {
                self.scrollTopBtn.alpha = 0.0
                self.isScrollTopVisible = false
            }
        }
    }
    
    fileprivate func checkForUpdates()
    {
        guard self.viewModel?.isFetching.value == false else {
            self.updateBtn.alpha = 1.0
            self.isUpdateBtnVisible = false
            self.updateBtn.isHidden = true
            
            return
        }
        
        if self.isUpdatesAvailable() {
            guard !self.isUpdateBtnVisible || self.updateBtn.alpha < 1.0 else { return }
            
            self.updateBtn.alpha = 1.0
            self.updateBtn.isHidden = false
            self.isUpdateBtnVisible = true
        } else {
            guard self.isUpdateBtnVisible else { return }
            
            self.updateBtn.isHidden = true
            self.isUpdateBtnVisible = false
        }
    }
    
    fileprivate func showChat(_ profile: LMMProfile, photo: Photo, indexPath: IndexPath, profileVC: MainLMMProfileViewController?)
    {
        self.isChatShown = true
        let photoId = photo.id
        if let actionProfile = profile.actionInstance(),
            let actionPhoto = actionProfile.orderedPhotos().filter({ $0.id == photoId }).first {
            
            self.input.actionsManager.stopViewAction(actionProfile, photo: actionPhoto, sourceType: self.type.value.sourceType())
            self.input.actionsManager.startViewChatAction(actionProfile, photo: actionPhoto, sourceType: self.type.value.sourceType())
        }
        
        let vc = ChatViewController.create()
        vc.input = ChatVMInput(
            profile: profile,
            photo: photo,
            source: self.type.value.sourceType(),
            chatManager: self.input.chatManager,
            lmmManager: self.input.lmmManager,
            scenario: self.input.scenario,
            transition: self.input.transition
            , onClose: { [weak self] in
                self?.hideChat(profileVC, profile: profile, photo: photo, indexPath: indexPath)
            }, onBlock: { [weak profileVC] in
                profileVC?.block(true)
        })
  
        self.chatContainerView.embed(vc, to: self)
        self.chatContainerView.isHidden = false
                
        self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
        profileVC?.hideNotChatControls()
    }
    
    fileprivate func hideChat(_ profileVC: MainLMMProfileViewController?, profile: LMMProfile, photo: Photo, indexPath: IndexPath)
    {
        let photoId = photo.id
        if let actionProfile = profile.actionInstance(),
            let actionPhoto = actionProfile.orderedPhotos().filter({ $0.id == photoId }).first {
            self.input.actionsManager.stopViewChatAction(actionProfile, photo: actionPhoto, sourceType: self.type.value.sourceType())
            self.input.actionsManager.startViewAction(actionProfile, photo: actionPhoto, sourceType: self.type.value.sourceType())
        }
        profileVC?.showNotChatControls()
        
        self.chatContainerView.isHidden = true
        self.chatContainerView.remove()

        self.isChatShown = false
    }
    
    fileprivate func showScrollToTopOption()
    {
        guard !self.isScrollTopVisible else { return }
        guard self.profiles()?.value.count != 0 else { return }
        
        let topAnimator = UIViewPropertyAnimator(duration: 0.1, curve: .linear) {
            self.scrollTopBtn.alpha = 1.0
        }
        topAnimator.addCompletion { _ in
            self.isScrollTopVisible = true
        }
        
        topAnimator.startAnimation()
        
        guard self.viewModel?.isFetching.value == false else { return }
        
        self.updateBtn.alpha = 1.0
    }
    
    fileprivate func hideScrollToTopOption()
    {
        guard self.isScrollTopVisible else { return }
        
        let animator = UIViewPropertyAnimator(duration: 0.15, curve: .linear) {
            self.scrollTopBtn.alpha = 0.0
        }
        animator.addCompletion { _ in
            self.isScrollTopVisible = false
        }
        
        animator.startAnimation()
    }
    
    static func resetStates()
    {
        MainLMMViewController.photoIndexes = [:]
        MainLMMViewController.feedsState = [
            .likesYou: FeedState(offset: 0.0),
            .messages: FeedState(offset: 0.0),
            .inbox: FeedState(offset: 0.0),
            .sent: FeedState(offset: 0.0)
        ]
    }
    
    fileprivate func scrollTop(to index: Int, offset: CGFloat, animated: Bool)
    {
        let height = UIScreen.main.bounds.width * AppConfig.photoRatio
        let topOffset = self.view.safeAreaInsets.top

        self.tableView.setContentOffset(CGPoint(x: 0.0, y: CGFloat(index) * height - topOffset - offset), animated: animated)
    }
    
    fileprivate func showAddPhotosOptions()
    {
        let alertVC = UIAlertController(
            title: nil,
            message: "feed_lmm_dialog_no_user_photo_description".localized(),
            preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "button_add_photo".localized(), style: .default, handler: { [weak self] _ in
            self?.viewModel?.moveToProfile()
        }))
        alertVC.addAction(UIAlertAction(title: "button_later".localized(), style: .cancel, handler: nil))
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
    fileprivate func toggleActivity(_ state: LMMFeedActivityState)
    {
        self.currentActivityState = state
        
        switch state {
        case .initial:
            self.emptyFeedActivityView.stopAnimating()
            self.emptyFeedLabel.text = self.initialLabelTitle()
            self.emptyFeedLabel.isHidden = false
            self.feedTitleBtn.isHidden = false
            self.feedBottomLabel.text = nil
            break
            
        case .fetching:
            self.emptyFeedActivityView.startAnimating()
            self.emptyFeedLabel.isHidden = true
            self.feedTitleBtn.isHidden = true
            self.feedBottomLabel.text = nil
            break
            
        case .empty:
            self.emptyFeedActivityView.stopAnimating()
            self.emptyFeedLabel.text = self.emptyLabelTitle()
            self.emptyFeedLabel.isHidden = false
            self.feedTitleBtn.isHidden = false
            break
            
        case .contentAvailable:
            self.emptyFeedActivityView.stopAnimating()
            self.emptyFeedLabel.isHidden = true
            self.feedTitleBtn.isHidden = true
            break
        }                
    }
    
    fileprivate func emptyLabelTitle() -> String
    {
        guard !self.isTabSwitched else {
            return self.initialLabelTitle()
        }
        
        switch self.type.value {
        case .likesYou:
            let totalCount = self.input.lmmManager.allLikesYouProfilesCount.value
            if let count = self.profiles()?.value.count, totalCount != count {
                return String(format: "feed_profiles_filtered".localized(), totalCount - count)
            }
            
            return "feed_likes_you_empty_no_data".localized()
            
        case .messages:
            let totalCount = self.input.lmmManager.allMessagesProfilesCount.value
            if let count = self.profiles()?.value.count, totalCount != count {
                return String(format: "feed_profiles_filtered".localized(), totalCount - count)
            }
            
            return "feed_messages_empty_no_data".localized()
            
        default: return ""
        }
    }
    
    fileprivate func bottomLabelTitle() -> String?
    {
        switch self.type.value {
        case .likesYou:
            let totalCount = self.input.lmmManager.allLikesYouProfilesCount.value
            if let count = self.profiles()?.value.count, totalCount != count, count != 0 {
                return String(format: "feed_profiles_filtered".localized(), totalCount - count)
            }
            
            return nil
            
        case .messages:
            let totalCount = self.input.lmmManager.allMessagesProfilesCount.value
            if let count = self.profiles()?.value.count, totalCount != count, count != 0 {
                return String(format: "feed_profiles_filtered".localized(), totalCount - count)
            }
            
            return nil
            
        default: return nil
        }
    }

    
    fileprivate func initialLabelTitle() -> String
    {
        switch self.type.value {
        case .likesYou:
            let totalCount = self.input.lmmManager.allLikesYouProfilesCount.value
            let count = self.input.lmmManager.filteredLikesYouProfilesCount.value
            if totalCount != count {
                return String(format: "feed_profiles_filtered".localized(), totalCount - count)
            }
            
            return "common_pull_to_refresh".localized()
            
        case .messages:
            let totalCount = self.input.lmmManager.allMessagesProfilesCount.value
            let count = self.input.lmmManager.filteredMessagesProfilesCount.value
            if totalCount != count {
                return String(format: "feed_profiles_filtered".localized(), totalCount - count)
            }
            
            return "common_pull_to_refresh".localized()
            
        default: return ""
        }
    }
    
    fileprivate func updateVisibleCellsBorders(_  contentOffset: CGFloat)
    {
        let tableBottomOffset = contentOffset + self.tableView.bounds.height
        let screenHeight = UIScreen.main.bounds.height
        
        // Cells
        self.tableView.visibleCells.forEach { cell in
            guard let vc = (cell as? MainLMMCell)?.containerView.containedVC as? MainLMMProfileViewController else { return }
            guard let index = self.tableView.indexPath(for: cell)?.row else { return }
            
            let cellTopOffset = CGFloat(index) * cell.bounds.height
            let cellBottomOffset = cellTopOffset + cell.bounds.height
            
            //vc.topVisibleBorderDistance = cellTopOffset - contentOffset - self.view.safeAreaInsets.top - 72.0
            vc.bottomVisibleBorderDistance = tableBottomOffset - cellBottomOffset - self.view.safeAreaInsets.bottom - 64.0
        }
        
        // Titles
        let feedBottomLabelFrame = self.feedBottomLabel.convert(self.feedBottomLabel.bounds, to: self.view)
        let feedBottomLabelBottom = feedBottomLabelFrame.maxY
        self.feedBottomLabel.alpha = feedBottomLabelBottom <  screenHeight -  self.view.safeAreaInsets.bottom - 56.0 ? 1.0 : 0.0
    }
    
    fileprivate func showLocationsSettingsAlert()
    {
        let alertVC = UIAlertController(title: nil, message: "settings_location_permission".localized(), preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "button_later".localized(), style: .cancel, handler: nil))
        alertVC.addAction(UIAlertAction(title: "button_settings".localized(), style: .default, handler: { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        }))
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
    fileprivate func showFilter()
    {
        let storyboard = Storyboards.mainLMM()
        let vc = storyboard.instantiateViewController(withIdentifier: "main_lc_filter") as! MainLCFilterViewController
        vc.input = MainLCFilterVMInput(
            filter: self.input.filter,
            lmm: self.input.lmmManager,
            feedType: self.type.value
        )
        vc.onShowAll = { [weak self] in
            self?.reload(false)
        }
        vc.onUpdate = { [weak self] isUpdated in
            if isUpdated { self?.reload(true) }
        }
        vc.onClose = {
            ModalUIManager.shared.hide(animated: false)
        }
        
        ModalUIManager.shared.show(vc, animated: false)
    }
    
    fileprivate func showTopBar(_ animated: Bool)
    {
        self.topBarOffsetConstraint.constant = 0.0
        
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.view.layoutSubviews()
            }
        } else {
            self.view.setNeedsLayout()
        }
    }
    
    fileprivate func hideTopBar()
    {
        guard !self.isTabSwitched else { return }
        
        self.topBarOffsetConstraint.constant = -1.0 * (self.view.safeAreaInsets.top + 64.0)
        UIView.animate(withDuration: 0.3) {
            self.view.layoutSubviews()
        }
    }
    
    fileprivate func updateFeedLabel()
    {
        switch self.currentActivityState {
        case .empty: self.emptyFeedLabel.text = self.emptyLabelTitle()
        case .initial: self.emptyFeedLabel.text = self.initialLabelTitle()
        default: break
        }
    }
}

extension MainLMMViewController: UITableViewDataSource, UITableViewDelegate
{
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.profiles()?.value.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "main_llm_cell") as! MainLMMCell
        
        let index = indexPath.row
        if  let profiles = self.profiles()?.value, profiles.count > index {
            let profile = profiles[index]
            guard !profile.isInvalidated else { return cell }
            
            let profileId = profile.id!
            let photoIndex: Int = MainLMMViewController.photoIndexes[profileId] ?? 0
            let profileVC = MainLMMProfileViewController.create(profile,
                                                                feedType: self.type.value,
                                                                initialIndex: photoIndex,
                                                                actionsManager: self.input.actionsManager,
                                                                profileManager: self.input.profileManager,
                                                                navigationManager: self.input.navigationManager,
                                                                scenarioManager: self.input.scenario,
                                                                transitionManager: self.input.transition,
                                                                lmmManager: self.input.lmmManager,
                                                                filter: self.input.filter
            )
            weak var weakProfileVC = profileVC
            profileVC.onChatShow = { [weak self, weak cell] profile, photo, vc in
                guard let `cell` = cell else { return }
                guard let cellIndexPath = self?.tableView.indexPath(for: cell) else { return }
                
                self?.showChat(profile, photo: photo, indexPath: cellIndexPath, profileVC: vc)
            }
            profileVC.onChatHide = { [weak self, weak cell] profile, photo, vc in
                guard let `cell` = cell else { return }
                guard let cellIndexPath = self?.tableView.indexPath(for: cell) else { return }
                
                self?.hideChat(weakProfileVC, profile: profile, photo: photo, indexPath: cellIndexPath)
            }
            profileVC.onBlockOptionsWillShow = { [weak self, weak cell, weak profile] index in
                guard let `cell` = cell else { return }
                guard let cellIndexPath = self?.tableView.indexPath(for: cell) else { return }
                
                self?.tableView.scrollToRow(at: cellIndexPath, at: .top, animated: true)
                
                guard let url = profile?.photos[index].filepath().url() else { return }
                guard let photoView = self?.blockPhotoView else { return }
                
                ImageService.shared.load(url, thumbnailUrl: nil, to: photoView)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                    self?.blockContainerView.isHidden = false
                })
            }
            
            profileVC.onBlockOptionsWillHide = { [weak self] in
                self?.blockContainerView.isHidden = true
            }
            
            profileVC.currentIndex.skip(1).subscribe(onNext: { index in
                MainLMMViewController.photoIndexes[profileId] = index
            }).disposed(by: self.disposeBag)
            
            cell.containerView.embed(profileVC, to: self)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        if let profiles = self.profiles()?.value {
            var distance = profiles.count - indexPath.row
            distance = distance < 0 ? 0 : distance
            distance = distance > 4 ? 4 : distance
            
            let urls = profiles[indexPath.row..<(indexPath.row + distance)].compactMap({ $0.orderedPhotos().first?.thumbnailFilepath().url() })
            self.preheater.startPreheating(with: urls)
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        (cell as? MainLMMCell)?.containerView.remove()
    }
}

fileprivate let topTrashhold: CGFloat = 0.0
fileprivate let midTrashhold: CGFloat = 75.0

extension MainLMMViewController: UIScrollViewDelegate
{
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    {
        guard self.input.chatManager.actionsManager.checkConnectionState() else { return }
        
        self.isDragged = true
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    {
        self.isDragged = false
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        let offset = scrollView.contentOffset.y
        self.updateVisibleCellsBorders(offset)
        
        guard self.isDragged else { return }
        
        if offset > -1.0 * self.tableView.contentInset.top {
            MainLMMViewController.feedsState[self.type.value]?.offset = offset
        } else {
            MainLMMViewController.feedsState[self.type.value]?.offset = 0.0
        }
        
        // Scroll to top FAB
        
        guard offset > topTrashhold else {
            self.hideScrollToTopOption()
            self.showTopBar(true)
            self.updateBtn.alpha = 1.0
            self.prevScrollingOffset = 0.0
            
            return
        }
        
        if offset - self.prevScrollingOffset <  -1.0 * midTrashhold {
            self.showScrollToTopOption()
            self.showTopBar(true)
            self.prevScrollingOffset = offset
            
            return
        }
        
        if offset - self.prevScrollingOffset > midTrashhold {
            self.hideScrollToTopOption()
            self.hideTopBar()
            self.updateBtn.alpha = 0.0
            self.prevScrollingOffset = offset
            
            return
        }
    }
}

extension SourceFeedType
{
    func lmmType() -> LMMType?
    {
        switch self {
        case .whoLikedMe: return .likesYou        
        case .messages: return .messages
        case .inbox: return .inbox
        case .sent: return .sent
        default: return nil
        }
    }
}
