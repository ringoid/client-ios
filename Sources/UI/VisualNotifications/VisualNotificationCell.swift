//
//  VisualNotificationCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 27/09/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class VisualNotificaionCell: BaseTableViewCell
{
    var item: VisualNotificationInfo!
    {
        didSet {
            self.messageLabel.text = self.item.text
            self.nameLabel.text = self.item.name
            
            if let image = self.item.photoImage  {
                self.photoView.image = image
                
                return
            }
            
            if let url = self.item.photoUrl {
                self.photoView.image = nil
                ImageService.shared.load(url, thumbnailUrl: nil, to: self.photoView)
                
                return
            }
        }
    }
    
    var onAnimationFinished: (()->())?
    
    @IBOutlet fileprivate weak var containerView: UIView!
    @IBOutlet fileprivate weak var photoView: UIImageView!
    @IBOutlet fileprivate weak var messageLabel: UILabel!
    @IBOutlet fileprivate weak var nameLabel: UILabel!
    
    func startAnimation()
    {
        self.containerView.alpha = 1.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.hideContainer()
        }
    }
    
    // MARK: -
    
    fileprivate func hideContainer()
    {
        let animator = UIViewPropertyAnimator(duration: 1.0, curve: .linear) {
            self.containerView.alpha = 0.0
        }
        
        animator.addCompletion { _ in
            self.onAnimationFinished?()
        }
        
        animator.startAnimation()
    }
}
