//
//  UserProfileCropOverlayView.swift
//  ringoid
//
//  Created by Victor Sukochev on 28/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class UserProfileCropOverlayView: TouchThroughView
{
    fileprivate var fillLayer: CALayer?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.fillLayer?.removeFromSuperlayer()
        
        let path = UIBezierPath(rect: self.bounds)
        
        let holeWidth = self.bounds.width - 32.0
        let holeHeight = holeWidth * AppConfig.photoRatio
        let holePath = UIBezierPath(rect: CGRect(
            x: (self.bounds.width - holeWidth) / 2.0,
            y: (self.bounds.height - holeHeight) / 2.0,
            width: holeWidth,
            height: holeHeight)
        )
        path.append(holePath)
        path.usesEvenOddFillRule = true
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.fillRule = .evenOdd
        shapeLayer.fillColor = UIColor.black.cgColor
        shapeLayer.opacity = 0.6
        
        self.layer.addSublayer(shapeLayer)
        self.fillLayer = shapeLayer
    }
    
    override func draw(_ rect: CGRect)
    {
        // Outter white
        let holeWidth1 = self.bounds.width - 32.0
        let holeHeight1 = holeWidth1 * AppConfig.photoRatio
        let holePath1 = UIBezierPath(rect: CGRect(
            x: (self.bounds.width - holeWidth1) / 2.0,
            y: (self.bounds.height - holeHeight1) / 2.0,
            width: holeWidth1,
            height: holeHeight1)
        )
        
        UIColor.white.set()
        holePath1.stroke()
        
        // Inner black
        let holeWidth2 = holeWidth1 - 2.0
        let holeHeight2 = holeHeight1 - 2.0
        let holePath2 = UIBezierPath(rect: CGRect(
            x: (self.bounds.width - holeWidth2) / 2.0,
            y: (self.bounds.height - holeHeight2) / 2.0,
            width: holeWidth2,
            height: holeHeight2)
        )
        
        UIColor.black.set()
        holePath2.stroke()
    }
}
