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
    case messages
    case profile
}

class MainViewController: ThemeViewController
{
    var input: MainVMInput!
    var defaultState: SelectionState = .search
    
    fileprivate var viewModel: MainViewModel?
    fileprivate var containerVC: ContainerViewController!
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    @IBOutlet fileprivate weak var searchBtn: UIButton!
    @IBOutlet fileprivate weak var likeBtn: UIButton!
    @IBOutlet fileprivate weak var messagesBtn: UIButton!
    @IBOutlet fileprivate weak var profileBtn: UIButton!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.setupBindings()
        self.select(self.defaultState)
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
    
    @IBAction func onMessagesSelected()
    {
        self.viewModel?.moveToMessages()
    }
    
    @IBAction func onProfileSelected()
    {
        self.viewModel?.moveToProfile()
    }
    
    // MARK: -
    
    fileprivate func select(_ to: SelectionState)
    {
        self.viewModel?.purgeNewFaces()
        
        switch to {
        case .search:
            self.searchBtn.setImage(UIImage(named: "main_bar_search_selected"), for: .normal)
            self.likeBtn.setImage(UIImage(named: "main_bar_like"), for: .normal)
            self.messagesBtn.setImage(UIImage(named: "main_bar_messages"), for: .normal)
            self.profileBtn.setImage(UIImage(named: "main_bar_profile"), for: .normal)
            self.embedNewFaces()
            break
            
        case .like:
            self.searchBtn.setImage(UIImage(named: "main_bar_search"), for: .normal)
            self.likeBtn.setImage(UIImage(named: "main_bar_like_selected"), for: .normal)
            self.messagesBtn.setImage(UIImage(named: "main_bar_messages"), for: .normal)
            self.profileBtn.setImage(UIImage(named: "main_bar_profile"), for: .normal)
            self.embedMainLMM()
            break
            
        case .messages:
            self.searchBtn.setImage(UIImage(named: "main_bar_search"), for: .normal)
            self.likeBtn.setImage(UIImage(named: "main_bar_like"), for: .normal)
            self.messagesBtn.setImage(UIImage(named: "main_bar_messages_selected"), for: .normal)
            self.profileBtn.setImage(UIImage(named: "main_bar_profile"), for: .normal)
            self.embedMessages()
            break
            
        case .profile:
            self.searchBtn.setImage(UIImage(named: "main_bar_search"), for: .normal)
            self.likeBtn.setImage(UIImage(named: "main_bar_like"), for: .normal)
            self.messagesBtn.setImage(UIImage(named: "main_bar_messages"), for: .normal)
            self.profileBtn.setImage(UIImage(named: "main_bar_profile_selected"), for: .normal)
            self.embedUserProfile()
            break
        }
    }
    
    fileprivate func embedNewFaces()
    {
        let storyboard = Storyboards.newFaces()
        guard let vc = storyboard.instantiateInitialViewController() as? NewFacesViewController else { return }
        vc.input = NewFacesVMInput(newFacesManager: self.input.newFacesManager, actionsManager: self.input.actionsManager)
        
        self.containerVC.embed(vc)
    }
    
    fileprivate func embedMainLMM()
    {
        let storyboard = Storyboards.mainLMM()
        guard let vc = storyboard.instantiateInitialViewController() as? MainLMMContainerViewController else { return }
        vc.input = MainLMMVMInput(lmmManager: self.input.lmmManager, actionsManager: self.input.actionsManager, chatManager: self.input.chatManager, profileManager: self.input.profileManager)
        
        self.containerVC.embed(vc)
    }
    
    fileprivate func embedMessages()
    {
        let storyboard = Storyboards.mainLMM()
        guard let vc = storyboard.instantiateViewController(withIdentifier: "main_lmm_vc") as? MainLMMViewController else { return }
        vc.input = MainLMMVMInput(lmmManager: self.input.lmmManager, actionsManager: self.input.actionsManager, chatManager: self.input.chatManager, profileManager: self.input.profileManager)
        vc.type.accept(.messages)
        
        self.containerVC.embed(vc)
    }
    
    fileprivate func embedUserProfile()
    {
        let storyboard = Storyboards.userProfile()
        guard let vc = storyboard.instantiateInitialViewController() as? UserProfilePhotosViewController else { return }
        vc.input = UserProfilePhotosVCInput(
            profileManager: self.input.profileManager,
            lmmManager: self.input.lmmManager,
            settingsManager: self.input.settingsManager,
            navigationManager: self.input.navigationManager
        )
        
        self.containerVC.embed(vc)
    }
    
    fileprivate func setupBindings()
    {
        self.viewModel = MainViewModel(self.input)
        self.viewModel?.input.navigationManager.mainItem.asObservable().subscribeOn(MainScheduler.instance).subscribe(onNext: { [weak self] item in
            self?.select(item.selectionState())
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
        case .messages: return .messages
        case .profile: return .profile
        }
    }
}
