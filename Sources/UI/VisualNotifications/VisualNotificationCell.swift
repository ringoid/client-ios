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
    var onDeletionAnimationFinished: (() -> ())?
    
    fileprivate var hidingTimer: Timer?
    
    @IBOutlet fileprivate weak var containerView: UIView!
    @IBOutlet fileprivate weak var photoView: UIImageView!
    @IBOutlet fileprivate weak var messageLabel: UILabel!
    @IBOutlet fileprivate weak var nameLabel: UILabel!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(panAction(_:)))
        self.containerView.addGestureRecognizer(recognizer)
    }
    
    func startHidingTimer()
    {
        self.containerView.alpha = 1.0
        
        self.hidingTimer?.invalidate()
        self.hidingTimer = nil
        
        let timer = Timer(timeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.hidingTimer = nil
            self?.hideContainer()
        }
        RunLoop.main.add(timer, forMode: .common)
        
        self.hidingTimer = timer
    }
    
    func stopHidingTimer()
    {
        self.hidingTimer?.invalidate()
        self.hidingTimer = nil
        
        let animator = UIViewPropertyAnimator(duration: 0.1, curve: .linear) {
            self.containerView.alpha = 1.0
        }
        animator.startAnimation()        
    }
    
    fileprivate var prevTranslation: CGFloat = 0.0
    
    @objc fileprivate func panAction(_ recognizer: UIPanGestureRecognizer)
    {
        let dx = recognizer.translation(in: self.contentView).x
        
        defer {
            self.prevTranslation = dx
        }
        
        guard recognizer.state != .began else { return }
        
        if recognizer.state == .ended || recognizer.state == .cancelled {
            let center = self.containerView.center
            let normal = dx / abs(dx)
            
            if abs(dx) < 95.0 {
                let animator = UIViewPropertyAnimator(duration: 0.2, dampingRatio: 0.7) {
                    self.containerView.center = CGPoint(
                        x: self.bounds.width / 2.0,
                        y: center.y
                    )
                }
                animator.startAnimation()
            } else {
                let animator = UIViewPropertyAnimator(duration: 0.2, curve: .linear) {
                    self.containerView.center = CGPoint(
                        x: self.bounds.width / 2.0 + (self.containerView.bounds.width + 100.0) * normal,
                        y: center.y
                    )
                }
                animator.addCompletion { _ in
                    self.onDeletionAnimationFinished?()
                }
                animator.startAnimation()
            }
            
            return
        }
                
        let center = self.containerView.center
        
        self.containerView.center = CGPoint(
            x: center.x + (dx - self.prevTranslation),
            y: center.y
        )
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
