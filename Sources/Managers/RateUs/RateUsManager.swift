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
    
    func showAlertIfNeeded(_ from: UIViewController)
    {
        self.showAlert(from)
    }
    
    func showAlert(_ from: UIViewController)
    {
        let vc = Storyboards.rateUs().instantiateViewController(withIdentifier: "rate_us") as! RateUsViewController
        vc.modalPresentationStyle = .overFullScreen
        vc.onLowRate = {
            FeedbackManager.shared.showSuggestion(from, source: .chat, feedSource: .messages)
        }
        
        vc.view.alpha = 0.0
        
        from.present(vc, animated: false, completion: {
            let animator = UIViewPropertyAnimator(duration: 0.2, curve: .easeOut) {
                vc.view.alpha = 1.0
            }
            animator.startAnimation()
        })
    }
}
