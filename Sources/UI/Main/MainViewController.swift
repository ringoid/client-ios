//
//  MainViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 09/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

fileprivate enum SelectionState {
    case search
    case like
    case messages
    case profile
}

class MainViewController: ThemeViewController
{
    var input: MainVMInput!
    
    fileprivate var viewModel: MainViewModel?
    fileprivate var containerVC: ContainerViewController!
    
    @IBOutlet fileprivate weak var searchBtn: UIButton!
    @IBOutlet fileprivate weak var likeBtn: UIButton!
    @IBOutlet fileprivate weak var messagesBtn: UIButton!
    @IBOutlet fileprivate weak var profileBtn: UIButton!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.setupBindings()
        self.select(.search)
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
        self.select(.search)
    }
    
    @IBAction func onLikeSelected()
    {
        self.select(.like)
    }
    
    @IBAction func onMessagesSelected()
    {
        self.select(.messages)
    }
    
    @IBAction func onProfileSelected()
    {
        self.select(.profile)
    }
    
    // MARK: -
    
    fileprivate func select(_ to: SelectionState)
    {
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
            break
            
        case .profile:
            self.searchBtn.setImage(UIImage(named: "main_bar_search"), for: .normal)
            self.likeBtn.setImage(UIImage(named: "main_bar_like"), for: .normal)
            self.messagesBtn.setImage(UIImage(named: "main_bar_messages"), for: .normal)
            self.profileBtn.setImage(UIImage(named: "main_bar_profile_selected"), for: .normal)
            break
        }
    }
    
    fileprivate func embedNewFaces()
    {
        let storyboard = UIStoryboard(name: "NewFaces", bundle: nil)
        guard let vc = storyboard.instantiateInitialViewController() as? NewFacesViewController else { return }
        vc.input = NewFacesVMInput(newFacesManager: self.input.newFacesManager, actionsManager: self.input.actionsManager)
        
        self.containerVC.embed(vc)
    }
    
    fileprivate func embedMainLMM()
    {
        let storyboard = UIStoryboard(name: "MainLMM", bundle: nil)
        guard let vc = storyboard.instantiateInitialViewController() as? MainLMMViewController else { return }
        vc.input = MainLMMVMInput(lmmManager: self.input.lmmManager)
        
        self.containerVC.embed(vc)
    }
    
    fileprivate func setupBindings()
    {
        self.viewModel = MainViewModel(self.input)
    }
}
