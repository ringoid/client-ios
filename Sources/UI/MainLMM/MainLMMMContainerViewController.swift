//
//  MainLMMMContainerViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 18/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

var lmmSelectedFont = UIFont.systemFont(ofSize: 18.0, weight: .bold)
var lmmUnselectedFont = UIFont.systemFont(ofSize: 17.0, weight: .regular)
var lmmSelectedColor = UIColor.white
var lmmUnselectedColor = UIColor(
    red: 219.0 / 255.0,
    green: 219.0 / 255.0,
    blue: 219.0 / 255.0,
    alpha: 1.0
)

class MainLMMContainerViewController: BaseViewController
{
    var input: MainLMMVMInput!
    
    fileprivate static var feedTypeCache: LMMType = .likesYou
    
    fileprivate var lmmVC: MainLMMViewController?
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    fileprivate var isBannerClosedManually: Bool = false
    
    @IBOutlet weak var likeYouBtn: UIButton!
    @IBOutlet weak var matchesBtn: UIButton!
    @IBOutlet weak var chatBtn: UIButton!
    @IBOutlet weak var chatIndicatorView: UIView!
    @IBOutlet weak var matchesIndicatorView: UIView!
    @IBOutlet weak var likesYouIndicatorView: UIView!
    @IBOutlet weak var optionsContainer: UIView!
    @IBOutlet fileprivate weak var topShadowView: UIView!
    @IBOutlet fileprivate weak var notificationsBannerView: UIView!
    @IBOutlet fileprivate weak var notificationsBannerLabel: UILabel!
    @IBOutlet fileprivate weak var notificationsBannerSubLabel: UILabel!
    @IBOutlet fileprivate weak var notSeenLikesYouWidthConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var notSeenMatchesWidthConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var notSeenMessagesWidthConstraint: NSLayoutConstraint!
    
    override func viewDidLoad()
    {
        assert( self.input != nil )
        
        super.viewDidLoad()
        
        self.toggle(MainLMMContainerViewController.feedTypeCache)
        self.setupBindings()
    }
    
    override func updateLocale()
    {
        self.notificationsBannerLabel.text = "settings_notifications_banner_title".localized()
        self.notificationsBannerSubLabel.text = "settings_notifications_banner_subtitle".localized()
    }
    
    override func updateTheme()
    {
        self.view.backgroundColor = BackgroundColor().uiColor()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "embed_lmm", let vc = segue.destination as? MainLMMViewController {
            vc.input = self.input

            self.lmmVC = vc
        }
    }
    
    func prepareForNavigation()
    {
        DispatchQueue.main.async {
            self.lmmVC?.prepareForNavigation()
        }
    }
    
    func reload()
    {
        self.lmmVC?.reload()
    }
    
    // MARK: - Actions
    
    @IBAction func onLikesYouSelected()
    {
        self.toggle(.likesYou)
    }
    
    @IBAction func onMatchesSelected()
    {
        self.toggle(.matches)
    }
    
    @IBAction func onChatSelected()
    {
        self.toggle(.messages)
    }
    
    @IBAction fileprivate func onBannerTap()
    {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
        
        self.closeBanner()
    }
    
    @IBAction fileprivate func onBannerClose()
    {
        self.isBannerClosedManually = true
        
        self.closeBanner()
    }
    
    fileprivate func closeBanner()
    {
        let animator = UIViewPropertyAnimator(duration: 0.1, curve: .easeIn) { [weak self] in
            self?.notificationsBannerView.alpha = 0.0
        }
        
        animator.addCompletion { [weak self] _ in
            self?.notificationsBannerView.isHidden = true
            self?.notificationsBannerView.alpha = 1.0
        }
        
        animator.startAnimation()
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.input.lmmManager.likesYou.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] profiles in
            let title: String? = profiles.count != 0 ? "\(profiles.count)" : nil
            self?.likeYouBtn.setTitle(title, for: .normal)
        }).disposed(by: self.disposeBag)
        
        self.input.lmmManager.matches.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] profiles in
            let title: String? = profiles.count != 0 ? "\(profiles.count)" : nil
            self?.matchesBtn.setTitle(title, for: .normal)
        }).disposed(by: self.disposeBag)
        
        self.input.lmmManager.messages.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] profiles in
            let title: String? = profiles.count != 0 ? "\(profiles.count)" : nil
            self?.chatBtn.setTitle(title, for: .normal)
        }).disposed(by: self.disposeBag)
        
        self.input.lmmManager.notSeenLikesYouCount.subscribe(onNext: { [weak self] count in
            guard let `self` = self else { return }
            
            self.likesYouIndicatorView.isHidden = count == 0
        }).disposed(by: self.disposeBag)
        
        self.input.lmmManager.notSeenMatchesCount.subscribe(onNext: { [weak self] count in
            guard let `self` = self else { return }
            
            self.matchesIndicatorView.isHidden = count == 0
        }).disposed(by: self.disposeBag)
        
        self.input.lmmManager.notSeenMessagesCount.subscribe(onNext: { [weak self] count in
            guard let `self` = self else { return }
            
            self.chatIndicatorView.isHidden = count == 0
        }).disposed(by: self.disposeBag)
        
        UIManager.shared.blockModeEnabled.asObservable().subscribe(onNext: { [weak self] state in
            UIViewPropertyAnimator(duration: 0.1, curve: .linear, animations: {
                self?.optionsContainer.alpha = state ? 0.0 : 1.0
                self?.topShadowView.isHidden = state
            }).startAnimation()
        }).disposed(by: self.disposeBag)
        
        UIManager.shared.chatModeEnabled.asObservable().subscribe(onNext: { [weak self] state in
            UIViewPropertyAnimator(duration: 0.1, curve: .linear, animations: {
                guard let `self` = self else { return }
                
                self.optionsContainer.alpha = state ? 0.0 : 1.0
                self.topShadowView.isHidden = state
                
                if state  {
                    self.notificationsBannerView.isHidden = true
                } else {
                    if self.input.notifications.isRegistered {
                        self.notificationsBannerView.isHidden = self.input.notifications.isGranted.value || self.isBannerClosedManually
                    }
                }
            }).startAnimation()
        }).disposed(by: self.disposeBag)
        
        UIManager.shared.lmmRefreshModeEnabled.asObservable().subscribe(onNext: { [weak self] state in
            let alpha: CGFloat = state ? 0.0 : 1.0
            self?.likesYouIndicatorView.alpha = alpha
            self?.matchesIndicatorView.alpha = alpha
            self?.chatIndicatorView.alpha = alpha
        }).disposed(by: self.disposeBag)
        
        self.input.notifications.isGranted.observeOn(MainScheduler.instance).subscribe(onNext:{ [weak self] _ in
            guard let `self` = self else { return }
            guard self.input.notifications.isRegistered else { return }
            
            self.notificationsBannerView.isHidden = self.input.notifications.isGranted.value || self.isBannerClosedManually
        }).disposed(by: self.disposeBag)
    }
    
    func toggle(_ type: LMMType)
    {
        guard self.input.chatManager.actionsManager.checkConnectionState() else { return }
        
        MainLMMContainerViewController.feedTypeCache = type

        switch type {
        case .likesYou:
            self.likeYouBtn.setImage(UIImage(named: "main_bar_like_selected"), for: .normal)
            self.matchesBtn.setImage(UIImage(named: "main_bar_like"), for: .normal)
            self.chatBtn.setImage(UIImage(named: "main_bar_like"), for: .normal)
            break
            
        case .matches:
            self.matchesBtn.setImage(UIImage(named: "main_bar_like_selected"), for: .normal)
            self.likeYouBtn.setImage(UIImage(named: "main_bar_like"), for: .normal)
            self.chatBtn.setImage(UIImage(named: "main_bar_like"), for: .normal)
            break
            
        case .messages:
            self.chatBtn.setImage(UIImage(named: "main_bar_like_selected"), for: .normal)
            self.matchesBtn.setImage(UIImage(named: "main_bar_like"), for: .normal)
            self.likeYouBtn.setImage(UIImage(named: "main_bar_like"), for: .normal)
            break
            
        default: return
        }
        
        self.lmmVC?.type.accept(type)
    }
}
