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
    fileprivate var delayedItems: [VisualNotificationInfo] = []
    fileprivate var delayModeState: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    fileprivate var delayTimer: Timer?
    
    @IBOutlet fileprivate var tableView: VisualNotificationsTableView!
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()

        self.tableView.onTap = { [weak self] in
            self?.updateDelayTimer()
        }
        
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
            
            guard !self.delayModeState.value else {
                self.delayedItems.insert(contentsOf: filteredItems, at: 0)
                
                return
            }
            
            guard self.items.count + filteredItems.count <= 5 else {
                let limitedItems = filteredItems[0..<(5 - self.items.count)]
                let restItems = filteredItems[(5 - self.items.count)..<filteredItems.count]
                
                let indexPaths = (0..<limitedItems.count).map({ IndexPath(row: $0, section: 0) })
                self.items.insert(contentsOf: limitedItems, at: 0)
                self.tableView.insertRows(at: indexPaths, with: .top)
                
                self.delayedItems.insert(contentsOf: restItems, at: 0)
                
                self.delayModeState.accept(true)
                
                return
            }
            
            let indexPaths = (0..<filteredItems.count).map({ IndexPath(row: $0, section: 0) })
            self.items.insert(contentsOf: filteredItems, at: 0)
            self.tableView.insertRows(at: indexPaths, with: .top)
        }).disposed(by: self.disposeBag)
        
        self.delayModeState.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] state in
            guard !state else { return }
            guard let `self` = self else { return }
            
            if self.items.count + self.delayedItems.count > 5 {
                let limitedItems = self.delayedItems[0..<(5 - self.items.count)]
                let restItems = self.delayedItems[(5 - self.items.count)..<self.delayedItems.count]
                
                let indexPaths = (0..<limitedItems.count).map({ IndexPath(row: $0, section: 0) })
                self.items.insert(contentsOf: limitedItems, at: 0)
                self.tableView.insertRows(at: indexPaths, with: .top)
                
                self.delayedItems.removeAll()
                self.delayedItems.append(contentsOf: restItems)
                
                self.delayModeState.accept(true)
            } else {
                self.items.insert(contentsOf: self.delayedItems, at: 0)
                let indexPaths = (0..<self.delayedItems.count).map({ IndexPath(row: $0, section: 0) })
                self.tableView.insertRows(at: indexPaths, with: .top)
                self.delayedItems.removeAll()
            }
            
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func startTemporaryHideAnimation()
    {
        let animator = UIViewPropertyAnimator(duration: 0.125, curve: .linear) {
            self.tableView.alpha = 0.0
        }
        
        animator.addCompletion { _ in
            self.items.removeAll()
            self.tableView.reloadData()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                self.delayModeState.accept(false)
                self.tableView.alpha = 1.0
            }
        }
        
        animator.startAnimation()
    }
    
    fileprivate var lastUpdateDate: Date? = nil
    fileprivate func updateDelayTimer()
    {
        if let lastDate = self.lastUpdateDate, Date().timeIntervalSince(lastDate) < 1.0 { return }
        
        self.tableView.visibleCells.forEach({ cell in
            (cell as? VisualNotificaionCell)?.stopHidingTimer()
        })
        
        self.delayModeState.accept(true)
        
        self.lastUpdateDate = Date()
        self.delayTimer?.invalidate()
        self.delayTimer = nil
        
        let timer = Timer(timeInterval: 2.0, repeats: false) { [weak self] _ in
            guard let `self` = self else { return }
            
            self.tableView.visibleCells.forEach({ cell in
                (cell as? VisualNotificaionCell)?.startHidingTimer()
                self.delayModeState.accept(false)
            })
        }
        RunLoop.main.add(timer, forMode: .common)
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
        cell.startHidingTimer()
        cell.onSelected = { [weak self] in
            guard let `self` = self else { return }
            
            self.startTemporaryHideAnimation()
            
            let index = indexPath.row
            let item = self.items[index]
            self.viewModel?.openChat(item.profileId)
        }
        cell.onAnimationFinished = { [weak self] in
            guard let `self` = self else { return }
            guard let index = self.items.firstIndex(of: item) else { return }
            
            self.items.remove(at: index)
            let indexPath = IndexPath(row: index, section: 0)
            self.tableView.deleteRows(at: [indexPath], with: .none)
            self.delayModeState.accept(false)
        }
        cell.onDeletionAnimationFinished = { [weak self] in
            guard let `self` = self else { return }
            guard let index = self.items.firstIndex(of: item) else { return }
           
            self.items.remove(at: index)
            let indexPath = IndexPath(row: index, section: 0)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            self.delayModeState.accept(false)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 80.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 0.0
    }
}
