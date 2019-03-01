//
//  NoConnectionViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 27/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

struct NoConnectionVCInput
{
    let reachability: ReachabilityService
}

class NoConnectionViewController: BaseViewController
{
    var input: NoConnectionVCInput!
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    @IBOutlet fileprivate weak var noConnectionLabel: UILabel!
    @IBOutlet fileprivate weak var retryBtn: UIButton!
    @IBOutlet fileprivate weak var iconImageView: UIImageView!
    @IBOutlet fileprivate weak var activityView: UIActivityIndicatorView!
    
    static func create(_ input: NoConnectionVCInput) -> NoConnectionViewController
    {
        let storyboard = Storyboards.root()
        let vc = storyboard.instantiateViewController(withIdentifier: "no_connection_vc") as! NoConnectionViewController
        vc.input = input
        
        return vc
    }
    
    override var prefersStatusBarHidden: Bool
    {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle
    {
        return ThemeManager.shared.theme.value == .dark ? .lightContent : .default
    }
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        self.activityView.stopAnimating()
    }
    
    override func updateTheme()
    {
        self.view.backgroundColor = BackgroundColor().uiColor()
        self.noConnectionLabel.textColor = ThirdContentColor().uiColor()
        self.iconImageView.tintColor = ThirdContentColor().uiColor()
    }
    
    override func updateLocale()
    {
        self.noConnectionLabel.text = "error_screen_no_network_connection".localized()
        self.retryBtn.setTitle("error_screen_no_network_connection_button_label".localized(), for: .normal)
    }
    
    // MARK: - Actions
    
    @IBAction fileprivate func onRetry()
    {
        self.retryBtn.isHidden = true
        self.activityView.startAnimating()
        self.input.reachability.check().subscribe(onNext: { [weak self] state in
            guard state else {
                self?.activityView.stopAnimating()
                self?.retryBtn.isHidden = false
                
                return
            }
            
            self?.dismiss(animated: false, completion: nil)
        }).disposed(by: self.disposeBag)
    }
}
