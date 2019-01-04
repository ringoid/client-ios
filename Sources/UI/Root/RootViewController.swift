//
//  RootViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 02/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class RootViewController: UIViewController {

    var appManager: AppManager!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.appManager = (UIApplication.shared.delegate as! AppDelegate).appManager
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        self.handleAuthState()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == SegueIds.auth, let vc = segue.destination as? AuthViewController {
            vc.input = AuthVMInput(
                profileManager: self.appManager.profileManager,
                apiService: self.appManager.apiService
            )
        }
    }
    
    // MARK: -
    
    fileprivate func handleAuthState()
    {
        if self.appManager.apiService.isAuthorized {
            
        } else {
            self.performSegue(withIdentifier: SegueIds.auth, sender: nil)
        }
    }
}

extension RootViewController
{
    fileprivate struct SegueIds
    {
        static let auth = "auth_flow"
    }
}

