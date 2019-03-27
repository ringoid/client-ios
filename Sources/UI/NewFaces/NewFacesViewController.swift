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

fileprivate enum NewFacesFeedActivityState
{
    case initial;
    case fetching
    case empty
    case contentAvailable
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
    fileprivate let preheater = ImagePreheater()
    fileprivate var prevScrollingOffset: CGFloat = 0.0
    fileprivate var isScrollTopVisible: Bool = false
    fileprivate var isTabSwitched: Bool = false
    
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var emptyFeedLabel: UILabel!
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet fileprivate weak var scrollTopBtn: UIButton!
    @IBOutlet fileprivate weak var loadingActivityView: UIActivityIndicatorView!
    @IBOutlet fileprivate weak var feedEndLabel: UILabel!
    @IBOutlet fileprivate weak var emptyFeedActivityView: UIActivityIndicatorView!
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        self.toggleActivity(.initial)
        
        self.tableView.tableHeaderView = nil
        self.tableView.estimatedSectionHeaderHeight = 0.0
        self.tableView.estimatedSectionFooterHeight = 0.0
        
        let rowHeight = UIScreen.main.bounds.width * AppConfig.photoRatio
        self.tableView.rowHeight = rowHeight
        self.tableView.estimatedRowHeight = rowHeight
        self.tableView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: UIScreen.main.bounds.height - rowHeight, right: 0.0)
        
        self.setupBindings()
        self.setupReloader()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.isTabSwitched = true
        self.updateFeed()
    }
        
    override func updateTheme()
    {
        self.view.backgroundColor = BackgroundColor().uiColor()
    }
    
    override func updateLocale()
    {
        self.titleLabel.text = "feed_explore_empty_title".localized()
        self.feedEndLabel.text = "feed_footer_item_label".localized()
        
        self.toggleActivity(self.currentActivityState)
    }
    
    // MARK: - Actions
    @objc func onReload()
    {
        self.tableView.panGestureRecognizer.isEnabled = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.tableView.refreshControl?.endRefreshing()
        }
     
        guard self.viewModel?.isFetching.value == false else {
            self.tableView.panGestureRecognizer.isEnabled = true
            
            return
        }
        
        self.toggleActivity(.fetching)
        
        self.lastFetchCount = -1
        self.photoIndexes.removeAll()
        
        self.viewModel?.refresh().subscribe(onNext: { [weak self] _ in
            self?.updateFeed()
            self?.tableView.panGestureRecognizer.isEnabled = true
            }, onError:{ [weak self] error in
                guard let `self` = self else { return }
                
                self.updateFeed()
                self.tableView.panGestureRecognizer.isEnabled = true
                showError(error, vc: self)
        }).disposed(by: self.disposeBag)
    }
    
    func onFetchMore()
    {        
        guard let count = self.viewModel?.profiles.value.count, count > 0 else { return }
        
        self.loadingActivityView.startAnimating()
        self.feedEndLabel.isHidden = true
        self.viewModel?.fetchNext().subscribe(
            onNext: { [weak self] _ in
                self?.lastFetchCount = count
                self?.loadingActivityView.stopAnimating()
                self?.feedEndLabel.isHidden = false
            }, onError: { [weak self] error in
                guard let `self` = self else { return }
                
                self.loadingActivityView.stopAnimating()
                self.feedEndLabel.isHidden = false
                showError(error, vc: self)
            }).disposed(by: self.disposeBag)
    }
    
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
        self.viewModel = NewFacesViewModel(self.input)
        self.viewModel?.profiles.asObservable().subscribe(onNext: { [weak self] updatedProfiles in
            guard let `self` = self else { return }
            
            self.updateFeed()
        }).disposed(by: self.disposeBag)
        
        self.viewModel?.isFetching.asObservable().subscribeOn(MainScheduler.instance).skip(1).subscribe(onNext: { [weak self] state in
            if state {
                self?.toggleActivity(.fetching)
            } else {
                self?.toggleActivity(.contentAvailable)
            }
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
        guard let profiles = self.viewModel?.profiles.value else { return }

        defer {
            self.lastFeedIds = profiles.map({ $0.id })
            
            let offset = self.tableView.contentOffset.y
            self.updateVisibleCellsBorders(offset)
        }

        let totalCount = profiles.count
        let isEmpty = totalCount == 0
        self.titleLabel.isHidden = !isEmpty
        self.feedEndLabel.isHidden = isEmpty
        
        if isEmpty && self.currentActivityState != .initial && self.currentActivityState != .fetching {
            self.toggleActivity(.empty)
        }
        
        if !isEmpty {
            self.toggleActivity(.contentAvailable)
        }
        
        let lastItemsCount = self.lastFeedIds.count

        // No signle profile data changed
        if totalCount == 1, lastItemsCount == 1, profiles.first?.id == self.lastFeedIds.last {
            print("NO PROFILE DATA CHANGED")
            return
        }
        
        // No items or several items removal case
        if lastItemsCount <= 1 || totalCount < (lastItemsCount - 1) {
            self.tableView.reloadData()

            return
        }
        
        // Single item removal - blocking case
        if totalCount == lastItemsCount - 1 {
            for i in 0..<totalCount {
                let profile = profiles[i]
                
                // Check for deprecated state
                guard !profile.isInvalidated else { self.tableView.reloadData(); return }
                
                // Found diff - playing animation
                if profile.id != self.lastFeedIds[i] {
                    self.tableView.performBatchUpdates({
                        self.tableView.deleteRows(at: [IndexPath(row: i, section: 0)], with: .top)
                    }, completion: nil)
                    self.tableView.layer.removeAllAnimations()

                    return
                }
            }
            
            // Diff should be last item
            self.tableView.performBatchUpdates({
                self.tableView.deleteRows(at: [IndexPath(row: totalCount, section: 0)], with: .top)
            }, completion: nil)
            self.tableView.layer.removeAllAnimations()
            
            return
        }

        // No update case
        guard totalCount != lastItemsCount else {
            let offset = self.tableView.contentOffset.y
            if offset > 75.0 && totalCount > 0 {
                self.scrollTopBtn.alpha = 1.0
                self.isScrollTopVisible = true
            } else {
                self.scrollTopBtn.alpha = 0.0
                self.isScrollTopVisible = false
            }
            
            return
        }
        
        // Paging case
        let pageRange = lastItemsCount..<totalCount        
        self.lastFeedIds.append(contentsOf: profiles[pageRange].map({ $0.id }))
        
        self.tableView.performBatchUpdates({
            self.tableView.insertRows(at: pageRange.map({ IndexPath(row: $0, section: 0) }), with: .none)
        }, completion: nil)
        
    }
    
    fileprivate func toggleActivity(_ state: NewFacesFeedActivityState)
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
            self.emptyFeedLabel.text =  self.isTabSwitched ? "common_pull_to_refresh".localized() : "feed_explore_empty_no_data".localized()
            self.emptyFeedLabel.isHidden = false
            break
            
        case .contentAvailable:
            self.emptyFeedActivityView.stopAnimating()
            self.emptyFeedLabel.isHidden = true
            break
        }
        
        self.isTabSwitched = false
    }
    
    fileprivate func updateVisibleCellsBorders(_  contentOffset: CGFloat)
    {
        let tableBottomOffset = contentOffset + self.tableView.bounds.height
        
        // Cells
        self.tableView.visibleCells.forEach { cell in
            guard let vc = (cell as? NewFacesCell)?.containerView.containedVC as? NewFaceProfileViewController else { return }
            guard let index = self.tableView.indexPath(for: cell)?.row else { return }
            
            let cellTopOffset = CGFloat(index) * cell.bounds.height
            let cellBottomOffset = cellTopOffset + cell.bounds.height
            
            vc.bottomVisibleBorderDistance = tableBottomOffset - cellBottomOffset - self.view.safeAreaInsets.bottom - 42.0
        }
        
        // Footer
        let globalLabelFrame = self.feedEndLabel.convert(self.feedEndLabel.frame, to: self.view)
        if globalLabelFrame.origin.y + globalLabelFrame.height > self.tableView.bounds.height - self.view.safeAreaInsets.bottom - 62.0 {
            self.feedEndLabel.alpha = 0.0
        } else {
            self.feedEndLabel.alpha = 1.0
        }
        
        let globalIndicatorFrame = self.loadingActivityView.convert(self.loadingActivityView.frame, to: self.view)
        if globalIndicatorFrame.origin.y + globalIndicatorFrame.height > self.tableView.bounds.height - self.view.safeAreaInsets.bottom - 62.0 {
            self.loadingActivityView.alpha = 0.0
        } else {
            self.loadingActivityView.alpha = 1.0
        }
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
            let profileVC = NewFaceProfileViewController.create(profile, actionsManager: self.input.actionsManager, profileManager: self.input.profileManager, navigationManager: self.input.navigationManager,  initialIndex: self.photoIndexes[profile.id] ?? 0)
            cell.containerView.embed(profileVC, to: self)
            
            profileVC.onBlockOptionsWillShow = { [weak self, weak cell] in
                guard let `cell` = cell else { return }
                guard let cellIndexPath = self?.tableView.indexPath(for: cell) else { return }
                
                self?.tableView.scrollToRow(at: cellIndexPath, at: .top, animated: true)
            }
            
            let profileId = profile.id!
            profileVC.currentIndex.asObservable().subscribe(onNext:{ [weak self] index in
                self?.photoIndexes[profileId] = index
            }).disposed(by: self.disposeBag)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        
        if let profiles = self.viewModel?.profiles.value, profiles.count != 0 {
            var distance = profiles.count - indexPath.row
            distance = distance < 0 ? 0 : distance
            distance = distance > 4 ? 4 : distance
            
            let urls = profiles[indexPath.row..<(indexPath.row + distance)].compactMap({ $0.orderedPhotos().first?.filepath().url() })
            self.preheater.startPreheating(with: urls)
        }
        
        print("index: \(indexPath.row) total: \(self.viewModel!.profiles.value.count)")
        guard let isFetching = self.viewModel?.isFetching.value, !isFetching else { return }
        guard
            let totalCount = self.viewModel?.profiles.value.count,
            totalCount != self.lastFetchCount,
            totalCount > 14,
            (totalCount - indexPath.row) <= 5
            else { return }

        log("fetching next page", level: .high)
        self.loadingActivityView.startAnimating()
        self.feedEndLabel.isHidden = true
        self.viewModel?.fetchNext().subscribe(
            onNext: { [weak self] _ in
                self?.loadingActivityView.stopAnimating()
                self?.feedEndLabel.isHidden = false
                self?.lastFetchCount = totalCount
            }, onError: { [weak self] error in
                guard let `self` = self else { return }
                
                self.loadingActivityView.stopAnimating()
                self.feedEndLabel.isHidden = false
                showError(error, vc: self)
            }).disposed(by: self.disposeBag)
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        (cell as? NewFacesCell)?.containerView.remove()
    }
}

fileprivate let topTrashhold: CGFloat = 0.0
fileprivate let midTrashhold: CGFloat = 75.0

extension NewFacesViewController: UIScrollViewDelegate
{
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        let offset = scrollView.contentOffset.y
        self.updateVisibleCellsBorders(offset)
        
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
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    {
        _ = self.input.actionsManager.checkConnectionState()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    {
        self.tableView.visibleCells.forEach { cell in
            guard let vc = (cell as? NewFacesCell)?.containerView.containedVC as? NewFaceProfileViewController else { return }
           
            vc.preheatSecondPhoto()
        }
    }
}
