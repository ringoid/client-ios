//
//  Image.swift
//  ringoid
//
//  Created by Victor Sukochev on 08/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

extension UIImage
{
    // based on: https://gist.github.com/matthiasnagel/fe7ed96dc66310c67b45fb759cf6de8c
    
    func fixedOrientation() -> UIImage? {
        
        if imageOrientation == .up {
            return self
        }
        
        var transform: CGAffineTransform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: .pi)
            break
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: .pi / 2.0)
            break
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -.pi / 2.0)
            break
        case .up, .upMirrored:
            break
        }
        
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform.translatedBy(x: size.width, y: 0)
            transform.scaledBy(x: -1, y: 1)
            break
        case .leftMirrored, .rightMirrored:
            transform.translatedBy(x: size.height, y: 0)
            transform.scaledBy(x: -1, y: 1)
        case .up, .down, .left, .right:
            break
        }
        
        let ctx: CGContext = CGContext(data: nil,
                                       width: Int(size.width),
                                       height: Int(size.height),
                                       bitsPerComponent: self.cgImage!.bitsPerComponent,
                                       bytesPerRow: 0,
                                       space: self.cgImage!.colorSpace!,
                                       bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        
        ctx.concatenate(transform)
        
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            break
        }
        
        guard let cgImage: CGImage = ctx.makeImage() else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    func adjust(for orientation: UIDeviceOrientation) -> UIImage?
    {
        var transform: CGAffineTransform = .identity
        
        var height = size.height
        var width = size.width
        
        switch orientation {
        case .landscapeLeft:
            transform = transform.translatedBy(x: size.height, y: size.width)
            transform = transform.rotated(by: .pi)
            height = size.width
            width = size.height
            
            break
            
        case .landscapeRight:
            height = size.width
            width = size.height
            
            break
            
        default:
            return self
        }
        
        let ctx: CGContext = CGContext(data: nil,
                                       width: Int(width),
                                       height: Int(height),
                                       bitsPerComponent: self.cgImage!.bitsPerComponent,
                                       bytesPerRow: 0,
                                       space: self.cgImage!.colorSpace!,
                                       bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        
        ctx.concatenate(transform)
        
        ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let cgImage: CGImage = ctx.makeImage() else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    func crop(rect: CGRect) -> UIImage?
    {
        guard let imageRef = self.fixedOrientation()?.cgImage?.cropping(to: rect) else { return nil }
        
        return UIImage(cgImage: imageRef)
    }
}
