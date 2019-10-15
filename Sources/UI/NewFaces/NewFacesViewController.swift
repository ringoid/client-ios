//
//  NewFacesViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 07/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import RxSwift
import Nuke
import Differ

fileprivate enum NewFacesFeedActivityState
{
    case initial;
    case reloading;
    case fetching;
    case empty;
    case contentAvailable;
}

class NewFacesViewController: BaseViewController
{
    var input: NewFacesVMInput!
    
    fileprivate var viewModel: NewFacesViewModel?
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    fileprivate var lastFeedIds: [String] = []
    fileprivate var lastFetchCount: Int = -1
    fileprivate var photoIndexes: [String: Int] = [:]
    fileprivate var currentActivityState: NewFacesFeedActivityState = .initial
    fileprivate let preheater = ImagePreheater(destination: .diskCache)
    fileprivate var prevScrollingOffset: CGFloat = 0.0
    fileprivate var isScrollTopVisible: Bool = false
    fileprivate var isTabSwitched: Bool = false
    fileprivate var visibleCells: [NewFacesCell] = []
    fileprivate var shouldShowFetchActivityOnLocationPermission: Bool = false
    fileprivate var activityStartDate: Date? = nil
    
    @IBOutlet fileprivate weak var feedTitleLabel: UILabel!
    @IBOutlet fileprivate weak var emptyFeedLabel: UILabel!
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet fileprivate weak var scrollTopBtn: UIButton!
    @IBOutlet fileprivate weak var emptyFeedActivityView: UIActivityIndicatorView!
    @IBOutlet fileprivate weak var blockContainerView: UIView!
    @IBOutlet fileprivate weak var blockPhotoView: UIImageView!
    @IBOutlet fileprivate weak var blockPhotoAspectConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var tapBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var topBarOffsetConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var feedTitleBtn: UIButton!
    @IBOutlet fileprivate weak var feedBottomBtn: UIButton!
    @IBOutlet fileprivate weak var feedBottomLabel: UILabel!
    @IBOutlet fileprivate weak var topPanelView: UIView!
    @IBOutlet fileprivate weak var topPanelLineHeightConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var filterBtn: UIButton!    
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        self.filterBtn.setImage(UIImage(named: "feed_filter_btn")?.withRenderingMode(.alwaysTemplate), for: .normal)        
        
        self.topPanelLineHeightConstraint.constant = 0.5
        
        self.toggleActivity(.initial)
        
        self.tableView.estimatedSectionHeaderHeight = 0.0
        self.tableView.estimatedSectionFooterHeight = 0.0
        
        let headerHeight = MainLMMProfileViewController.profileHeaderHeight
        let footerHeight = MainLMMProfileViewController.profileFooterHeight
        let rowHeight = UIScreen.main.bounds.width * AppConfig.photoRatio + headerHeight + footerHeight
        self.tableView.rowHeight = rowHeight
        self.tableView.estimatedRowHeight = rowHeight
        self.tableView.contentInset = UIEdgeInsets(
            top: 64.0,
            left: 0.0,
            bottom: UIScreen.main.bounds.height - rowHeight,
            right: 0.0)
        
        self.blockPhotoAspectConstraint.constant = AppConfig.photoRatio
        
        self.setupBindings()
        self.setupReloader()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        self.isTabSwitched = true
        self.updateFeed()
        self.showTopBar(false)
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        self.isTabSwitched = false
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
        self.topPanelView.backgroundColor = BackgroundColor().uiColor()
        
        self.feedTitleLabel.textColor = ContentColor().uiColor()
        self.feedBottomLabel.textColor = ContentColor().uiColor()
        self.emptyFeedLabel.textColor = ContentColor().uiColor()
        self.filterBtn.tintColor = ContentColor().uiColor()
    }
    
    override func updateLocale()
    {
        self.feedTitleLabel.text = "feed_explore_empty_title".localized()
        self.feedBottomLabel.text = "feed_discover_expand_filters".localized()
        
        self.toggleActivity(self.currentActivityState)
    }
    
    func reload(_ isFilteringEnabled: Bool)
    {
        self.tableView.panGestureRecognizer.isEnabled = false
        
        self.feedBottomLabel.isHidden = true
        self.feedBottomBtn.isHidden = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.tableView.refreshControl?.endRefreshing()
        }
        
        guard self.viewModel?.isFetching.value == false else {
            self.tableView.panGestureRecognizer.isEnabled = true
            
            return
        }
        
        guard self.viewModel?.isLocationDenied != true else {
            self.shouldShowFetchActivityOnLocationPermission = true
            self.showLocationsSettingsAlert()
            self.tableView.panGestureRecognizer.isEnabled = true
            
            return
        }
        
        guard self.viewModel?.registerLocationsIfNeeded() == true else {
            self.shouldShowFetchActivityOnLocationPermission = true
            self.tableView.panGestureRecognizer.isEnabled = true
            
            return
        }
        
        self.viewModel?.registerPushesIfNeeded()
        
        self.toggleActivity(.reloading)
        
        self.lastFetchCount = -1
        self.photoIndexes.removeAll()
        
        self.tableView.dataSource = EmptyFeed.shared
        self.tableView.reloadData()
        self.viewModel?.refresh(isFilteringEnabled).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
            guard let `self` = self else { return }
            
            self.tableView.dataSource = self
            self.tableView.reloadData()
            self.tableView.panGestureRecognizer.isEnabled = true
            
            let isNotEmptyFeed = self.viewModel!.profiles.value.count != 0
            let isNotEnoughUsersAvailable = self.viewModel!.profiles.value.count < 8
            let isMaxRangeSelected = self.input.filter.isMaxRangeSelected
            self.feedBottomLabel.isHidden = !(isNotEnoughUsersAvailable && !isMaxRangeSelected && isNotEmptyFeed)
            self.feedBottomBtn.isHidden = !(isNotEnoughUsersAvailable && !isMaxRangeSelected && isNotEmptyFeed)
            }, onError:{ [weak self] error in
                guard let `self` = self else { return }
                
                self.tableView.panGestureRecognizer.isEnabled = true
                self.feedBottomLabel.isHidden = true
                self.feedBottomBtn.isHidden = true
                
                self.showErrorAlert()
        }).disposed(by: self.disposeBag)
    }
    
    // MARK: - Actions
    @objc fileprivate func onReload()
    {
        AnalyticsManager.shared.send(.pullToRefresh(SourceFeedType.newFaces.rawValue))
        self.showTopBar(true)
        self.reload(false)
    }
    
    func onFetchMore()
    {
        guard let count = self.viewModel?.profiles.value.count, count > 0 else { return }
 
        log("fetching next page", level: .high)

        self.viewModel?.fetchNext().subscribe(
            onNext: { [weak self] _ in
                self?.lastFetchCount = count
                
                let isNotEmptyFeed = self?.viewModel?.profiles.value.count != 0
                let isNoUsersAvailable = count == self?.viewModel?.profiles.value.count
                let isMaxRangeSelected = self?.input.filter.isMaxRangeSelected == true
                self?.feedBottomLabel.isHidden = !(isNoUsersAvailable && !isMaxRangeSelected && isNotEmptyFeed)
                self?.feedBottomBtn.isHidden = !(isNoUsersAvailable && !isMaxRangeSelected && isNotEmptyFeed)
            }, onError: { [weak self] error in
                guard let `self` = self else { return }
                
                showError(error, vc: self)
            }).disposed(by: self.disposeBag)
    }
    
    @IBAction func onScrollTop()
    {
        //self.hideScrollToTopOption()
        self.showTopBar(true)
        let topOffset = self.view.safeAreaInsets.top + self.tableView.contentInset.top
        self.tableView.setContentOffset(CGPoint(x: 0.0, y: -topOffset), animated: false)
        self.input.actionsManager.commit()
    }
    
    @IBAction func onShowFilter()
    {
        self.showFilter()
    }
    
    @IBAction func showFilterFromFeed()
    {
        self.showTopBar(true)
        self.showFilter()
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.viewModel = NewFacesViewModel(self.input)
        self.viewModel?.profiles.subscribe(onNext: { [weak self] updatedProfiles in
            guard let `self` = self else { return }
            
            self.updateFeed()
        }).disposed(by: self.disposeBag)
        
        self.viewModel?.isFetching.asObservable().observeOn(MainScheduler.instance).skip(1).subscribe(onNext: { [weak self] state in
            if state {
                self?.toggleActivity(.fetching)
            } else {
                let isEmpty = self?.viewModel?.profiles.value.count == 0
                self?.toggleActivity(isEmpty ? .empty : .contentAvailable)
            }
        }).disposed(by: self.disposeBag)
        
        self.viewModel?.location.isGranted.asObservable().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] state in
            guard state else { return }
            guard let `self` = self else { return }
            guard self.shouldShowFetchActivityOnLocationPermission else { return }
            
            self.shouldShowFetchActivityOnLocationPermission = false
            self.toggleActivity(.fetching)
        }).disposed(by: self.disposeBag)
        
        self.viewModel?.initialLocationTrigger.asObservable().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] value in
            guard value else { return }
            
            self?.reload(false)
        }).disposed(by: self.disposeBag)
        
//        UIManager.shared.feedsFabShouldBeHidden.asObservable().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] state in
//            guard state else { return }
//
//            self?.hideScrollToTopOption()
//        }).disposed(by: self.disposeBag)
        
        UIManager.shared.discoverTopBarShouldBeHidden.asObservable().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] state in
            guard let `self` = self else { return }
            guard state else { return }
            guard self.tableView.contentOffset.y > topTrashhold else { return }
            
            self.hideTopBar()
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func setupReloader()
    {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(onReload), for: .valueChanged)
        self.tableView.refreshControl = refreshControl
    }
    
    fileprivate func updateFeed()
    {
        guard self.tableView.dataSource !== EmptyFeed.shared else { return }
        guard let profiles = self.viewModel?.profiles.value else { return }
        
        let feedIds = profiles.compactMap({ $0.id })
        
        defer {
            self.lastFeedIds = feedIds
            
            let offset = self.tableView.contentOffset.y
            self.updateVisibleCellsBorders(offset)
            self.input.transition.afterTransition = false
        }
        
        let totalCount = profiles.count
        let isEmpty = totalCount == 0
        
        if isEmpty && self.currentActivityState != .fetching {
            if self.currentActivityState == .contentAvailable {
                self.toggleActivity(.initial)
            } else if self.currentActivityState != .initial {
                self.toggleActivity(.empty)
            }
        }
        
        if !isEmpty {
            self.toggleActivity(.contentAvailable)
        } else {
            self.feedBottomLabel.isHidden = true
            self.feedBottomBtn.isHidden = true
        }
        
        let diff = patch(from: self.lastFeedIds, to: feedIds)
        
        // No signle profile data changed
        if diff.isEmpty {
            print("NO PROFILE DATA CHANGED")
            
            return
        }
        
        // Counting operations
        var insertionsCount: Int = 0
        var deletionsCount: Int = 0
        diff.forEach { path in
            switch path {
            case .insertion(_, _): insertionsCount += 1; break
            case .deletion(_): deletionsCount += 1; break
            }
        }
        
        // Items update or several items removal case
        if deletionsCount > 1 || (deletionsCount > 0 && insertionsCount > 0) {
            self.tableView.reloadData()
            
            return
        }
        
        // Single item removal - blocking case
        if insertionsCount == 0, deletionsCount == 1 {
            if let path = diff.first {
                switch path {
                case .deletion(let index):                    
                    self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .top)
                    self.tableView.layer.removeAllAnimations()
                    
                    if !isEmpty, index == totalCount {
                        self.tableView.scrollToRow(at:  IndexPath(row: totalCount - 1, section: 0), at: .top, animated: true)
                    }

                    break
                    
                default: break
                }
            }
            
            return
        }
        
        // Paging case
        if insertionsCount > 0, deletionsCount == 0, self.lastFeedIds.count != 0 {
            
            var insertionIndexes: [IndexPath] = []
            diff.forEach { path in
                switch path {
                case .insertion(let index, _):
                    insertionIndexes.append(IndexPath(row: index, section: 0))
                    break
                    
                default: break
                }
            }
            
            self.tableView.insertRows(at: insertionIndexes, with: .none)
            self.tableView.layer.removeAllAnimations()
            
            return
        }
        
        // Rest cases
        self.tableView.reloadData()
    }
        
    
    fileprivate func toggleActivity(_ state: NewFacesFeedActivityState)
    {
        self.currentActivityState = state
        
        switch state {
        case .initial:
            if let startDate = self.activityStartDate {
                let duration: Double =  round(Date().timeIntervalSince(startDate) * 1000.0) / 1000.0
                AnalyticsManager.shared.send(.spinnerShown("new_faces", duration))
                self.activityStartDate = nil
            }
            
            self.emptyFeedActivityView.stopAnimating()
            self.emptyFeedLabel.text = "common_pull_to_refresh".localized()
            self.emptyFeedLabel.isHidden = false
            self.feedTitleBtn.isHidden = false
            break
            
        case .reloading:
            self.activityStartDate = Date()
            
            self.emptyFeedActivityView.startAnimating()
            self.emptyFeedLabel.isHidden = true
            self.feedTitleBtn.isHidden = true
            break
            
        case .fetching:
            self.emptyFeedLabel.isHidden = true
            self.feedTitleBtn.isHidden = true
            break
            
        case .empty:
            if let startDate = self.activityStartDate {
                let duration: Double =  round(Date().timeIntervalSince(startDate) * 1000.0) / 1000.0
                AnalyticsManager.shared.send(.spinnerShown("new_faces", duration))
                self.activityStartDate = nil
            }
            
            self.emptyFeedActivityView.stopAnimating()
            self.emptyFeedLabel.text = "feed_explore_empty_no_data".localized()
            self.emptyFeedLabel.isHidden = false
            self.feedTitleBtn.isHidden = false
            break
            
        case .contentAvailable:
            if let startDate = self.activityStartDate {
                let duration: Double =  round(Date().timeIntervalSince(startDate) * 1000.0) / 1000.0
                AnalyticsManager.shared.send(.spinnerShown("new_faces", duration))
                self.activityStartDate = nil
            }
            
            self.emptyFeedActivityView.stopAnimating()
            self.emptyFeedLabel.isHidden = true
            self.feedTitleBtn.isHidden = true
            break
        }
    }
    
    fileprivate func updateVisibleCellsBorders(_  contentOffset: CGFloat)
    {
        let tableBottomOffset = contentOffset + self.tableView.bounds.height
        let screenHeight = UIScreen.main.bounds.height
        
        // Cells
        self.visibleCells.forEach { cell in
            guard let vc = cell.containerView.containedVC as? NewFaceProfileViewController else { return }
            guard let index = self.tableView.indexPath(for: cell)?.row else { return }
            
            let cellTopOffset = CGFloat(index) * cell.bounds.height
            let cellBottomOffset = cellTopOffset + cell.bounds.height
            
            vc.bottomVisibleBorderDistance = tableBottomOffset - cellBottomOffset - self.view.safeAreaInsets.bottom - 64.0
        }
        
        // Titles
        let feedBottomLabelFrame = self.feedBottomLabel.convert(self.feedBottomLabel.bounds, to: self.view)
        let feedBottomLabelBottom = feedBottomLabelFrame.maxY
        self.feedBottomLabel.alpha = feedBottomLabelBottom <  screenHeight -  self.view.safeAreaInsets.bottom - 56.0 ? 1.0 : 0.0
    }
    
//    fileprivate func showScrollToTopOption()
//    {
//        guard !self.isScrollTopVisible else { return }
//
//        let animator = UIViewPropertyAnimator(duration: 0.1, curve: .linear) {
//            self.scrollTopBtn.alpha = 1.0
//        }
//        animator.addCompletion { _ in
//            self.isScrollTopVisible = true
//        }
//
//        animator.startAnimation()
//    }
//
//    fileprivate func hideScrollToTopOption()
//    {
//        guard self.isScrollTopVisible else { return }
//
//        let animator = UIViewPropertyAnimator(duration: 0.15, curve: .linear) {
//            self.scrollTopBtn.alpha = 0.0
//        }
//        animator.addCompletion { _ in
//            self.isScrollTopVisible = false
//        }
//
//        animator.startAnimation()
//    }
    
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
        let storyboard = Storyboards.newFaces()
        let vc = storyboard.instantiateViewController(withIdentifier: "new_faces_filter") as! NewFacesFilterViewController
        vc.input = NewFacesFilterVMInput(filter: self.input.filter)
        vc.onUpdate = { [weak self] isUpdated in
            if isUpdated { self?.reload(true) }
        }
        vc.onClose = {
            ModalUIManager.shared.hide(animated: true)
        }
        
        ModalUIManager.shared.show(vc, animated: true)
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
    
    fileprivate func showErrorAlert()
    {
        let alertVC = UIAlertController(title: nil, message: "error_timeout".localized(), preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "button_cancel".localized(), style: .cancel, handler: { [weak self] _ in
            guard let `self` = self else { return }
            
            self.tableView.dataSource = self
            self.tableView.reloadData()
        }))
        
        alertVC.addAction(UIAlertAction(title: "button_retry".localized(), style: .default, handler: { [weak self] _ in
            self?.onReload()
        }))
        
        self.present(alertVC, animated: true, completion: nil)
    }
}

extension NewFacesViewController: UITableViewDataSource, UITableViewDelegate
{
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.viewModel?.profiles.value.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "new_faces_cell") as! NewFacesCell
        
        guard let count = self.viewModel?.profiles.value.count, indexPath.row < count else { return cell }
        
        if let profile = self.viewModel?.profiles.value[indexPath.row], !profile.isInvalidated {
            let profileVC = NewFaceProfileViewController.create(profile,
                                                                initialIndex: self.photoIndexes[profile.id] ?? 0,
                                                                actionsManager: self.input.actionsManager,
                                                                profileManager: self.input.profileManager,
                                                                navigationManager: self.input.navigationManager,
                                                                scenarioManager: self.input.scenario,
                                                                transitionManager: self.input.transition,
                                                                externalLinkManager: self.input.externalLinkManager
            )
            cell.containerView.embed(profileVC, to: self)
            
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
            
            let profileId = profile.id!
            profileVC.currentIndex.skip(1).subscribe(onNext:{ [weak self] index in
                self?.photoIndexes[profileId] = index
            }).disposed(by: self.disposeBag)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        guard let newFacesCell = cell as? NewFacesCell else { return }
        
        self.visibleCells.append(newFacesCell)
        
        if let profiles = self.viewModel?.profiles.value, profiles.count != 0 {
            var distance = profiles.count - indexPath.row
            distance = distance < 0 ? 0 : distance
            distance = distance > 4 ? 4 : distance
            
            guard indexPath.row + distance < profiles.count else { return }
            
            let urls = profiles[indexPath.row..<(indexPath.row + distance)].compactMap({ $0.orderedPhotos().first?.thumbnailFilepath().url() })
            self.preheater.startPreheating(with: urls)
        }
        
        print("index: \(indexPath.row) total: \(self.viewModel!.profiles.value.count)")
        guard let isFetching = self.viewModel?.isFetching.value, !isFetching else { return }
        guard
            let totalCount = self.viewModel?.profiles.value.count,
            totalCount != self.lastFetchCount,
            totalCount > 8,
            (totalCount - indexPath.row) <= 5
            else { return }

        self.onFetchMore()
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        guard let newFacesCell = cell as? NewFacesCell else { return }
        
        if let indexToRemove = self.visibleCells.firstIndex(of: newFacesCell) {
            self.visibleCells.remove(at: indexToRemove)
        }
        
        newFacesCell.containerView.remove()
    }
}

fileprivate let topTrashhold: CGFloat = 0.0
fileprivate let midTrashhold: CGFloat = 75.0

extension NewFacesViewController: UIScrollViewDelegate
{
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        let offset = scrollView.contentOffset.y
        //self.updateVisibleCellsBorders(offset)
        
        // Bottom new page trigger
        let bottomOffset = scrollView.contentSize.height - scrollView.bounds.height - scrollView.contentInset.bottom - scrollView.contentInset.top - offset - 64.0
        if bottomOffset < 0.0 && self.viewModel?.isFetching.value == false {
            if let profiles = self.viewModel?.profiles.value, profiles.count > 2 {
                self.onFetchMore()
            }
        }
        
        // Scroll to top FAB
        
        guard offset > topTrashhold else {
            // self.hideScrollToTopOption()
            self.showTopBar(true)
            self.prevScrollingOffset = 0.0
            
            return
        }
        
        if offset - self.prevScrollingOffset <  -1.0 * midTrashhold {
            // self.showScrollToTopOption()
            self.showTopBar(true)
            self.prevScrollingOffset = offset
            
            return
        }
        
        if offset - self.prevScrollingOffset > midTrashhold {
            // self.hideScrollToTopOption()
            self.hideTopBar()
            self.prevScrollingOffset = offset
            
            return
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    {
        _ = self.input.actionsManager.checkConnectionState()
    }
}

extension NewFacesViewController
{
    struct SegueIds
    {
        static let fiter = "embed_filter"
    }
}
