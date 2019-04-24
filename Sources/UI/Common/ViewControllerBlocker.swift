//
//  ViewControllerBlocker.swift
//  ringoid
//
//  Created by Victor Sukochev on 24/04/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

fileprivate var blockView: UIView? = nil

extension UIViewController
{
    func block()
    {
        guard blockView == nil else { return }
        
        let backgroundView = UIView(frame: self.view.bounds)
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        let activityView = UIActivityIndicatorView(style: .whiteLarge)
        activityView.center = backgroundView.center
        backgroundView.addSubview(activityView)
        activityView.startAnimating()
        
        self.view.addSubview(backgroundView)
        blockView = backgroundView
    }
    
    func unblock()
    {
        blockView?.removeFromSuperview()
    }
}
