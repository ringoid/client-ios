//
//  RootViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 02/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

fileprivate enum AppUIMode
{
    case unknown
    case auth
    case newfaces
}

class RootViewController: UIViewController {

    var appManager: AppManager!
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    fileprivate var mode: AppUIMode = .unknown
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.appManager = (UIApplication.shared.delegate as! AppDelegate).appManager
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        self.subscribeToAuthState()
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
    
    fileprivate func move(to: AppUIMode)
    {
        guard to != self.mode else { return }
        
        defer {
            self.mode = to
        }
        
        var segueId = ""
        
        switch to {
        case .unknown: break
        case .auth:
            segueId = SegueIds.newFaces
        case .newfaces:
            segueId = SegueIds.auth
        }
        
        if let presentedVC = self.presentedViewController {
            presentedVC.dismiss(animated: false) {
                self.performSegue(withIdentifier: segueId, sender: nil)
            }
        } else {
            self.performSegue(withIdentifier: segueId, sender: nil)
        }
    }
    
    fileprivate func subscribeToAuthState()
    {
        self.appManager.apiService.isAuthorized.asObservable().subscribe ({ [weak self] event in
            if event.element == true {
                self?.move(to: .auth)
            } else {
                self?.move(to: .newfaces)
            }
        }).disposed(by: disposeBag)
    }
}

extension RootViewController
{
    fileprivate struct SegueIds
    {
        static let auth = "auth_flow"
        static let newFaces = "new_faces_flow"
    }
}

