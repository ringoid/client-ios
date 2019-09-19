//
//  RateUsManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 19/09/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class RateUsManager
{
    private init() {}
    
    static let shared = RateUsManager()
    
    func showAlert(_ from: UIViewController)
    {
        let vc = Storyboards.rateUs().instantiateViewController(withIdentifier: "rate_us") as! RateUsViewController
        vc.modalPresentationStyle = .overFullScreen
        
        from.present(vc, animated: false, completion: nil)
    }
}
