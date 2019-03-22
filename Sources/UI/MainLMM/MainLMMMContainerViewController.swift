//
//  MainLMMMContainerViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 18/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

fileprivate let selectedFont = UIFont.systemFont(ofSize: 18.0, weight: .bold
)
fileprivate let unselectedFont = UIFont.systemFont(ofSize: 17.0, weight: .regular)
fileprivate let selectedColor = UIColor.white
fileprivate let unselectedColor = UIColor(
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
    
    override func viewDidLoad()
    {
        assert( self.input != nil )
        
        super.viewDidLoad()
        
        self.toggle(MainLMMContainerViewController.feedTypeCache)
        self.setupBindings()
    }
    
    override func updateLocale()
    {
        self.chatBtn.setTitle("lmm_tab_messenger".localized(), for: .normal)
        self.likeYouBtn.setTitle("lmm_tab_likes".localized(), for: .normal)
        self.matchesBtn.setTitle("lmm_tab_matches".localized(), for: .normal)
        
        self.updateBtnSizes()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "embed_lmm", let vc = segue.destination as? MainLMMViewController {
            vc.input = self.input

            self.lmmVC = vc
        }
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
        self.input.lmmManager.notSeenLikesYouCount.subscribe(onNext: { [weak self] count in
            self?.likesYouIndicatorView.isHidden = count == 0
        }).disposed(by: self.disposeBag)
        
        self.input.lmmManager.notSeenMatchesCount.subscribe(onNext: { [weak self] count in
            self?.matchesIndicatorView.isHidden = count == 0
        }).disposed(by: self.disposeBag)
        
        self.input.lmmManager.notSeenMessagesCount.subscribe(onNext: { [weak self] count in
            self?.chatIndicatorView.isHidden = count == 0
        }).disposed(by: self.disposeBag)
        
        UIManager.shared.blockModeEnabled.asObservable().subscribe(onNext: { [weak self] state in
            UIViewPropertyAnimator(duration: 0.1, curve: .linear, animations: {
                self?.optionsContainer.alpha = state ? 0.0 : 1.0
            }).startAnimation()
        }).disposed(by: self.disposeBag)
        
        UIManager.shared.chatModeEnabled.asObservable().subscribe(onNext: { [weak self] state in
            UIViewPropertyAnimator(duration: 0.1, curve: .linear, animations: {
                self?.optionsContainer.alpha = state ? 0.0 : 1.0
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
            self.likeYouBtn.setTitleColor(selectedColor, for: .normal)
            self.likeYouBtn.titleLabel?.font = selectedFont
            self.matchesBtn.setTitleColor(unselectedColor, for: .normal)
            self.matchesBtn.titleLabel?.font = unselectedFont
            self.chatBtn.setTitleColor(unselectedColor, for: .normal)
            self.chatBtn.titleLabel?.font = unselectedFont
            break
            
        case .matches:
            self.matchesBtn.setTitleColor(selectedColor, for: .normal)
            self.matchesBtn.titleLabel?.font = selectedFont
            self.likeYouBtn.setTitleColor(unselectedColor, for: .normal)
            self.likeYouBtn.titleLabel?.font = unselectedFont
            self.chatBtn.setTitleColor(unselectedColor, for: .normal)
            self.chatBtn.titleLabel?.font = unselectedFont
            break
            
        case .messages:
            self.chatBtn.setTitleColor(selectedColor, for: .normal)
            self.chatBtn.titleLabel?.font = selectedFont
            self.likeYouBtn.setTitleColor(unselectedColor, for: .normal)
            self.likeYouBtn.titleLabel?.font = unselectedFont
            self.matchesBtn.setTitleColor(unselectedColor, for: .normal)
            self.matchesBtn.titleLabel?.font = unselectedFont
            break
        }
        
        self.lmmVC?.type.accept(type)
    }
    
    fileprivate func updateBtnSizes()
    {
        let matchesWidth = ("lmm_tab_matches".localized() as NSString).boundingRect(
            with: CGSize(width: 300.0, height: 200.0),
            options: .usesLineFragmentOrigin,
            attributes: [.font: unselectedFont],
            context: nil
            ).width
        
        let likesWidth = ("lmm_tab_likes".localized() as NSString).boundingRect(
            with: CGSize(width: 300.0, height: 200.0),
            options: .usesLineFragmentOrigin,
            attributes: [.font: unselectedFont],
            context: nil
            ).width
        
        let chatsWidth = ("lmm_tab_messenger".localized() as NSString).boundingRect(
            with: CGSize(width: 300.0, height: 200.0),
            options: .usesLineFragmentOrigin,
            attributes: [.font: unselectedFont],
            context: nil
            ).width
        
        self.matchesBtnWidthLayout.constant = matchesWidth + 20.0
        self.tabsCenterConstraint.constant = (likesWidth - chatsWidth) / 2.0
        self.view.layoutSubviews()
    }
}
