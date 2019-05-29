//
//  ImageService.swift
//  ringoid
//
//  Created by Victor Sukochev on 02/04/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Nuke
import RxNuke
import RxSwift
import RxCocoa

class ImageService
{
    static let shared = ImageService()
    
    fileprivate var taskMap: [URL: DisposeBag] = [:]
    
    private init()
    {
        ImagePipeline.shared = ImagePipeline {
            $0.isProgressiveDecodingEnabled = true
        }
    }
    
    func load(_ url: URL, thumbnailUrl: URL?, to: UIImageView)
    {
        let request = ImageRequest(url: url)
        if let cachedImage = ImageCache.shared[request] {
            to.image = cachedImage
            
            return
        }
        
        guard let thumbnailUrl = thumbnailUrl else {
            let disposeBag: DisposeBag = DisposeBag()
            ImagePipeline.shared.rx.loadImage(with: url).asObservable()
                .retryOnConnect(timeout: 10.0)
                .retry(3)
                .subscribe(onNext: { response in
                    self.taskMap.removeValue(forKey: url)
                to.image = response.image
            }).disposed(by: disposeBag)
            
            self.taskMap[url] = disposeBag
            
            return
        }
        
        let disposeBag: DisposeBag = DisposeBag()
        var thumbnailResponse: ImageResponse? = nil
        
        ImagePipeline.shared.rx.loadImage(with: thumbnailUrl).asObservable()
            .retryOnConnect(timeout: 10.0)
            .retry(3)
            .flatMap({ response -> Observable<ImageResponse> in                
                to.image = response.image
                thumbnailResponse = response
                
                return ImagePipeline.shared.rx.loadImage(with: request).asObservable()
                    .retryOnConnect(timeout: 10.0)
                    .retry(3)
            }).subscribe(onNext: { response in
                self.taskMap.removeValue(forKey: url)
                
                let thumbView = UIImageView(frame: to.bounds)
                thumbView.image = thumbnailResponse?.image
                thumbView.contentMode = .scaleAspectFill
                to.addSubview(thumbView)
                to.image = response.image
                
                let animator = UIViewPropertyAnimator(duration: 0.5, curve: .linear, animations: {
                    thumbView.alpha = 0.0
                })
                
                animator.addCompletion({ _ in
                    thumbView.removeFromSuperview()
                })
                
                animator.startAnimation()
            }).disposed(by: disposeBag)
        
        self.taskMap[url] = disposeBag
    }
    
    func cancel(_ url: URL)
    {
        self.taskMap.removeValue(forKey: url)
    }
}
