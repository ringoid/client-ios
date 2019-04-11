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
        
        let duration: Double = 1.0 + Double(count) / 5.25
        let birthRate: Float = Float(count) / Float(duration)
        let lifetime: Float = 3.0
        let velocity: CGFloat = UIScreen.main.bounds.height / 3.3
        
        let cell = CAEmitterCell()
        cell.contents = UIImage(named: "effect_like")!.cgImage
        cell.emissionLongitude = -.pi / 2.0 - .pi * 0.015
        cell.emissionRange = .pi / 16.0
        cell.lifetime = lifetime
        cell.birthRate = birthRate
        cell.scale = 0.6
        cell.scaleRange = 0.1
        cell.scaleSpeed = 0.05
        cell.velocity = velocity
        cell.velocityRange = velocity / 4.0
        cell.yAcceleration = velocity * 0.125
        cell.alphaSpeed = -1.0 / lifetime
        cell.alphaRange = 0.1
        
        let emitLayer: CAEmitterLayer = CAEmitterLayer()
        emitLayer.emitterShape = .point
        emitLayer.emitterPosition = from
        emitLayer.frame = self.bounds
        emitLayer.beginTime = CACurrentMediaTime()
        emitLayer.seed = UInt32.random(in: 1000...9999)
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
    
    func animateMessages(_ count: Int, from: CGPoint)
    {
        guard count > 0 else { return }
        
        let duration: Double = 1.1 + Double(count) / 4.75
        let birthRate: Float = Float(count) / Float(duration)
        let lifetime: Float = 3.5
        let velocity: CGFloat = UIScreen.main.bounds.height / 4.0
        
        let cell = CAEmitterCell()
        cell.contents = UIImage(named: "effect_message")!.cgImage
        cell.emissionLongitude = -.pi / 2.0 + .pi * 0.15
        cell.emissionRange = .pi / 16.0
        cell.lifetime = lifetime
        cell.birthRate = birthRate
        cell.scale = 0.6
        cell.scaleRange = 0.1
        cell.scaleSpeed = 0.05
        cell.velocity = velocity
        cell.velocityRange = velocity / 4.0
        cell.yAcceleration = velocity * 0.125
        cell.alphaSpeed = -1.0 / lifetime
        cell.alphaRange = 0.1

        let emitLayer: CAEmitterLayer = CAEmitterLayer()
        emitLayer.emitterShape = .point
        emitLayer.emitterPosition = from
        emitLayer.frame = self.bounds
        emitLayer.beginTime = CACurrentMediaTime()
        emitLayer.seed = UInt32.random(in: 0...1000)
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
    
    func animateMatches(_ count: Int, from: CGPoint)
    {
        guard count > 0 else { return }
        
        let duration: Double = 0.9 + Double(count) / 3.75
        let birthRate: Float = Float(count) / Float(duration)
        let lifetime: Float = 3.5
        let velocity: CGFloat = UIScreen.main.bounds.height / 4.25
        
        let cell = CAEmitterCell()
        cell.contents = UIImage(named: "effect_match")!.cgImage
        cell.emissionLongitude = -.pi / 2.0 + .pi * 0.055
        cell.emissionRange = .pi / 16.0
        cell.lifetime = lifetime
        cell.birthRate = birthRate
        cell.scale = 0.6
        cell.scaleRange = 0.1
        cell.scaleSpeed = 0.05
        cell.velocity = velocity
        cell.velocityRange = velocity / 4.0
        cell.yAcceleration = velocity * 0.125
        cell.alphaSpeed = -1.0 / lifetime
        cell.alphaRange = 0.1
        cell.color = UIColor(red: 1.0, green: 153.0 / 255.0, blue: 1.0, alpha: 1.0).cgColor
        
        let emitLayer: CAEmitterLayer = CAEmitterLayer()
        emitLayer.emitterShape = .point
        emitLayer.emitterPosition = from
        emitLayer.frame = self.bounds
        emitLayer.beginTime = CACurrentMediaTime()
        emitLayer.seed = UInt32.random(in: 9999...20000)
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
