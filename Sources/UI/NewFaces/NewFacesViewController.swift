//
//  NewFacesViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 07/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import RxSwift
import KafkaRefresh

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
    fileprivate var currentActivityState: NewFacesFeedActivityState = .initial
    
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var emptyFeedLabel: UILabel!
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet fileprivate weak var loadingActivityView: UIActivityIndicatorView!
    @IBOutlet fileprivate weak var feedEndLabel: UILabel!
    @IBOutlet fileprivate weak var emptyFeedActivityView: UIActivityIndicatorView!
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        self.toggleActivity(.initial)
        
        self.tableView.tableHeaderView = nil
        let rowHeight = UIScreen.main.bounds.width * AppConfig.photoRatio
        self.tableView.rowHeight = rowHeight
        self.tableView.estimatedRowHeight = rowHeight
        self.tableView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: UIScreen.main.bounds.height - rowHeight, right: 0.0)
        
        self.setupBindings()
        self.setupReloader()
    }
    
    override func updateTheme()
    {
        self.view.backgroundColor = BackgroundColor().uiColor()
    }
    
    override func updateLocale()
    {
        self.toggleActivity(self.currentActivityState)
    }
    
    // MARK: - Actions
    func onReload()
    {
        if self.viewModel?.isPhotosAdded == false {
            self.showAddPhotosOptions()
            
            return
        }
        
        self.toggleActivity(.fetching)
        self.tableView.headRefreshControl.endRefreshing()
        
        self.lastFetchCount = -1
        
        self.viewModel?.refresh().subscribe(onError:{ [weak self] error in
            guard let `self` = self else { return }
            
            showError(error, vc: self)
            }).disposed(by: self.disposeBag)
    }
    
    func onFetchMore()
    {
        self.tableView.footRefreshControl.endRefreshing()
        
        if self.viewModel?.isPhotosAdded == false {
            self.showAddPhotosOptions()
            
            return
        }
        
        guard let count = self.viewModel?.profiles.value.count, count > 0 else { return }
        
        self.loadingActivityView.startAnimating()
        self.feedEndLabel.isHidden = true
        self.viewModel?.fetchNext().subscribe(
            onNext: { [weak self] _ in
                self?.lastFetchCount = count
            }, onError: { [weak self] error in
                guard let `self` = self else { return }
                
                showError(error, vc: self)
            }, onCompleted: { [weak self] in
                self?.viewModel?.finishFetching()
                self?.loadingActivityView.stopAnimating()
                self?.feedEndLabel.isHidden = false
        }).disposed(by: self.disposeBag)
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.viewModel = NewFacesViewModel(self.input)
        self.viewModel?.profiles.asObservable().subscribe(onNext: { [weak self] _ in
            guard let `self` = self else { return }
            
            self.updateFeed()
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func setupReloader()
    {
        self.tableView.bindHeadRefreshHandler({ [weak self] in
            self?.onReload()
        }, themeColor: .lightGray, refreshStyle: .replicatorCircle)
        
        self.tableView.bindFootRefreshHandler({ [weak self] in
            self?.onFetchMore()
        }, themeColor: .lightGray, refreshStyle: .replicatorCircle)
    }
    
    fileprivate func updateFeed()
    {
        guard let profiles = self.viewModel?.profiles.value else { return }
        
        defer {
            self.lastFeedIds = profiles.map({ $0.id })
        }

        let totalCount = profiles.count
        let isEmpty = totalCount == 0
        self.titleLabel.isHidden = !isEmpty
        self.feedEndLabel.isHidden = isEmpty
        self.toggleActivity(isEmpty ?.empty : .contentAvailable)
        
        let lastItemsCount = self.lastFeedIds.count
        
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
                    self.tableView.deleteRows(at: [IndexPath(row: i, section: 0)], with: .top)
                    
                    return
                }
            }
            
            // Diff should be last item
            self.tableView.deleteRows(at: [IndexPath(row: totalCount, section: 0)], with: .top)
            
            return
        }

        // Paging case
        let pageRange = lastItemsCount..<totalCount
        self.lastFeedIds.append(contentsOf: profiles[pageRange].map({ $0.id }))
        self.tableView.insertRows(at: pageRange.map({ IndexPath(row: $0, section: 0) }), with: .none)
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
            self?.tableView.footRefreshControl.endRefreshing()
        })
    }
    
    fileprivate func toggleActivity(_ state: NewFacesFeedActivityState)
    {
        self.currentActivityState = state
        
        switch state {
        case .initial:
            self.emptyFeedActivityView.stopAnimating()
            self.emptyFeedLabel.text = "FEED_PULL_TO_REFRESH".localized()
            self.emptyFeedLabel.isHidden = false
            break
            
        case .fetching:
            self.emptyFeedActivityView.startAnimating()
            self.emptyFeedLabel.isHidden = true
            break
            
        case .empty:
            self.emptyFeedActivityView.stopAnimating()
            self.emptyFeedLabel.text = "NEW_FACES_NO_NEW_ITEMS".localized()
            self.emptyFeedLabel.isHidden = false
            break
            
        case .contentAvailable:
            self.emptyFeedActivityView.stopAnimating()
            self.emptyFeedLabel.isHidden = true
            break
        }
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
            let profileVC = NewFaceProfileViewController.create(profile, actionsManager: self.input.actionsManager)
            cell.containerView.embed(profileVC, to: self)
            
            profileVC.onBlockOptionsWillShow = { [weak self, weak cell] in
                guard let `cell` = cell else { return }
                guard let cellIndexPath = self?.tableView.indexPath(for: cell) else { return }
                
                self?.tableView.scrollToRow(at: cellIndexPath, at: .top, animated: true)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        print("index: \(indexPath.row) total: \(self.viewModel!.profiles.value.count)")
        guard let isFetching = self.viewModel?.isFetching, !isFetching else { return }
        guard
            let totalCount = self.viewModel?.profiles.value.count,
            totalCount != self.lastFetchCount,
            (totalCount - indexPath.row) <= 5
            else { return }

        print("fetching next page")
        self.loadingActivityView.startAnimating()
        self.feedEndLabel.isHidden = true
        self.viewModel?.fetchNext().subscribe(
            onNext: { [weak self] _ in
                self?.lastFetchCount = totalCount
            }, onError: { [weak self] error in
                guard let `self` = self else { return }
                
                showError(error, vc: self)
            }, onCompleted: { [weak self] in
                self?.viewModel?.finishFetching()
                self?.loadingActivityView.stopAnimating()
                self?.feedEndLabel.isHidden = false
        }).disposed(by: self.disposeBag)
    }
}
