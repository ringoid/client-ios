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
            self.titleLabel.text = self.item.text
            
            if let image = self.item.photoImage  {
                self.photoView.image = image
                
                return
            }
            
            if let url = self.item.photoUrl, let imageData = try? Data(contentsOf: url) {
                self.photoView.image = UIImage(data: imageData)
                
                return
            }
        }
    }
    
    @IBOutlet fileprivate weak var containerView: UIView!
    @IBOutlet fileprivate weak var photoView: UIImageView!
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    
    func startAnimation()
    {
        self.containerView.alpha = 1.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.hideContainer()
        }
    }
    
    // MARK: -
    
    fileprivate func hideContainer()
    {
        let animator = UIViewPropertyAnimator(duration: 1.0, curve: .linear) {
            self.containerView.alpha = 0.0
        }
        
        animator.startAnimation()
    }
}
