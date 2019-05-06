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
    
    @IBOutlet weak var likeYouBtn: UIButton!
    @IBOutlet weak var matchesBtn: UIButton!
    @IBOutlet weak var chatBtn: UIButton!
    @IBOutlet weak var chatIndicatorView: UIView!
    @IBOutlet weak var matchesIndicatorView: UIView!
    @IBOutlet weak var likesYouIndicatorView: UIView!
    @IBOutlet weak var optionsContainer: UIView!
    @IBOutlet weak var matchesBtnWidthLayout: NSLayoutConstraint!
    @IBOutlet weak var tabsCenterConstraint: NSLayoutConstraint!
    @IBOutlet weak var messagesIndicatorConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var topShadowView: UIView!
    
    override func viewDidLoad()
    {
        assert( self.input != nil )
        
        super.viewDidLoad()
        
        self.toggle(MainLMMContainerViewController.feedTypeCache)
        self.setupBindings()
    }
    
    override func updateLocale()
    {
        self.chatBtn.setTitle("lmm_tab_hellos".localized(), for: .normal)
        self.likeYouBtn.setTitle("lmm_tab_likes".localized(), for: .normal)
        self.matchesBtn.setTitle("lmm_tab_matches".localized(), for: .normal)
        
        self.updateBtnSizes()
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
        self.toggle(.hellos)
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.input.lmmManager.notSeenLikesYouCount.subscribe(onNext: { [weak self] count in
            self?.likesYouIndicatorView.isHidden = count == 0
        }).disposed(by: self.disposeBag)
        
        self.input.lmmManager.notSeenMatchesCount.subscribe(onNext: { [weak self] count in
            self?.matchesIndicatorView.isHidden = count == 0
        }).disposed(by: self.disposeBag)
        
        self.input.lmmManager.notSeenHellosCount.subscribe(onNext: { [weak self] count in
            self?.chatIndicatorView.isHidden = count == 0
        }).disposed(by: self.disposeBag)
        
        UIManager.shared.blockModeEnabled.asObservable().subscribe(onNext: { [weak self] state in
            UIViewPropertyAnimator(duration: 0.1, curve: .linear, animations: {
                self?.optionsContainer.alpha = state ? 0.0 : 1.0
                self?.topShadowView.isHidden = state
            }).startAnimation()
        }).disposed(by: self.disposeBag)
        
        UIManager.shared.chatModeEnabled.asObservable().subscribe(onNext: { [weak self] state in
            UIViewPropertyAnimator(duration: 0.1, curve: .linear, animations: {
                self?.optionsContainer.alpha = state ? 0.0 : 1.0
                self?.topShadowView.isHidden = state
            }).startAnimation()
        }).disposed(by: self.disposeBag)
        
        UIManager.shared.lmmRefreshModeEnabled.asObservable().subscribe(onNext: { [weak self] state in
            let alpha: CGFloat = state ? 0.0 : 1.0
            self?.likesYouIndicatorView.alpha = alpha
            self?.matchesIndicatorView.alpha = alpha
            self?.chatIndicatorView.alpha = alpha
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func toggle(_ type: LMMType)
    {
        guard self.input.chatManager.actionsManager.checkConnectionState() else { return }
        
        MainLMMContainerViewController.feedTypeCache = type

        switch type {
        case .likesYou:
            self.likeYouBtn.setTitleColor(lmmSelectedColor, for: .normal)
            self.likeYouBtn.titleLabel?.font = lmmSelectedFont
            self.matchesBtn.setTitleColor(lmmUnselectedColor, for: .normal)
            self.matchesBtn.titleLabel?.font = lmmUnselectedFont
            self.chatBtn.setTitleColor(lmmUnselectedColor, for: .normal)
            self.chatBtn.titleLabel?.font = lmmUnselectedFont
            break
            
        case .matches:
            self.matchesBtn.setTitleColor(lmmSelectedColor, for: .normal)
            self.matchesBtn.titleLabel?.font = lmmSelectedFont
            self.likeYouBtn.setTitleColor(lmmUnselectedColor, for: .normal)
            self.likeYouBtn.titleLabel?.font = lmmUnselectedFont
            self.chatBtn.setTitleColor(lmmUnselectedColor, for: .normal)
            self.chatBtn.titleLabel?.font = lmmUnselectedFont
            break
            
        case .hellos:
            self.chatBtn.setTitleColor(lmmSelectedColor, for: .normal)
            self.chatBtn.titleLabel?.font = lmmSelectedFont
            self.likeYouBtn.setTitleColor(lmmUnselectedColor, for: .normal)
            self.likeYouBtn.titleLabel?.font = lmmUnselectedFont
            self.matchesBtn.setTitleColor(lmmUnselectedColor, for: .normal)
            self.matchesBtn.titleLabel?.font = lmmUnselectedFont
            break
            
        default: return
        }
        
        self.lmmVC?.type.accept(type)
    }
    
    fileprivate func updateBtnSizes()
    {
        let matchesWidth = ("lmm_tab_matches".localized() as NSString).boundingRect(
            with: CGSize(width: 300.0, height: 200.0),
            options: .usesLineFragmentOrigin,
            attributes: [.font: lmmUnselectedFont],
            context: nil
            ).width
        
        let likesWidth = ("lmm_tab_likes".localized() as NSString).boundingRect(
            with: CGSize(width: 300.0, height: 200.0),
            options: .usesLineFragmentOrigin,
            attributes: [.font: lmmUnselectedFont],
            context: nil
            ).width
        
        let chatsWidth = ("lmm_tab_hellos".localized() as NSString).boundingRect(
            with: CGSize(width: 300.0, height: 200.0),
            options: .usesLineFragmentOrigin,
            attributes: [.font: lmmUnselectedFont],
            context: nil
            ).width
        
        if likesWidth + matchesWidth + chatsWidth > UIScreen.main.bounds.width - 50.0
        {
            lmmUnselectedFont = UIFont.systemFont(ofSize: 15.0, weight: .regular)
            lmmSelectedFont = UIFont.systemFont(ofSize: 16.0, weight: .bold)
            
            self.updateBtnSizes()
            return
        }
        
        self.matchesBtnWidthLayout.constant = matchesWidth + 20.0
        self.tabsCenterConstraint.constant = (likesWidth - chatsWidth) / 2.0
        self.messagesIndicatorConstraint.constant = chatsWidth + 10.0
        self.view.layoutSubviews()
    }
}
