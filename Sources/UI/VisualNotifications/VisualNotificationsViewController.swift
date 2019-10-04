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
        
        self.tableView.estimatedSectionHeaderHeight = 0.0
        self.tableView.estimatedSectionFooterHeight = 0.0
        
        self.viewModel = VisualNotificationsViewModel(self.input)
        self.setupBindings()
    }
    
    // IBAction: -
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.viewModel?.items.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] updatedItems in
            guard let `self` = self else { return }
            
            let localIds = self.items.map({ $0.profileId })
            let filteredItems = updatedItems.filter({ !localIds.contains($0.profileId) })
            
            guard !filteredItems.isEmpty else { return }

            let indexPaths = (0..<filteredItems.count).map({ IndexPath(row: $0, section: 0) })
            self.items.insert(contentsOf: filteredItems, at: 0)
            self.tableView.insertRows(at: indexPaths, with: .top)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func startTemporaryHideAnimation()
    {
        let animator = UIViewPropertyAnimator(duration: 0.125, curve: .linear) {
            self.tableView.alpha = 0.0
        }
        
        animator.addCompletion { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                self.tableView.alpha = 1.0
            }
        }
        
        animator.startAnimation()
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
        let item = self.items[indexPath.row]
        let identifier = item.type == .match ? "visual_notification_match_cell" : "visual_notification_cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as! VisualNotificaionCell
        
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
        self.startTemporaryHideAnimation()
        
        let index = indexPath.row
        let item = self.items[index]
        self.viewModel?.openChat(item.profileId)
    }
}
