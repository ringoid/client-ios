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

            let indexPaths = (0..<updatedItems.count).map({ IndexPath(row: $0, section: 0) })
            self.items.insert(contentsOf: updatedItems, at: 0)
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
        cell.onAnimationFinished = { [weak self] in
            guard let `self` = self else { return }
            guard let index = self.items.firstIndex(of: item) else { return }
            
            self.items.remove(at: index)
            let indexPath = IndexPath(row: index, section: 0)
            self.tableView.deleteRows(at: [indexPath], with: .none)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 80.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let index = indexPath.row
        let item = self.items[index]
        self.viewModel?.openChat(item.profileId)
        
        self.items.remove(at: index)
        self.tableView.deleteRows(at: [indexPath], with: .none)
    }
}
