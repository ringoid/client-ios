//
//  MainEffectsView.swift
//  ringoid
//
//  Created by Victor Sukochev on 08/04/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class MainEffectsView: TouchThroughView
{
    func animateLikes(_ count: Int, from: CGPoint)
    {
        guard count > 0 else { return }
        
        let duration: Double = 1.0 + Double(count) / 10.0
        let birthRate: Float = Float(count) / Float(duration)
        let lifetime: Float = 3.0
        
        let cell = CAEmitterCell()
        cell.contents = UIImage(named: "feed_like_selected")!.cgImage
        cell.emissionLongitude = -.pi / 2.0
        cell.emissionRange = .pi / 8.0
        cell.lifetime = lifetime
        cell.birthRate = birthRate
        cell.scale = 0.5
        cell.scaleRange = 0.1
        cell.velocity = 100.0
        cell.velocityRange = 50.0
        cell.alphaSpeed = -1.0 / lifetime
        cell.alphaRange = 0.1
        
        let emitLayer: CAEmitterLayer = CAEmitterLayer()
        emitLayer.emitterShape = .point
        emitLayer.emitterPosition = from
        emitLayer.frame = self.bounds
        emitLayer.beginTime = CACurrentMediaTime()
        emitLayer.emitterCells = [
            cell
        ]
        
        self.layer.addSublayer(emitLayer)
        
        let durationTimer = Timer(timeInterval: duration, repeats: false) { timer in
            emitLayer.birthRate = 0.0
            timer.invalidate()
        }
        
        let removalTimer = Timer(timeInterval: duration + Double(lifetime) + 0.1, repeats: false) { timer in
            emitLayer.removeFromSuperlayer()
            timer.invalidate()
        }
        
        RunLoop.main.add(durationTimer, forMode: .common)
        RunLoop.main.add(removalTimer, forMode: .common)
    }
}
