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

enum LMMType: String
{
    case likesYou = "likesYou"
    case matches = "matches"
    case messages = "message"
}

fileprivate struct FeedState
{
    var offset: CGFloat = 0.0
    var photos: [String: Int] = [:]
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
        .matches: FeedState(),
        .messages: FeedState()
    ]
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
    
    @IBOutlet fileprivate weak var emptyFeedLabel: UILabel!
    @IBOutlet fileprivate weak var chatContainerView: ContainerView!
    @IBOutlet fileprivate weak var scrollTopBtn: UIButton!
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet fileprivate weak var emptyFeedActivityView: UIActivityIndicatorView!
    @IBOutlet fileprivate weak var blockContainerView: UIView!
    @IBOutlet fileprivate weak var blockPhotoView: UIImageView!
    @IBOutlet fileprivate weak var blockPhotoAspectConstraint: NSLayoutConstraint!
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        self.toggleActivity(.initial)
        
        self.tableView.estimatedSectionHeaderHeight = 0.0
        self.tableView.estimatedSectionFooterHeight = 0.0
        
        let cellHeight = UIScreen.main.bounds.width * AppConfig.photoRatio
        self.tableView.tableHeaderView = nil
        self.tableView.rowHeight = cellHeight
        self.tableView.estimatedRowHeight = cellHeight
        self.tableView.contentInset = UIEdgeInsets(
            top: self.view.safeAreaInsets.top + 44.0,
            left: 0.0,
            bottom: UIScreen.main.bounds.height - cellHeight,
            right: 0.0
        )
        
        self.blockPhotoAspectConstraint.constant = AppConfig.photoRatio

        UIManager.shared.blockModeEnabled.accept(false)
        UIManager.shared.chatModeEnabled.accept(false)

        self.setupBindings()
        self.setupReloader()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        self.isTabSwitched = true
        self.updateFeed(true)
    }
    
    override func updateTheme()
    {
        self.view.backgroundColor = BackgroundColor().uiColor()
        self.blockContainerView.backgroundColor = BackgroundColor().uiColor()
    }
    
    override func updateLocale()
    {
        self.toggleActivity(self.currentActivityState)
    }
    
    fileprivate var isInitialLayout: Bool = true    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
        // Applying offset after view size is set
        guard isInitialLayout else { return }
        
        self.isTabSwitched = true
        self.isInitialLayout = false
        self.updateFeed(true)
    }
    
    // MARK: - Actions
    
    @IBAction func onScrollTop()
    {
        self.hideScrollToTopOption()
        let topOffset = self.view.safeAreaInsets.top + self.tableView.contentInset.top
        self.tableView.setContentOffset(CGPoint(x: 0.0, y: -topOffset), animated: false)
        self.input.actionsManager.commit()
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
                UIManager.shared.lmmRefreshModeEnabled.accept(true)
            } else {
                UIManager.shared.lmmRefreshModeEnabled.accept(false)
                self?.toggleActivity(.contentAvailable)
                self?.tableView.dataSource = self
                self?.updateFeed(true)
            }
        }).disposed(by: self.disposeBag)
        
        UIManager.shared.feedsFabShouldBeHidden.asObservable().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] state in
            guard state else { return }
            
            self?.hideScrollToTopOption()
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func updateBindings()
    {
        self.feedDisposeBag = DisposeBag()
        self.profiles()?.asObservable().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
            self?.updateFeed(false)
        }).disposed(by: self.feedDisposeBag)
    }
    
    fileprivate func setupReloader()
    {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(reload), for: .valueChanged)
        self.tableView.refreshControl = refreshControl
    }
    
    @objc fileprivate func reload()
    {
        AnalyticsManager.shared.send(.pullToRefresh(self.type.value.sourceType().rawValue))
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
        
        self.viewModel?.refresh(self.type.value).subscribe(
            onNext: { [weak self ] _ in
                self?.tableView.panGestureRecognizer.isEnabled = true                
            }, onError:{ [weak self] error in
                guard let `self` = self else { return }
                
                self.tableView.panGestureRecognizer.isEnabled = true
                showError(error, vc: self)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func toggle(_ type: LMMType)
    {
        self.input.actionsManager.commit()
        
        self.isTabSwitched = true
        self.updateBindings()
    }
    
    fileprivate func profiles() -> BehaviorRelay<[LMMProfile]>?
    {
        switch self.type.value {
        case .likesYou:
            return self.viewModel?.likesYou
            
        case .matches:
            return self.viewModel?.matches
            
        case .messages:
            return self.viewModel?.messages
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
        
        if self.type.value == .matches && updatedProfiles.count > 0 {
            self.input.scenario.checkFirstMatch(self.type.value.sourceType())
        }
        
        defer {
            self.lastFeedIds = updatedProfiles.map { $0.id }
            self.lastUpdateFeedType = self.type.value
            
            let offset = self.tableView.contentOffset.y
            self.updateVisibleCellsBorders(offset)
        }
        
        let totalCount = updatedProfiles.count
        let isEmpty = updatedProfiles.isEmpty
        
        if isEmpty && self.currentActivityState != .initial && self.currentActivityState != .fetching {
            self.toggleActivity(.empty)
        }
        
        if !isEmpty {
            self.toggleActivity(.contentAvailable)
        }

        // Checking for blocking scenario
        if totalCount == self.lastFeedIds.count - 1, self.lastFeedIds.count > 1, self.lastUpdateFeedType == self.type.value {
            var diffCount: Int = 0
            var diffIndex: Int = 0
            var j: Int = 0
            
            for i in 0..<totalCount {
                let profile = updatedProfiles[i]
                if profile.isInvalidated { break } // Deprecated profiles

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
                self.tableView.performBatchUpdates({
                    self.tableView.deleteRows(at: [IndexPath(row: totalCount, section: 0)], with: .top)
                }, completion: nil)
                self.tableView.layer.removeAllAnimations()
                
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
            
            if cachedOffset > 75.0 && totalCount > 0 {
                self.scrollTopBtn.alpha = 1.0
                self.isScrollTopVisible = true
            } else {
                self.scrollTopBtn.alpha = 0.0
                self.isScrollTopVisible = false
            }
        }
    }
    
    fileprivate func showChat(_ profile: LMMProfile, photo: Photo, indexPath: IndexPath, profileVC: MainLMMProfileViewController?)
    {
        self.isChatShown = true
        let photoId = photo.id
        if let actionProfile = profile.actionInstance(),
            let actionPhoto = actionProfile.orderedPhotos().filter({ $0.id == photoId }).first {
            
            self.input.actionsManager.stopViewAction(actionProfile, photo: actionPhoto, sourceType: self.type.value.sourceType())
            self.input.actionsManager.startViewChatAction(actionProfile, photo: actionPhoto)
        }
        
        let vc = ChatViewController.create()
        vc.input = ChatVMInput(
            profile: profile,
            photo: photo,
            source: self.type.value.sourceType(),
            chatManager: self.input.chatManager,
            scenario: self.input.scenario,
            transition: self.input.transition
            , onClose: { [weak self] in
                self?.hideChat(profileVC, profile: profile, photo: photo, indexPath: indexPath)
            }, onBlock: { [weak profileVC] in
                profileVC?.block(true)
        })
  
        self.chatContainerView.embed(vc, to: self)
        self.chatContainerView.isHidden = false
                
        self.scrollTop(to: indexPath.row, offset: 0.0, animated: false)
        profileVC?.hideNotChatControls()
    }
    
    fileprivate func hideChat(_ profileVC: MainLMMProfileViewController?, profile: LMMProfile, photo: Photo, indexPath: IndexPath)
    {
        let photoId = photo.id
        if let actionProfile = profile.actionInstance(),
            let actionPhoto = actionProfile.orderedPhotos().filter({ $0.id == photoId }).first {
            self.input.actionsManager.stopViewChatAction(actionProfile, photo: actionPhoto, sourceType: self.type.value.sourceType())
            self.input.actionsManager.startViewAction(actionProfile, photo: actionPhoto)
        }
        profileVC?.showNotChatControls()
        
        self.chatContainerView.isHidden = true
        self.chatContainerView.remove()
        
        self.scrollTop(to: indexPath.row, offset: 44.0, animated: false)
        self.isChatShown = false
    }
    
    fileprivate func showScrollToTopOption()
    {
        guard !self.isScrollTopVisible else { return }
        
        let animator = UIViewPropertyAnimator(duration: 0.1, curve: .linear) {
            self.scrollTopBtn.alpha = 1.0
        }
        animator.addCompletion { _ in
            self.isScrollTopVisible = true
        }
        
        animator.startAnimation()
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
        MainLMMViewController.feedsState = [
            .likesYou: FeedState(offset: 0.0, photos: [:]),
            .matches: FeedState(offset: 0.0, photos: [:]),
            .messages: FeedState(offset: 0.0, photos: [:])
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
            message: "feed_explore_dialog_no_user_photo_description".localized(),
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
            self.emptyFeedLabel.text = "common_pull_to_refresh".localized()
            self.emptyFeedLabel.isHidden = false
            break
            
        case .fetching:
            self.emptyFeedActivityView.startAnimating()
            self.emptyFeedLabel.isHidden = true
            break
            
        case .empty:
            self.emptyFeedActivityView.stopAnimating()
            self.emptyFeedLabel.text = self.emptyLabelTitle()
            self.emptyFeedLabel.isHidden = false
            break
            
        case .contentAvailable:
            self.emptyFeedActivityView.stopAnimating()
            self.emptyFeedLabel.isHidden = true
            break
        }
        
        self.isTabSwitched = false
    }
    
    fileprivate func emptyLabelTitle() -> String
    {
        guard !self.isTabSwitched else {
            return "common_pull_to_refresh".localized()
        }
        
        switch self.type.value {
        case .likesYou: return "feed_likes_you_empty_no_data".localized()
        case .matches: return "feed_matches_empty_no_data".localized()
        case .messages: return "feed_messages_empty_no_data".localized()
        }
    }
    
    fileprivate func updateVisibleCellsBorders(_  contentOffset: CGFloat)
    {
        let tableBottomOffset = contentOffset + self.tableView.bounds.height
        
        // Cells
        self.tableView.visibleCells.forEach { cell in
            guard let vc = (cell as? MainLMMCell)?.containerView.containedVC as? MainLMMProfileViewController else { return }
            guard let index = self.tableView.indexPath(for: cell)?.row else { return }
            
            let cellTopOffset = CGFloat(index) * cell.bounds.height
            let cellBottomOffset = cellTopOffset + cell.bounds.height
            
            vc.topVisibleBorderDistance = cellTopOffset - contentOffset - self.view.safeAreaInsets.top - 12.0
            vc.bottomVisibleBorderDistance = tableBottomOffset - cellBottomOffset - self.view.safeAreaInsets.bottom - 42.0
        }
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
            let profileId = profile.id!
            let photoIndex: Int = MainLMMViewController.feedsState[self.type.value]?.photos[profileId] ?? 0
            let profileVC = MainLMMProfileViewController.create(profile,
                                                                feedType: self.type.value,
                                                                initialIndex: photoIndex,
                                                                actionsManager: self.input.actionsManager,
                                                                profileManager: self.input.profileManager,
                                                                navigationManager: self.input.navigationManager,
                                                                scenarioManager: self.input.scenario,
                                                                transitionManager: self.input.transition
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
                
                self?.scrollTop(to: cellIndexPath.row, offset: 0.0, animated: true)
                
                guard let url = profile?.photos[index].filepath().url() else { return }
                guard let photoView = self?.blockPhotoView else { return }
                
                ImageService.shared.load(url, to: photoView)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                    self?.blockContainerView.isHidden = false
                })
            }
            
            profileVC.onBlockOptionsWillHide = { [weak self, weak cell] in
                self?.blockContainerView.isHidden = true
                
                guard let `cell` = cell else { return }
                guard let cellIndexPath = self?.tableView.indexPath(for: cell) else { return }
                
                self?.scrollTop(to: cellIndexPath.row, offset: 44.0, animated: false)
            }
            
            profileVC.currentIndex.asObservable().subscribe(onNext: { [weak self] index in
                guard let `self` = self else { return }
                
                MainLMMViewController.feedsState[self.type.value]?.photos[profileId] = index
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
            
            let urls = profiles[indexPath.row..<(indexPath.row + distance)].compactMap({ $0.orderedPhotos().first?.filepath().url() })
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
        
        self.tableView.visibleCells.forEach { cell in
            guard let vc = (cell as? MainLMMCell)?.containerView.containedVC as? MainLMMProfileViewController else { return }
            
            vc.preheatSecondPhoto()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        let offset = scrollView.contentOffset.y
        self.updateVisibleCellsBorders(offset)
        
        guard self.isDragged else { return }
        
        if offset > -1.0 * self.tableView.contentInset.top {
            MainLMMViewController.feedsState[self.type.value]?.offset = offset
        }
        
        // Scroll to top FAB
        
        guard offset > topTrashhold else {
            self.hideScrollToTopOption()
            self.prevScrollingOffset = 0.0
            
            return
        }
        
        if offset - self.prevScrollingOffset <  -1.0 * midTrashhold {
            self.showScrollToTopOption()
            self.prevScrollingOffset = offset
            
            return
        }
        
        if offset - self.prevScrollingOffset > midTrashhold {
            self.hideScrollToTopOption()
            self.prevScrollingOffset = offset
            
            return
        }
    }
}
