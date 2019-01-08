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
    case userProfile
}

class RootViewController: ThemeViewController {

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
            vc.input = AuthVMInput(apiService: self.appManager.apiService)
        }
        
        if segue.identifier == SegueIds.userProfile, let vc = segue.destination as? UserProfilePhotosViewController {
            vc.input = UserProfilePhotosVCInput(profileManager: self.appManager.profileManager)
        }
        
        if segue.identifier == SegueIds.newFaces, let vc = segue.destination as? NewFacesViewController {
            vc.input = NewFacesVMInput(newFacesManager: self.appManager.newFacesManager)
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
            segueId = SegueIds.auth
        case .newfaces:
            segueId = SegueIds.newFaces
        case .userProfile:
            segueId = SegueIds.userProfile
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
            if event.element != true {
                self?.move(to: .auth)
            } else {
                if self?.appManager.profileManager.photos.value.count == 0 {
                    self?.move(to: .userProfile)
                } else {
                    self?.move(to: .newfaces)
                }
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
        static let userProfile = "user_profile_flow"
    }
}

