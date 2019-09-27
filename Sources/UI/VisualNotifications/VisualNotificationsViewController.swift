//
//  VisualNotificationsViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 27/09/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class VisualNotificationsViewController: UIViewController
{
    var input: VisualNotificationsVMInput!
    
    fileprivate var viewModel: VisualNotificationsViewModel?
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    fileprivate var items: [VisualNotificationInfo] = []
    
    @IBOutlet fileprivate var tableView: UITableView!
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        self.viewModel = VisualNotificationsViewModel(self.input)
        self.setupBindings()
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.viewModel?.items.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] updatedItems in
            self?.items = updatedItems
            self?.tableView.reloadData()
        }).disposed(by: self.disposeBag)
    }
}
