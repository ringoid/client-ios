//
//  MainLMMMContainerViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 18/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

fileprivate let selectedFont = UIFont.systemFont(ofSize: 17.0, weight: .medium)
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
    
    override func viewDidLoad()
    {
        assert( self.input != nil )
        
        super.viewDidLoad()
        
        self.toggle(MainLMMContainerViewController.feedTypeCache)
        self.setupBindings()
    }
    
    override func updateLocale()
    {
        self.chatBtn.setTitle("LMM_HEADER_CHATS_OPTION".localized(), for: .normal)
        self.likeYouBtn.setTitle("LMM_HEADER_LIKES_OPTION".localized(), for: .normal)
        self.matchesBtn.setTitle("LMM_HEADER_MATCHES_OPTION".localized(), for: .normal)
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
    }
    
    fileprivate func toggle(_ type: LMMType)
    {
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
}
