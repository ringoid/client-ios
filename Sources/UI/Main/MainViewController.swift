//
//  MainViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 09/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class MainViewController: ThemeViewController
{
    var input: MainVMInput!
    
    fileprivate var viewModel: MainViewModel?
    fileprivate var containerVC: ContainerViewController!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.setupBindings()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "embed_container"
        {
            self.containerVC = segue.destination as? ContainerViewController
            self.embedNewFaces()
        }
    }
    
    // MARK: -
    
    fileprivate func embedNewFaces()
    {
        let storyboard = UIStoryboard(name: "NewFaces", bundle: nil)
        guard let vc = storyboard.instantiateInitialViewController() as? NewFacesViewController else { return }
        vc.input = NewFacesVMInput(newFacesManager: self.input.newFacesManager)
        
        self.containerVC.embed(vc)
    }
    
    fileprivate func setupBindings()
    {
        self.viewModel = MainViewModel(self.input)
    }
}
