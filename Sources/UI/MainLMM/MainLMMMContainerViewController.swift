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
    alpha: 0.35
)

class MainLMMContainerViewController: UIViewController
{
    var input: MainLMMVMInput!
    
    fileprivate var lmmVC: MainLMMViewController?
    
    @IBOutlet weak var likeYouBtn: UIButton!
    @IBOutlet weak var matchesBtn: UIButton!
    @IBOutlet weak var chatBtn: UIButton!
    
    override func viewDidLoad()
    {
        assert( self.input != nil )
        
        super.viewDidLoad()
        
        self.toggle(.likesYou)
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
    
    fileprivate func toggle(_ type: LMMType)
    {
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
