//
//  ModalUIManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 16/05/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class ModalUIManager
{
    var backgroundView: UIView!
    var containerView: ContainerView!
    var containerVC: UIViewController!
    
    func show(_ vc: UIViewController, animated: Bool)
    {
        self.containerView.embed(vc, to: containerVC)
        
        if animated {
            let animator = UIViewPropertyAnimator(duration: 0.35, curve: .easeIn) {
                self.backgroundView.alpha = 1.0
            }
            animator.startAnimation()
        } else {
            self.backgroundView.alpha = 1.0            
        }
    }
    
    func hide(animated: Bool)
    {
        if animated {
            let animator = UIViewPropertyAnimator(duration: 0.35, curve: .easeIn) {
                self.backgroundView.alpha = 0.0
            }
            animator.addCompletion { _ in
                self.containerView.remove()
            }
            
            animator.startAnimation()
        } else {
            self.backgroundView.alpha = 0.0
            self.containerView.remove()
        }
    }
}
