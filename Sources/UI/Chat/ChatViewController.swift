//
//  ChatViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 24/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class ChatViewController: UIViewController
{
    var input: ChatVMInput!
    
    fileprivate var viewModel: ChatViewModel?
    
    static func create() -> ChatViewController
    {
        let storyboard = Storyboards.chat()
        
        return storyboard.instantiateInitialViewController() as! ChatViewController
    }
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        self.setupBindings()
    }
    
    // MARK: - Actions
    
    @IBAction func onClose()
    {
        self.input.onClose?()
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.viewModel = ChatViewModel(self.input)
    }
}
