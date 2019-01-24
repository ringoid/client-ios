//
//  KeyboardListener.swift
//  ringoid
//
//  Created by Victor Sukochev on 24/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

protocol KeyboardListenerDelegate: class
{
    func keyboardListener(_ listener: KeyboardListener, animationFor keyboardHeight: CGFloat) -> (()->())?
}


class KeyboardListener
{
    static let shared = KeyboardListener()
    
    weak var delegate: KeyboardListenerDelegate?
    
    fileprivate(set) var height: CGFloat = 0.0
    
    fileprivate var lastActiveHeight: CGFloat = 0.0
    
    deinit
    {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate init()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(onKeyboardFrameChanged(_:)), name: UIApplication.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onKeyboardFrameChanged(_:)), name: UIApplication.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc fileprivate func handleWillEnterForeground()
    {
        // Final result of keyboard offset can not be different from 0.0 if we are moving to foreground
        // and last active height was equal to zero
        // Ignoring non-zero heights in this event allows log to avoid jumps
        guard self.lastActiveHeight > 0.1 else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard self.lastActiveHeight != self.height else { return }
            
            
            guard let animation = self.delegate?.keyboardListener(self, animationFor: 0.0) else { return }
            
            UIView.animate(withDuration: 0.2, delay: 0, options: [ .curveEaseInOut, .beginFromCurrentState ], animations: animation, completion: nil)
        }
    }
    
    @objc fileprivate func onKeyboardFrameChanged(_ notification: Notification)
    {
        let rect: CGRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? CGRect.zero
        self.height = UIScreen.main.bounds.height - rect.origin.y

        self.lastActiveHeight = self.height
        
        let duration: TimeInterval = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0.2
        let curveInt: Int? = (notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int)
        let curve: UIView.AnimationCurve = UIView.AnimationCurve(rawValue: curveInt ?? -1) ?? .easeInOut
        let curveOption: UIView.AnimationOptions = UIView.AnimationOptions(rawValue: UInt(curve.rawValue)<<16)
        
        guard let animation = self.delegate?.keyboardListener(self, animationFor: self.height) else { return }
        
        UIView.animate(withDuration: duration, delay: 0, options: [ curveOption, .beginFromCurrentState ], animations: animation, completion: nil)
        
    }
}
