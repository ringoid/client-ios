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
import MessageUI

fileprivate enum AppUIMode
{
    case unknown
    case auth
    case main
    case search
    case userProfile
}

class RootViewController: BaseViewController {

    var appManager: AppManager!
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    fileprivate var mode: AppUIMode = .unknown
    fileprivate var prevOldVersionState: Bool = false
    fileprivate var prevNoConnectionState: Bool = false
    
    @IBOutlet fileprivate weak var containerView: ContainerView!
    @IBOutlet fileprivate weak var debugTextView: UITextView!
    @IBOutlet fileprivate weak var modalContainerView: ContainerView!
    @IBOutlet fileprivate weak var modalBackgroundView: UIView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.appManager = (UIApplication.shared.delegate as! AppDelegate).appManager
        self.setupModalManager()
        self.subscribeToAuthState()
        self.subscribeToNoConnectionState()
        self.subscribeToOldVersionState()
        self.subscribeToSomethingWentWrong()
        
        #if STAGE
        self.subscribeForDebugLog()
        #endif
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
        
        ModalUIManager.shared.hide(animated: false)
                
        switch to {
        case .unknown: break
        case .auth: self.embedAuthVC()
        case .main:
            self.embedMainVC()
            self.appManager.navigationManager.mainItem.accept(.profileAndFetch)
            break
            
        case .search:
            self.embedMainVC()
            DispatchQueue.main.async {
                self.appManager.navigationManager.mainItem.accept(.searchAndFetch)
            }
            break
            
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
            navigationManager: self.appManager.navigationManager,
            errorsManager: self.appManager.errorsManager,
            promotionManager: self.appManager.promotionManager,
            device: self.appManager.deviceService,
            notifications: self.appManager.notifications,
            location: self.appManager.locationManager,
            scenario: self.appManager.scenarioManager,
            transition: self.appManager.transitionManager,
            db: self.appManager.db,
            filter: self.appManager.filterManager,
            impact: self.appManager.impact,
            achivement: self.appManager.achivementManager
        )
        
        self.containerView.embed(vc, to: self)
    }
    
    fileprivate func embedAuthVC()
    {
        self.presentedViewController?.dismiss(animated: false, completion: nil)
        ModalUIManager.shared.hide(animated: false)
        
        let vc = AuthViewController.create()
        vc.input = AuthVMInput(
            apiService: self.appManager.apiService,
            settingsManager: self.appManager.settingsMananger,
            promotionManager: self.appManager.promotionManager,
            locationManager: self.appManager.locationManager,
            profileManager: self.appManager.profileManager
        )
        
        self.containerView.embed(vc, to: self)
    }
    
    fileprivate func showNoConnection()
    {
        let vc = NoConnectionViewController.create(NoConnectionVCInput(reachability: self.appManager.reachability))
        
        if self.presentedViewController != nil {
            self.presentedViewController?.dismiss(animated: false, completion: {
                self.present(vc, animated: false, completion: nil)
            })
        } else {
            self.present(vc, animated: false, completion: nil)
        }
    }
    
    fileprivate func showOldVersion()
    {
        let vc = UpdateVersionViewController.create()
     
        if self.presentedViewController != nil {
            self.presentedViewController?.dismiss(animated: false, completion: {
                self.present(vc, animated: false, completion: nil)
            })
        } else {
            self.present(vc, animated: false, completion: nil)
        }
    }
    
    fileprivate func showErrorStatus(_ text: String)
    {
        let alertVC = UIAlertController(
            title: "error_common".localized(),
            message: text,
            preferredStyle: .alert
        )
        
        alertVC.addAction(UIAlertAction(title: "settings_support".localized(), style: .default, handler: { _ in
            guard MFMailComposeViewController.canSendMail() else { return }
            
            let vc = MFMailComposeViewController()
            vc.setToRecipients(["support@ringoid.com"])
            vc.mailComposeDelegate = self
            
            self.present(vc, animated: true, completion: nil)
        }))
        alertVC.addAction(UIAlertAction(title: "button_close".localized(), style: .cancel, handler: nil))
        
        if self.presentedViewController != nil {
            self.presentedViewController?.dismiss(animated: false, completion: {
                self.present(alertVC, animated: true, completion: nil)
            })
        } else {
            self.present(alertVC, animated: true, completion: nil)
        }
    }
    
    fileprivate func subscribeToAuthState()
    {
        self.appManager.apiService.isAuthorized.asObservable().subscribe ({ [weak self] event in
            if event.element != true {
                self?.move(to: .auth)
                DispatchQueue.main.async {
                    self?.appManager.settingsMananger.reset()
                }
            } else {
                if self?.appManager.settingsMananger.isFirstLaunch.value == true {
                    self?.move(to: .search)
                    self?.appManager.settingsMananger.isFirstLaunch.accept(false)
                } else {
                    self?.move(to: .search)
                }
            }
        }).disposed(by: disposeBag)
    }
    
    fileprivate func subscribeToNoConnectionState()
    {
        self.appManager.actionsManager.isInternetAvailable.asObservable().subscribe(onNext: { [weak self] state in
            guard state != self?.prevNoConnectionState else { return }
            
            self?.prevNoConnectionState = state
            
            guard !state else { return }
            
            self?.showNoConnection()
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func subscribeToOldVersionState()
    {
        self.appManager.errorsManager.oldVersion.asObservable().subscribe(onNext: { [weak self] state in
            guard state != self?.prevOldVersionState else { return }
            
            self?.prevOldVersionState = state
            
            guard state else { return }
            
            self?.showOldVersion()
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func subscribeToSomethingWentWrong()
    {
        self.appManager.errorsManager.somethingWentWrong.asObservable().subscribe(onNext: { [weak self] text in
            guard let text = text else { return }
            
            self?.showErrorStatus(text)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func subscribeForDebugLog()
    {
        LogService.shared.records.observeOn(MainScheduler.instance).asObservable().subscribe(onNext: { [weak self] _ in
            self?.debugTextView.text = LogService.shared.asShortText()
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func setupModalManager()
    {
        ModalUIManager.shared.containerVC = self
        ModalUIManager.shared.containerView = self.modalContainerView
        ModalUIManager.shared.backgroundView = self.modalBackgroundView
    }
}

extension RootViewController: MFMailComposeViewControllerDelegate
{
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        controller.dismiss(animated: true, completion: nil)
    }
}

#if STAGE
extension RootViewController
{
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?)
    {
        self.debugTextView.isHidden = !self.debugTextView.isHidden
    }
}
#endif
