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
    case main
    case userProfile
}

class RootViewController: BaseViewController {

    var appManager: AppManager!
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    fileprivate var mode: AppUIMode = .unknown
    fileprivate var mainItem: MainNavigationItem = .search
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.appManager = (UIApplication.shared.delegate as! AppDelegate).appManager
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        self.subscribeToAuthState()
        self.subscribeToPhotosState()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == SegueIds.auth, let vc = segue.destination as? AuthViewController {
            vc.input = AuthVMInput(
                apiService: self.appManager.apiService,
                settingsManager: self.appManager.settingsMananger
            )
        }
        
        if segue.identifier == SegueIds.userProfile, let vc = segue.destination as? UserProfilePhotosViewController {
            vc.input = UserProfilePhotosVCInput(
                profileManager: self.appManager.profileManager,
                lmmManager: self.appManager.lmmManager,
                settingsManager: self.appManager.settingsMananger,
                navigationManager: self.appManager.navigationManager
            )
        }
        
        if segue.identifier == SegueIds.main, let vc = segue.destination as? MainViewController {
            vc.input = MainVMInput(
                actionsManager: self.appManager.actionsManager,
                newFacesManager: self.appManager.newFacesManager,
                lmmManager: self.appManager.lmmManager,
                profileManager: self.appManager.profileManager,
                settingsManager: self.appManager.settingsMananger,
                chatManager: self.appManager.chatManager,
                navigationManager: self.appManager.navigationManager
            )
            
            self.appManager.navigationManager.mainItem.accept(self.mainItem)
        }
    }
    
    // MARK: -
    
    fileprivate func move(to: AppUIMode)
    {
        guard to != self.mode else { return }

        self.mode = to

        var segueId = ""
        
        switch to {
        case .unknown: break
        case .auth:
            segueId = SegueIds.auth
        case .main:
            segueId = SegueIds.main
        case .userProfile:
            segueId = SegueIds.main
            self.mainItem = .profile
            break
        }
        
        DispatchQueue.main.async {
            self.dismissPresentedVC({
                self.performSegue(withIdentifier: segueId, sender: nil)
            })
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
                    self?.move(to: .main)
                }
            }
        }).disposed(by: disposeBag)
    }
    
    fileprivate func subscribeToPhotosState()
    {
        self.appManager.profileManager.photos.asObservable().subscribe ({ [weak self] event in
            guard self?.appManager.apiService.isAuthorized.value == true else { return }
            
            if event.element?.count == 0 {
                self?.move(to: .userProfile)
            } else {
                self?.move(to: .main)
            }
        }).disposed(by: disposeBag)
    }
    
    fileprivate func dismissPresentedVC(_ completion: (()->())?)
    {
        guard let presentedVC = self.presentedViewController else {
            completion?()
            
            return
        }
        
        presentedVC.dismiss(animated: false) { [weak self] in
            self?.dismissPresentedVC(completion)
        }
    }
}

extension RootViewController
{
    fileprivate struct SegueIds
    {
        static let auth = "auth_flow"
        static let main = "main_flow"
        static let userProfile = "user_profile_flow"
    }
}

