//
//  MainLMMViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 14/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa
import KafkaRefresh

enum LMMType: String
{
    case likesYou = "likesYou"
    case matches = "matches"
    case messages = "message"
}

fileprivate struct FeedState
{
    var offset: CGFloat = 0.0
    var photos: [Int: Int] = [:]
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
    fileprivate var isUpdated: Bool = true
    fileprivate var chatStartDate: Date? = nil
    fileprivate var prevScrollingOffset: CGFloat = 0.0
    fileprivate var isScrollTopVisible: Bool = false
    fileprivate var lastFeedIds: [String] = []
    
    @IBOutlet fileprivate weak var emptyFeedLabel: UILabel!
    @IBOutlet fileprivate weak var chatContainerView: ContainerView!
    @IBOutlet fileprivate weak var scrollTopBtn: UIButton!
    @IBOutlet fileprivate weak var feedEndView: UIView!
    @IBOutlet fileprivate weak var tableView: UITableView!
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
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

        UIManager.shared.blockModeEnabled.accept(false)
        UIManager.shared.chatModeEnabled.accept(false)

        self.setupBindings()
        self.setupReloader()
    }
    
    override func updateTheme()
    {
        self.view.backgroundColor = BackgroundColor().uiColor()
    }
    
    fileprivate var isInitialLayout: Bool = true    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
     
        // Applying offset after view size is set
        guard isInitialLayout else { return }
        
        self.isInitialLayout = false
        self.isUpdated = true
        self.updateFeed()
    }
    
    // MARK: - Actions
    
    @IBAction func onScrollTop()
    {
        self.hideScrollToTopOption()
        let topOffset = self.view.safeAreaInsets.top + self.tableView.contentInset.top
        self.tableView.setContentOffset(CGPoint(x: 0.0, y: -topOffset), animated: false)
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.viewModel = MainLMMViewModel(self.input)

        self.type.asObservable().subscribe(onNext:{ [weak self] type in
            self?.toggle(type)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func updateBindings()
    {
        self.feedDisposeBag = DisposeBag()
        self.isUpdated = true
        self.profiles()?.asObservable().subscribe(onNext: { [weak self] _ in
            self?.updateFeed()
        }).disposed(by: self.feedDisposeBag)
    }
    
    fileprivate func setupReloader()
    {
        self.tableView.bindHeadRefreshHandler({ [weak self] in
            self?.reload()
            }, themeColor: .lightGray, refreshStyle: .replicatorCircle)
    }
    
    fileprivate func reload()
    {
        if self.viewModel?.isPhotosAdded == false {
            self.showAddPhotosOptions()
            
            return
        }
        
        self.isUpdated = true
        
        UIView.animate(withDuration: 0.095) {
            self.emptyFeedLabel.alpha = 0.0
        }
        
        // TODO: move "finishViewActions" logic inside view model
        self.input.actionsManager.finishViewActions(for: self.profiles()?.value ?? [], source: self.type.value.sourceType())
        self.viewModel?.refresh().subscribe(onError:{ [weak self] error in
            guard let `self` = self else { return }
            
            showError(error, vc: self)
            }, onCompleted:{ [weak self] in
                self?.resetStates()
                self?.tableView.headRefreshControl.endRefreshing()
                
                UIView.animate(withDuration: 0.095) {
                    self?.emptyFeedLabel.alpha = 1.0
                }
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func toggle(_ type: LMMType)
    {
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
    
    fileprivate func updateFeed()
    {
        guard self.isUpdated else { return }
        guard let updatedProfiles = self.profiles()?.value.filter({ !$0.isInvalidated }) else { return }
        
        defer {
            self.lastFeedIds = updatedProfiles.map { $0.id }
        }
        
        let totalCount = updatedProfiles.count
        self.isUpdated = totalCount == 0
        self.emptyFeedLabel.text = self.placeholderText()
        self.emptyFeedLabel.isHidden = !updatedProfiles.isEmpty
        self.feedEndView.isHidden = updatedProfiles.isEmpty
        
        // Checking for blocking scenario
        if totalCount == self.lastFeedIds.count - 1, self.lastFeedIds.count > 1 {
            var diffCount: Int = 0
            var diffIndex: Int = 0
            
            for i in 0..<totalCount {
                let profile = updatedProfiles[i]
                if profile.isInvalidated { break } // Deprecated profiles
                
                if profile.id != self.lastFeedIds[i] {
                    diffIndex = i
                    diffCount += 1
                }
            }
            
            // Blocking scenario confirmed
            if diffCount == 1 {
                self.tableView.deleteRows(at: [IndexPath(row: diffIndex, section: 0)], with: .top)
                
                return
            } else if diffCount == 0 { // Last profile should be removed
                self.tableView.deleteRows(at: [IndexPath(row: totalCount, section: 0)], with: .top)
                
                return
            }
            
            // Returning to default scenario
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
        }
    }
    
    fileprivate func showChat(_ profile: LMMProfile, photo: Photo, indexPath: IndexPath, profileVC: MainLMMProfileViewController?)
    {
        self.chatStartDate = Date()
        
        let vc = ChatViewController.create()
        vc.input = ChatVMInput(profile: profile, photo: photo, chatManager: self.input.chatManager, source: .messages, onClose: { [weak self] in
            self?.hideChat(profileVC, profile: profile, photo: photo)
        })
        
        self.chatContainerView.embed(vc, to: self)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.chatContainerView.isHidden = false
        }
        
        self.scrollTop(to: indexPath.row)
        profileVC?.hideNotChatControls()
    }
    
    fileprivate func hideChat(_ profileVC: MainLMMProfileViewController?, profile: LMMProfile, photo: Photo)
    {
        if let startDate = self.chatStartDate {
            let interval = Int(Date().timeIntervalSince(startDate))
            self.chatStartDate = nil

            self.input.actionsManager.openChatActionProtected(
                1,
                timeSec: interval,
                profile: profile.actionInstance(),
                photo: photo.actionInstance(),
                source: self.type.value.sourceType()
            )            
        }
        
        profileVC?.showNotChatControls()
        
        self.chatContainerView.isHidden = true
        self.chatContainerView.remove()
    }
    
    fileprivate func placeholderText() -> String
    {
        return "FEED_PULL_TO_REFRESH".localized()
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
    
    fileprivate func resetStates()
    {
        MainLMMViewController.feedsState = [
            .likesYou: FeedState(offset: 0.0, photos: [:]),
            .matches: FeedState(offset: 0.0, photos: [:]),
            .messages: FeedState(offset: 0.0, photos: [:])
        ]
    }
    
    fileprivate func scrollTop(to index: Int)
    {
        let height = UIScreen.main.bounds.width * AppConfig.photoRatio
        let topOffset = self.view.safeAreaInsets.top

        self.tableView.setContentOffset(CGPoint(x: 0.0, y: CGFloat(index) * height - topOffset), animated: true)
    }
    
    fileprivate func showAddPhotosOptions()
    {
        let alertVC = UIAlertController(
            title: nil,
            message: "NEW_FACES_NO_PHOTO_ALERT_MESSAGE".localized(),
            preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "NEW_FACES_NO_PHOTO_ALERT_ADD".localized(), style: .default, handler: { [weak self] _ in
            self?.viewModel?.moveToProfile()
        }))
        alertVC.addAction(UIAlertAction(title: "NEW_FACES_NO_PHOTO_ALERT_CANCEL".localized(), style: .cancel, handler: nil))
        
        self.present(alertVC, animated: true, completion: { [weak self] in
            self?.tableView.headRefreshControl.endRefreshing()            
        })
    }
}

extension MainLMMViewController: UITableViewDataSource
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
        if let profile = self.profiles()?.value[indexPath.row] {
            let photoIndex: Int = MainLMMViewController.feedsState[self.type.value]?.photos[indexPath.row] ?? 0
            let profileVC = MainLMMProfileViewController.create(profile, feedType: self.type.value, actionsManager: self.input.actionsManager, initialIndex: photoIndex)
            profileVC.onChatShow = { [weak self, weak cell] profile, photo, vc in
                guard let `cell` = cell else { return }
                guard let cellIndexPath = self?.tableView.indexPath(for: cell) else { return }
                
                self?.showChat(profile, photo: photo, indexPath: cellIndexPath, profileVC: vc)
            }
            profileVC.onChatHide = { [weak self] profile, photo, vc in
                self?.hideChat(profileVC, profile: profile, photo: photo)
                self?.isUpdated = true // for blocked profile update
            }
            profileVC.onBlockOptionsWillShow = { [weak self, weak cell] in
                guard let `cell` = cell else { return }
                guard let cellIndexPath = self?.tableView.indexPath(for: cell) else { return }
                
                self?.scrollTop(to: cellIndexPath.row)
            }
            
            profileVC.currentIndex.asObservable().subscribe(onNext: { [weak self] index in
                guard let `self` = self else { return }
                
                MainLMMViewController.feedsState[self.type.value]?.photos[indexPath.row] = index
            }).disposed(by: self.disposeBag)
            
            cell.containerView.embed(profileVC, to: self)
        }
        
        return cell
    }
}

fileprivate let topTrashhold: CGFloat = 0.0
fileprivate let midTrashhold: CGFloat = UIScreen.main.bounds.width * AppConfig.photoRatio

extension MainLMMViewController: UIScrollViewDelegate
{
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    {
        self.isDragged = true
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    {
        self.isDragged = false
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        let offset = scrollView.contentOffset.y
        
        guard self.isDragged else { return }
        
        MainLMMViewController.feedsState[self.type.value]?.offset = offset
                
        guard offset > topTrashhold else {
            self.hideScrollToTopOption()
            self.prevScrollingOffset = 0.0
            
            return
        }
        
        if offset - self.prevScrollingOffset < -1.0 * midTrashhold {
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
