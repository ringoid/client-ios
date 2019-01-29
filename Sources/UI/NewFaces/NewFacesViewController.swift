//
//  NewFacesViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 07/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import RxSwift

class NewFacesViewController: ThemeViewController
{
    var input: NewFacesVMInput!
    
    fileprivate var viewModel: NewFacesViewModel?
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    fileprivate var lastItemsCount: Int = 0
    
    @IBOutlet fileprivate weak var emptyFeedView: UIView!
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet fileprivate weak var loadingActivityView: UIActivityIndicatorView!
    fileprivate var refreshControl: UIRefreshControl!
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        self.tableView.tableHeaderView = nil
        let rowHeight = UIScreen.main.bounds.height * 3.0 / 4.0
        self.tableView.rowHeight = rowHeight
        self.tableView.estimatedRowHeight = rowHeight
        
        self.setupBindings()
        self.setupReloader()
    }
    
    // MARK: - Actions
    @objc func onReload()
    {
        if self.viewModel?.isPhotosAdded == false {
            self.showAddPhotosOptions()
            
            return
        }
        
        self.viewModel?.refresh().subscribe(onError:{ [weak self] error in
            guard let `self` = self else { return }
            
            showError(error, vc: self)
            }, onCompleted:{ [weak self] in
                self?.refreshControl.endRefreshing()
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
        self.refreshControl = UIRefreshControl()
        self.tableView.addSubview(self.refreshControl)
        self.refreshControl.addTarget(self, action: #selector(onReload), for: .valueChanged)
    }
    
    fileprivate func updateFeed()
    {
        guard let totalCount = self.viewModel?.profiles.value.count, totalCount > self.lastItemsCount else { return }
        
        defer {
            self.lastItemsCount = totalCount
        }

        self.emptyFeedView.isHidden = totalCount != 0
        
        if self.lastItemsCount == 0 {
            self.tableView.reloadData()
            self.loadingActivityView.startAnimating()
            
            return
        }
        
        self.tableView.insertRows(at: (self.lastItemsCount..<totalCount).map({ IndexPath(row: $0, section: 0) }), with: .none)
    }
    
    fileprivate func showAddPhotosOptions()
    {
        let alertVC = UIAlertController(
            title: nil,
            message: "Do you want to see who likes you, discover others, like and message them?",
            preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "Add photo", style: .default, handler: { [weak self] _ in
            self?.viewModel?.moveToProfile()
        }))
        alertVC.addAction(UIAlertAction(title: "Maybe later", style: .cancel, handler: nil))
        
        self.present(alertVC, animated: true, completion: { [weak self] in
            self?.refreshControl.endRefreshing()
        })
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
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        guard let isFetching = self.viewModel?.isFetching, !isFetching else { return }
        guard let totalCount = self.viewModel?.profiles.value.count, totalCount - indexPath.row <= 5 else { return }

        print("fetching next page")
        self.viewModel?.fetchNext().subscribe(onError: { [weak self] error in
            guard let `self` = self else { return }

            showError(error, vc: self)
            }, onCompleted: { [weak self] in
                self?.viewModel?.finishFetching()
        }).disposed(by: self.disposeBag)
    }
}
