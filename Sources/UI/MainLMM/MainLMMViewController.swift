//
//  MainLMMViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 14/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import RxSwift

class MainLMMViewController: ThemeViewController
{
    var input: MainLMMVMInput!
    
    fileprivate var viewModel: MainLMMViewModel?
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    @IBOutlet fileprivate weak var tableView: UITableView!
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        self.tableView.tableHeaderView = nil
        self.tableView.rowHeight = UIScreen.main.bounds.height * 3.0 / 4.0
        
        self.setupBindings()
        self.reload()
    }
    
    // MARK: - Actions
    
    @IBAction func onLikesYouSelected()
    {
        self.setupLikesYouBindings()
    }
    
    @IBAction func onMatches()
    {
        self.setupMatchesBindings()
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.viewModel = MainLMMViewModel(self.input)
        self.setupLikesYouBindings()
    }
    
    fileprivate func setupLikesYouBindings()
    {
        self.viewModel?.likesYou.bind(to: self.tableView.rx.items(cellIdentifier: "main_llm_cell", cellType: MainLMMCell.self)) { (_, profile, cell) in
            let profileVC = MainLMMProfileViewController.create(profile)
            cell.containerView.embed(profileVC, to: self)
            }.disposed(by: self.disposeBag)
    }
    
    fileprivate func setupMatchesBindings()
    {
        self.viewModel?.matches.bind(to: self.tableView.rx.items(cellIdentifier: "main_llm_cell", cellType: MainLMMCell.self)) { (_, profile, cell) in
            let profileVC = MainLMMProfileViewController.create(profile)
            cell.containerView.embed(profileVC, to: self)
            }.disposed(by: self.disposeBag)
    }
    
    fileprivate func reload()
    {
        self.viewModel?.refresh().subscribe(onError:{ [weak self] error in
            guard let `self` = self else { return }
            
            showError(error, vc: self)
        }).disposed(by: self.disposeBag)
    }
}
