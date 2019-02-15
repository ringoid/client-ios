//
//  MainViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 09/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

enum SelectionState {
    case search
    case like
    case profile
}

class MainViewController: BaseViewController
{
    var input: MainVMInput!
    var defaultState: SelectionState = .like
    
    fileprivate var viewModel: MainViewModel?
    fileprivate var containerVC: ContainerViewController!
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    fileprivate var menuVCCache: [SelectionState: UIViewController] = [:]
    
    @IBOutlet fileprivate weak var searchBtn: UIButton!
    @IBOutlet fileprivate weak var likeBtn: UIButton!
    @IBOutlet fileprivate weak var profileBtn: UIButton!
    @IBOutlet fileprivate weak var profileIndicatorView: UIView!
    @IBOutlet fileprivate weak var lmmNotSeenIndicatorView: UIView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.setupBindings()        
    }
    
    override func updateTheme()
    {
        self.view.backgroundColor = BackgroundColor().uiColor()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "embed_container"
        {
            self.containerVC = segue.destination as? ContainerViewController
        }
    }
    
    @IBAction func onSearchSelected()
    {
        self.viewModel?.moveToSearch()
    }
    
    @IBAction func onLikeSelected()
    {
        self.viewModel?.moveToLike()
    }
    
    @IBAction func onProfileSelected()
    {
        self.viewModel?.moveToProfile()
    }
    
    // MARK: -
    
    fileprivate func select(_ to: SelectionState)
    {
        switch to {
        case .search:
            self.searchBtn.setImage(UIImage(named: "main_bar_search_selected"), for: .normal)
            self.likeBtn.setImage(UIImage(named: "main_bar_like"), for: .normal)
            self.profileBtn.setImage(UIImage(named: "main_bar_profile"), for: .normal)
            self.embedNewFaces()
            break
            
        case .like:
            self.searchBtn.setImage(UIImage(named: "main_bar_search"), for: .normal)
            self.likeBtn.setImage(UIImage(named: "main_bar_like_selected"), for: .normal)
            self.profileBtn.setImage(UIImage(named: "main_bar_profile"), for: .normal)
            self.embedMainLMM()
            break
            
        case .profile:
            self.searchBtn.setImage(UIImage(named: "main_bar_search"), for: .normal)
            self.likeBtn.setImage(UIImage(named: "main_bar_like"), for: .normal)
            self.profileBtn.setImage(UIImage(named: "main_bar_profile_selected"), for: .normal)
            self.embedUserProfile()
            break
        }
    }
    
    fileprivate func embedNewFaces()
    {
        if let vc = self.menuVCCache[.search] {
            self.containerVC.embed(vc)
            
            return
        }
        
        let storyboard = Storyboards.newFaces()
        guard let vc = storyboard.instantiateInitialViewController() as? NewFacesViewController else { return }
        vc.input = NewFacesVMInput(
            newFacesManager: self.input.newFacesManager,
            actionsManager: self.input.actionsManager,
            profileManager: self.input.profileManager,
            navigationManager: self.input.navigationManager
        )
        
        self.menuVCCache[.search] = vc
        self.containerVC.embed(vc)
    }
    
    fileprivate func embedMainLMM()
    {
        if let vc = self.menuVCCache[.like] {
            self.containerVC.embed(vc)
            
            return
        }
        
        let storyboard = Storyboards.mainLMM()
        guard let vc = storyboard.instantiateInitialViewController() as? MainLMMContainerViewController else { return }
        vc.input = MainLMMVMInput(
            lmmManager: self.input.lmmManager,
            actionsManager: self.input.actionsManager,
            chatManager: self.input.chatManager,
            profileManager: self.input.profileManager,
            navigationManager: self.input.navigationManager,
            newFacesManager: self.input.newFacesManager
        )
       
        self.menuVCCache[.like] = vc
        self.containerVC.embed(vc)
    }
    
    fileprivate func embedUserProfile()
    {
        if let vc = self.menuVCCache[.profile] {
            self.containerVC.embed(vc)
            
            return
        }
        
        let storyboard = Storyboards.userProfile()
        guard let vc = storyboard.instantiateInitialViewController() as? UserProfilePhotosViewController else { return }
        vc.input = UserProfilePhotosVCInput(
            profileManager: self.input.profileManager,
            lmmManager: self.input.lmmManager,
            settingsManager: self.input.settingsManager,
            navigationManager: self.input.navigationManager,
            newFacesManager: self.input.newFacesManager
        )
        
        self.menuVCCache[.profile] = vc
        self.containerVC.embed(vc)
    }
    
    fileprivate func setupBindings()
    {
        self.viewModel = MainViewModel(self.input)
        self.viewModel?.input.navigationManager.mainItem.asObservable().subscribeOn(MainScheduler.instance).subscribe(onNext: { [weak self] item in
            self?.select(item.selectionState())
        }).disposed(by: self.disposeBag)
        
        self.viewModel?.availablePhotosCount.subscribe(onNext: { [weak self] count in
            self?.profileIndicatorView.isHidden = count != 0
        }).disposed(by: self.disposeBag)
        
        self.viewModel?.isNotSeenProfilesAvailable.asObservable().subscribe(onNext: { [weak self] state in
            self?.lmmNotSeenIndicatorView.isHidden = !state
        }).disposed(by: self.disposeBag)
        
    }
}

extension MainNavigationItem
{
    func selectionState() -> SelectionState
    {
        switch self {
        case .search: return .search
        case .like: return .like
        case .profile: return .profile
        }
    }
}
