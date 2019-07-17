//
//  MainLMMMContainerViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 18/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

var lmmSelectedTitleFont = UIFont.systemFont(ofSize: 16.0, weight: .semibold)
var lmmUnselectedTitleFont = UIFont.systemFont(ofSize: 15.0, weight: .regular)
var lmmSelectedCountFont = UIFont.systemFont(ofSize: 22.0, weight: .bold)
var lmmUnselectedCountFont = UIFont.systemFont(ofSize: 22.0, weight: .semibold)
var lmmSelectedColor = UIColor.white
var lmmUnselectedColor = UIColor(
    red: 160.0 / 255.0,
    green: 160.0 / 255.0,
    blue: 160.0 / 255.0,
    alpha: 1.0
)

class MainLMMContainerViewController: BaseViewController
{
    var input: MainLMMVMInput!
    
    fileprivate static var feedTypeCache: LMMType = .likesYou
    
    fileprivate var lmmVC: MainLMMViewController?
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    @IBOutlet weak var likeYouBtn: UIButton!
    @IBOutlet weak var matchesBtn: UIButton!
    @IBOutlet weak var chatBtn: UIButton!
    
    @IBOutlet weak var likesTitleLabel: UILabel!
    @IBOutlet weak var likesCountLabel: UILabel!
    @IBOutlet weak var matchesTitleLabel: UILabel!
    @IBOutlet weak var matchesCountLabel: UILabel!
    @IBOutlet weak var chatsTitleLabel: UILabel!
    @IBOutlet weak var chatsCountLabel: UILabel!
    
    @IBOutlet weak var chatIndicatorView: UIView!
    @IBOutlet weak var matchesIndicatorView: UIView!
    @IBOutlet weak var likesYouIndicatorView: UIView!
    
    @IBOutlet weak var optionsContainer: UIView!
    @IBOutlet fileprivate weak var notSeenLikesYouWidthConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var notSeenMatchesWidthConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var notSeenMessagesWidthConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var optionsLineLeftOffsetConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var optionLineView: UIView!
    
    override func viewDidLoad()
    {
        assert( self.input != nil )
        
        super.viewDidLoad()
        
        self.toggle(MainLMMContainerViewController.feedTypeCache)
        self.setupBindings()
    }
    
    override func updateLocale()
    {
        self.likesTitleLabel.text = "lmm_tab_likes".localized()
        self.matchesTitleLabel.text = "lmm_tab_matches".localized()
        self.chatsTitleLabel.text = "lmm_tab_messages".localized()
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
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.input.lmmManager.likesYou.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] profiles in
            self?.likesCountLabel.text = "\(profiles.count)"
        }).disposed(by: self.disposeBag)
        
        self.input.lmmManager.matches.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] profiles in
            self?.matchesCountLabel.text = "\(profiles.count)"
        }).disposed(by: self.disposeBag)
        
        self.input.lmmManager.messages.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] profiles in
            self?.chatsCountLabel.text = "\(profiles.count)"
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
            }).startAnimation()
        }).disposed(by: self.disposeBag)
        
        UIManager.shared.chatModeEnabled.asObservable().subscribe(onNext: { [weak self] state in
            UIViewPropertyAnimator(duration: 0.1, curve: .linear, animations: {
                guard let `self` = self else { return }
                
                self.optionsContainer.alpha = state ? 0.0 : 1.0                                
            }).startAnimation()
        }).disposed(by: self.disposeBag)
        
        UIManager.shared.lmmRefreshModeEnabled.asObservable().subscribe(onNext: { [weak self] state in
            let alpha: CGFloat = state ? 0.0 : 1.0
            self?.likesYouIndicatorView.alpha = alpha
            self?.matchesIndicatorView.alpha = alpha
            self?.chatIndicatorView.alpha = alpha
        }).disposed(by: self.disposeBag)
    }
    
    func toggle(_ type: LMMType)
    {
        guard self.input.chatManager.actionsManager.checkConnectionState() else { return }
        
        MainLMMContainerViewController.feedTypeCache = type

        switch type {
        case .likesYou:
            self.likesCountLabel.textColor = lmmSelectedColor
            self.likesCountLabel.font = lmmSelectedCountFont
            self.likesTitleLabel.textColor = lmmSelectedColor
            self.likesTitleLabel.font = lmmSelectedTitleFont
            
            self.matchesCountLabel.textColor = lmmUnselectedColor
            self.matchesCountLabel.font = lmmUnselectedCountFont
            self.matchesTitleLabel.textColor = lmmUnselectedColor
            self.matchesTitleLabel.font = lmmUnselectedTitleFont
            
            self.chatsCountLabel.textColor = lmmUnselectedColor
            self.chatsCountLabel.font = lmmUnselectedCountFont
            self.chatsTitleLabel.textColor = lmmUnselectedColor
            self.chatsTitleLabel.font = lmmUnselectedTitleFont
            
            self.optionsLineLeftOffsetConstraint.constant = 0.0
            UIViewPropertyAnimator(duration: 0.15, curve: .easeOut) {
                self.optionLineView.frame = CGRect(
                    origin: CGPoint(x: 0.0, y: self.optionLineView.frame.origin.y),
                    size: self.optionLineView.bounds.size)
                }.startAnimation()
            break
            
        case .matches:
            self.matchesCountLabel.textColor = lmmSelectedColor
            self.matchesCountLabel.font = lmmSelectedCountFont
            self.matchesTitleLabel.textColor = lmmSelectedColor
            self.matchesTitleLabel.font = lmmSelectedTitleFont
            
            self.likesCountLabel.textColor = lmmUnselectedColor
            self.likesCountLabel.font = lmmUnselectedCountFont
            self.likesTitleLabel.textColor = lmmUnselectedColor
            self.likesTitleLabel.font = lmmUnselectedTitleFont
            
            self.chatsCountLabel.textColor = lmmUnselectedColor
            self.chatsCountLabel.font = lmmUnselectedCountFont
            self.chatsTitleLabel.textColor = lmmUnselectedColor
            self.chatsTitleLabel.font = lmmUnselectedTitleFont
            
            self.optionsLineLeftOffsetConstraint.constant = self.matchesBtn.frame.origin.x
            UIViewPropertyAnimator(duration: 0.15, curve: .easeOut) {
                self.optionLineView.frame = CGRect(
                    origin: CGPoint(x: self.matchesBtn.frame.origin.x, y: self.optionLineView.frame.origin.y),
                    size: self.optionLineView.bounds.size)
                }.startAnimation()
            break
            
        case .messages:
            self.chatsCountLabel.textColor = lmmSelectedColor
            self.chatsCountLabel.font = lmmSelectedCountFont
            self.chatsTitleLabel.textColor = lmmSelectedColor
            self.chatsTitleLabel.font = lmmSelectedTitleFont
            
            self.matchesCountLabel.textColor = lmmUnselectedColor
            self.matchesCountLabel.font = lmmUnselectedCountFont
            self.matchesTitleLabel.textColor = lmmUnselectedColor
            self.matchesTitleLabel.font = lmmUnselectedTitleFont
            
            self.likesCountLabel.textColor = lmmUnselectedColor
            self.likesCountLabel.font = lmmUnselectedCountFont
            self.likesTitleLabel.textColor = lmmUnselectedColor
            self.likesTitleLabel.font = lmmUnselectedTitleFont
            
            self.optionsLineLeftOffsetConstraint.constant = self.chatBtn.frame.origin.x
            
            UIViewPropertyAnimator(duration: 0.15, curve: .easeOut) {
                self.optionLineView.frame = CGRect(
                    origin: CGPoint(x: self.chatBtn.frame.origin.x, y: self.optionLineView.frame.origin.y),
                    size: self.optionLineView.bounds.size)
            }.startAnimation()
            break
            
        default: return
        }

        self.lmmVC?.type.accept(type)
    }
}
