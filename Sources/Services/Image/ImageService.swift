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
    
    private init()
    {
//        let dataLoader = DataLoader()
//        dataLoader.
//        
//        let pipeline = ImagePipeline {
//            $0.dataLoader = ...
//                $0.dataLoadingQueue = ...
//                $0.imageCache = ...
//            ...
//        }
//        
//        ImagePipeline.shared = pipeline
    }
    
    func load(_ url: URL, to: UIImageView)
    {
        let contentModes = ImageLoadingOptions.ContentModes(
            success: .scaleAspectFill,
            failure: .scaleAspectFill,
            placeholder: .scaleAspectFill
        )
    
        let options = ImageLoadingOptions( contentModes: contentModes)
        Nuke.loadImage(with: url, options: options, into: to)
    }
}
