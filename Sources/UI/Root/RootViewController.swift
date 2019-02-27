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
    
    @IBOutlet fileprivate weak var containerView: ContainerView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.appManager = (UIApplication.shared.delegate as! AppDelegate).appManager
        self.subscribeToAuthState()
        self.subscribeToNoConnectionState()
    }

    override func updateTheme()
    {
        self.view.backgroundColor = BackgroundColor().uiColor()
    }
    
    // MARK: -
    
    fileprivate func move(to: AppUIMode)
    {
        guard to != self.mode else { return }

        self.mode = to
        
        switch to {
        case .unknown: break
        case .auth:
            self.embedAuthVC()
        case .main:
            self.embedMainVC()
            self.appManager.navigationManager.mainItem.accept(.profileAndFetch)
        case .userProfile:
            self.embedMainVC()
            self.appManager.navigationManager.mainItem.accept(.profile)
            break
        }
    }
    
    fileprivate func embedMainVC()
    {
        let vc = MainViewController.create()
        vc.input = MainVMInput(
            actionsManager: self.appManager.actionsManager,
            newFacesManager: self.appManager.newFacesManager,
            lmmManager: self.appManager.lmmManager,
            profileManager: self.appManager.profileManager,
            settingsManager: self.appManager.settingsMananger,
            chatManager: self.appManager.chatManager,
            navigationManager: self.appManager.navigationManager
        )
        
        self.containerView.embed(vc, to: self)
    }
    
    fileprivate func embedAuthVC()
    {
        self.presentedViewController?.dismiss(animated: false, completion: nil)
        let vc = AuthViewController.create()
        vc.input = AuthVMInput(
            apiService: self.appManager.apiService,
            settingsManager: self.appManager.settingsMananger
        )
        
        self.containerView.embed(vc, to: self)
    }
    
    fileprivate func showNoConnection()
    {
        let storyboard = Storyboards.root()
        let vc = storyboard.instantiateViewController(withIdentifier: "no_connection_vc")
        
        self.present(vc, animated: false, completion: nil)
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
    
    fileprivate func subscribeToNoConnectionState()
    {
        self.appManager.errorsManager.disconnection.asObservable().subscribe(onNext: { [weak self] _ in
            self?.showNoConnection()
        }).disposed(by: self.disposeBag)
    }
}
