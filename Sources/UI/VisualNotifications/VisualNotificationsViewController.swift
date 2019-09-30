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
import Differ

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
            guard let `self` = self else { return }
            
            let diff = patch(from: self.items, to: updatedItems)
            let indexPaths = diff.compactMap ({ item -> IndexPath? in
                switch item {
                case .insertion(let index, _): return IndexPath(row: index, section: 0)
                default: return nil
                }
            })
            
            self.items = updatedItems
            self.tableView.insertRows(at: indexPaths, with: .top)
        }).disposed(by: self.disposeBag)
    }
}

// MARK: - UITableViewDataSource & Delegate

extension VisualNotificationsViewController: UITableViewDataSource, UITableViewDelegate
{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "visual_notification_cell") as! VisualNotificaionCell
        
        let item = self.items[indexPath.row]
        cell.item = item
        cell.startAnimation()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 48.0
    }
}
