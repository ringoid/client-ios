//
//  GlobalAnimationManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 26/04/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class GlobalAnimationManager
{
    var animationView: UIView!
    
    static let shared: GlobalAnimationManager = GlobalAnimationManager()
    
    private init() {}
    
    func performAnimation(_ animationBlock: ((UIView)->())?)
    {
        animationBlock?(animationView)
    }
    
    func playFlyUpIconAnimation(_ icon: UIImage, from: UIView, point: CGPoint, scaleFactor: CGFloat = 1.0)
    {
        let duration: Double = 1.0
        
        let startTransform = CATransform3DMakeAffineTransform(CGAffineTransform(scaleX: 0.5, y: 0.5))
        let endTransform = CATransform3DMakeAffineTransform(CGAffineTransform(scaleX: 3.5 * scaleFactor, y: 3.5 * scaleFactor).concatenating(CGAffineTransform(translationX: 200.0 * sin(CGFloat.random(in: 0.0...2 * .pi)) , y: -400.0)))
        
        let iconLayer: CALayer = CALayer()
        iconLayer.frame = CGRect(x: 0.0, y: 0.0, width: icon.size.width, height: icon.size.height)
        iconLayer.contents = icon.cgImage
        iconLayer.transform = startTransform
        
        let absolutePoint = self.animationView.convert(point, from: from)
        iconLayer.position = absolutePoint
        
        self.animationView.layer.addSublayer(iconLayer)
        
        let scaleAnimation = CABasicAnimation(keyPath: "transform")
        scaleAnimation.duration = duration
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        scaleAnimation.fromValue = startTransform
        scaleAnimation.toValue = endTransform
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.duration = duration
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        opacityAnimation.fromValue = 1.0
        opacityAnimation.toValue = 0.0

        let group = CAAnimationGroup()
        group.duration = duration
        group.animations = [scaleAnimation, opacityAnimation]
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false
        group.completion = { [weak iconLayer] _ in
            iconLayer?.removeFromSuperlayer()
        }
        
        iconLayer.add(group, forKey: "icon_animations")
    }
    
    func playDropDownIconAnimation(_ icon: UIImage, from: UIView, point: CGPoint)
    {
        let duration: Double = 1.0
        
        let startTransform = CATransform3DMakeAffineTransform(CGAffineTransform(scaleX: 0.5, y: 0.5))
        let endTransform = CATransform3DMakeAffineTransform(CGAffineTransform(scaleX: 2.0, y: 2.0).concatenating(CGAffineTransform(translationX: 20.0 * sin(CGFloat.random(in: 0.0...2 * .pi)) , y: 600.0)))
        
        let iconLayer: CALayer = CALayer()
        iconLayer.frame = CGRect(x: 0.0, y: 0.0, width: icon.size.width, height: icon.size.height)
        iconLayer.contents = icon.cgImage
        iconLayer.transform = startTransform
        
        let absoluteCenter = self.animationView.convert(point, from: from)
        iconLayer.position = absoluteCenter
        
        self.animationView.layer.addSublayer(iconLayer)
        
        let scaleAnimation = CABasicAnimation(keyPath: "transform")
        scaleAnimation.duration = duration
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        scaleAnimation.fromValue = startTransform
        scaleAnimation.toValue = endTransform
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.duration = duration
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        opacityAnimation.fromValue = 1.0
        opacityAnimation.toValue = 0.0
        
        let group = CAAnimationGroup()
        group.duration = duration
        group.animations = [scaleAnimation, opacityAnimation]
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false
        group.completion = { [weak iconLayer] _ in
            iconLayer?.removeFromSuperlayer()
        }
        
        iconLayer.add(group, forKey: "icon_animations")
    }
}
