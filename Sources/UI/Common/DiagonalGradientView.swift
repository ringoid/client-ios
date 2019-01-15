//
//  HorizontalGradientView.swift
//  ringoid
//
//  Created by Victor Sukochev on 15/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class DiagonalGradientView: TouchThroughView
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
        
        self.gradientLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
        self.gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.0)
        self.layer.addSublayer(self.gradientLayer)
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        
        self.gradientLayer.frame = self.bounds
    }
}
