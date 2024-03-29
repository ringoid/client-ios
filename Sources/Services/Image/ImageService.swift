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
    fileprivate var viewMap: [URL: UIView] = [:]
    
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
            DispatchQueue.main.async {
                to.image = cachedImage
            }
            
            return
        }
        
        if self.taskMap[url] != nil && self.viewMap[url] == to { return }
        
        guard let thumbnailUrl = thumbnailUrl else {
            let disposeBag: DisposeBag = DisposeBag()
            self.taskMap[url] = disposeBag
            self.viewMap[url] = to
            
            ImagePipeline.shared.rx.loadImage(with: url).asObservable()
                .retryOnConnect(timeout: .seconds(10))
                .retry(3)
                .subscribe(onNext: { response in
                    self.taskMap.removeValue(forKey: url)
                    self.viewMap.removeValue(forKey: url)
                    
                    DispatchQueue.main.async {
                        to.image = response.image
                    }
                }, onError: { _ in
                    self.taskMap.removeValue(forKey: url)
                    self.viewMap.removeValue(forKey: url)
                }).disposed(by: disposeBag)
 
            return
        }
        
        let disposeBag: DisposeBag = DisposeBag()
        self.taskMap[url] = disposeBag
        self.viewMap[url] = to
        var thumbnailResponse: ImageResponse? = nil
        
        ImagePipeline.shared.rx.loadImage(with: thumbnailUrl).asObservable()
            .retryOnConnect(timeout: .seconds(10))
            .retry(3)
            .flatMap({ response -> Observable<ImageResponse> in
                DispatchQueue.main.async {
                    to.image = response.image
                }
                
                thumbnailResponse = response
                
                return ImagePipeline.shared.rx.loadImage(with: request).asObservable()
                    .retryOnConnect(timeout: .seconds(10))
                    .retry(3)
            }).subscribe(onNext: { response in
                self.taskMap.removeValue(forKey: url)
                self.viewMap.removeValue(forKey: url)

                DispatchQueue.main.async {
                    let thumbView = UIImageView(frame: to.bounds)
                    thumbView.image = thumbnailResponse?.image
                    thumbView.contentMode = .scaleAspectFill
                    to.addSubview(thumbView)
                    to.image = response.image
                    
                    let animator = UIViewPropertyAnimator(duration: 0.05, curve: .linear, animations: {
                        thumbView.alpha = 0.0
                    })
                    
                    animator.addCompletion({ _ in
                        thumbView.removeFromSuperview()
                    })
                    
                    animator.startAnimation()
                }
            }, onError: { _ in
                self.taskMap.removeValue(forKey: url)
                self.viewMap.removeValue(forKey: url)
            }).disposed(by: disposeBag)
    }
    
    func cancel(_ url: URL)
    {
        self.taskMap.removeValue(forKey: url)
        self.viewMap.removeValue(forKey: url)
    }
}
