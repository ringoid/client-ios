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

    @IBOutlet weak var optionsContainer: UIView!
    
    override func viewDidLoad()
    {
        assert( self.input != nil )
        
        super.viewDidLoad()
        
        self.toggle(MainLMMContainerViewController.feedTypeCache)
        self.setupBindings()
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
        self.lmmVC?.reload(false)
    }
    
    // MARK: - Actions
    
    @IBAction func onLikesYouSelected()
    {
        self.toggle(.likesYou)
    }
    
    @IBAction func onChatSelected()
    {
        self.toggle(.messages)
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
//        UIManager.shared.blockModeEnabled.asObservable().subscribe(onNext: { [weak self] state in
//            UIViewPropertyAnimator(duration: 0.1, curve: .linear, animations: {
//                self?.optionsContainer.alpha = state ? 0.0 : 1.0
//            }).startAnimation()
//        }).disposed(by: self.disposeBag)
        
//        UIManager.shared.chatModeEnabled.asObservable().subscribe(onNext: { [weak self] state in
//            UIViewPropertyAnimator(duration: 0.1, curve: .linear, animations: {
//                guard let `self` = self else { return }
//
//                self.optionsContainer.alpha = state ? 0.0 : 1.0
//            }).startAnimation()
//        }).disposed(by: self.disposeBag)
    }
    
    func toggle(_ type: LMMType)
    {
        guard self.input.chatManager.actionsManager.checkConnectionState() else { return }
        
        MainLMMContainerViewController.feedTypeCache = type
        self.lmmVC?.type.accept(type)
    }
}
