//
//  VerticalGradientView.swift
//  ringoid
//
//  Created by Victor Sukochev on 15/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class VerticalGradientView: TouchThroughView
{
    let gradientLayer = CAGradientLayer()
    
    @IBInspectable var topColor: UIColor = .clear {
        didSet {
            self.gradientLayer.colors = [self.topColor.cgColor, self.bottomColor.cgColor]
        }
    }
    
    @IBInspectable var bottomColor: UIColor = .clear {
        didSet {
            self.gradientLayer.colors = [self.topColor.cgColor, self.bottomColor.cgColor]
        }
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        self.layer.addSublayer(self.gradientLayer)
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        
        self.gradientLayer.frame = self.bounds
    }
}
