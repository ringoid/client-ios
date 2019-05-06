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
    
    func load(_ url: URL, to: UIImageView)
    {
        let task = ImagePipeline.shared.loadImage(with: url, progress: { (response, _, _) in
            to.image = response?.image
        }) { (response, _) in
            to.image = response?.image
        }
        
        self.taskMap[url] = task
    }
    
    func cancel(_ url: URL)
    {
        self.taskMap[url]?.cancel()
        self.taskMap.removeValue(forKey: url)
    }
}
