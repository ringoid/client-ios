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
    
    @IBOutlet fileprivate weak var tableView: UITableView!
    fileprivate var refreshControl: UIRefreshControl!
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        self.tableView.tableHeaderView = nil
        self.tableView.rowHeight = UIScreen.main.bounds.height * 3.0 / 4.0
        
        self.setupBindings()
        self.setupReloader()
    }
    
    // MARK: - Actions
    @objc func onReload()
    {
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
        self.viewModel?.profiles.bind(to: self.tableView.rx.items(cellIdentifier: "new_faces_cell", cellType: NewFacesCell.self)) { (_, profile, cell) in
            let profileVC = NewFaceProfileViewController.create(profile)
            cell.containerView.embed(profileVC, to: self)
        }.disposed(by: self.disposeBag)
    }
    
    fileprivate func setupReloader()
    {
        self.refreshControl = UIRefreshControl()
        self.tableView.addSubview(self.refreshControl)
        self.refreshControl.addTarget(self, action: #selector(onReload), for: .valueChanged)
    }
}
