//
//  ContainerView.swift
//  ringoid
//
//  Created by Victor Sukochev on 10/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class ContainerView: TouchThroughView
{
    var containedVC: UIViewController?
    
    func embed(_ vc: UIViewController, to: UIViewController)
    {
        self.remove()
        
        to.addChild(vc)
        
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        vc.view.frame = self.bounds
        self.addSubview(vc.view)
        vc.view.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        vc.view.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        vc.view.bottomAnchor.constraint(equalTo:self.bottomAnchor).isActive = true
        vc.view.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        
        self.containedVC = vc
    }
    
    func remove()
    {
        self.containedVC?.view.removeFromSuperview()
        self.containedVC?.removeFromParent()
    }
}
