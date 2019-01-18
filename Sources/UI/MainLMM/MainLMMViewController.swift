//
//  MainLMMViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 14/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

enum LMMType
{
    case likesYou
    case matches
    case messages
}

class MainLMMViewController: ThemeViewController
{
    var input: MainLMMVMInput!
    var type: BehaviorRelay<LMMType> = BehaviorRelay<LMMType>(value: .likesYou)
//    {
//        didSet {
//            guard oldValue.value != type.value else { return }
//
//            self.toggle(type.value)
//        }
//    }
    
    fileprivate var viewModel: MainLMMViewModel?
    fileprivate var feedDisposeBag: DisposeBag = DisposeBag()
    fileprivate var disposeBag: DisposeBag = DisposeBag()
    
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
        self.reload()
    }
    
    @objc func onReload()
    {
        self.reload()
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.viewModel = MainLMMViewModel(self.input)
        //self.setupLikesYouBindings()
        
        self.type.asObservable().subscribe(onNext:{ [weak self] type in
            self?.toggle(type)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func setupLikesYouBindings()
    {
        self.feedDisposeBag = DisposeBag()
        self.viewModel?.likesYou.bind(to: self.tableView.rx.items(cellIdentifier: "main_llm_cell", cellType: MainLMMCell.self)) { (_, profile, cell) in
            let profileVC = MainLMMProfileViewController.create(profile)
            cell.containerView.embed(profileVC, to: self)
            }.disposed(by: self.feedDisposeBag)
    }
    
    fileprivate func setupMatchesBindings()
    {
        self.feedDisposeBag = DisposeBag()
        self.viewModel?.matches.bind(to: self.tableView.rx.items(cellIdentifier: "main_llm_cell", cellType: MainLMMCell.self)) { (_, profile, cell) in
            let profileVC = MainLMMProfileViewController.create(profile)
            cell.containerView.embed(profileVC, to: self)
            }.disposed(by: self.feedDisposeBag)
    }
    
    fileprivate func setupMessagesBindings()
    {
        self.feedDisposeBag = DisposeBag()
        self.viewModel?.messages.bind(to: self.tableView.rx.items(cellIdentifier: "main_llm_cell", cellType: MainLMMCell.self)) { (_, profile, cell) in
            let profileVC = MainLMMProfileViewController.create(profile)
            cell.containerView.embed(profileVC, to: self)
            }.disposed(by: self.feedDisposeBag)
    }
    
    fileprivate func setupReloader()
    {
        self.refreshControl = UIRefreshControl()
        self.tableView.addSubview(self.refreshControl)
        self.refreshControl.addTarget(self, action: #selector(onReload), for: .valueChanged)
    }
    
    fileprivate func reload()
    {
        self.viewModel?.refresh().subscribe(onError:{ [weak self] error in
            guard let `self` = self else { return }
            
            showError(error, vc: self)
            }, onCompleted:{ [weak self] in
                self?.refreshControl.endRefreshing()
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func toggle(_ type: LMMType)
    {
        switch type {
        case .likesYou:
            self.setupLikesYouBindings()
            break
            
        case .matches:
            self.setupMatchesBindings()
            break
        
        case .messages:
            self.setupMessagesBindings()
            break
        }
    }
    
}
