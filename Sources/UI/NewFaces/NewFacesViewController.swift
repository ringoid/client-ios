//
//  NewFacesViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 07/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class NewFacesViewController: UIViewController
{
    var input: NewFacesVMInput!
    
    fileprivate var viewModel: NewFacesViewModel?
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.viewModel = NewFacesViewModel(self.input)
    }
}
