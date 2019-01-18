//
//  MainLMMMContainerViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 18/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

class MainLMMContainerViewController: UIViewController
{
    var input: MainLMMVMInput!
    
    fileprivate var lmmVC: MainLMMViewController?
    
    @IBOutlet weak var likeYouBtn: UIButton!
    @IBOutlet weak var matchesBtn: UIButton!
    
    override func viewDidLoad()
    {
        assert( self.input != nil )
        
        super.viewDidLoad()
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
        self.lmmVC?.type.accept(.likesYou)
    }
    
    @IBAction func onMatchesSelected()
    {
        self.lmmVC?.type.accept(.matches)
    }
}
