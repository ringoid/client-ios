//
//  ImageService.swift
//  ringoid
//
//  Created by Victor Sukochev on 02/04/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Nuke

class ImageService
{
    static let shared = ImageService()
    
    fileprivate var taskMap: [URL: ImageTask] = [:]
    
    private init()
    {
        ImagePipeline.shared = ImagePipeline {
            $0.isProgressiveDecodingEnabled = true
        }
    }
    
    func load(_ url: URL, thumbnailUrl: URL?, to: UIImageView)
    {
        guard let thumbnailUrl = thumbnailUrl else {
            let mainTask = ImagePipeline.shared.loadImage(with: url, progress: nil, completion: { (response, _) in
                to.image = response?.image
            })
            
            self.taskMap[url] = mainTask
            
            return
        }
        
        let thumbnailTask = ImagePipeline.shared.loadImage(with: thumbnailUrl, progress: { (response, _, _) in
            to.image = response?.image
        }) { (thumbnailResponse, _) in
            to.image = thumbnailResponse?.image
            
            let mainTask = ImagePipeline.shared.loadImage(with: url, progress: nil, completion: { (response, _) in
                let thumbView = UIImageView(frame: to.bounds)
                thumbView.image = thumbnailResponse?.image
                thumbView.contentMode = .scaleAspectFill
                to.addSubview(thumbView)
                to.image = response?.image
                
                let animator = UIViewPropertyAnimator(duration: 0.5, curve: .linear, animations: {
                    thumbView.alpha = 0.0
                })
                
                animator.addCompletion({ _ in
                    thumbView.removeFromSuperview()
                })
                
                animator.startAnimation()
            })
            
            self.taskMap[url] = mainTask
        }
        
        self.taskMap[url] = thumbnailTask
    }
    
    func cancel(_ url: URL)
    {
        self.taskMap[url]?.cancel()
        self.taskMap.removeValue(forKey: url)
    }
}
