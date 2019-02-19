//
//  MainLMMProfileViewModel.swift
//  ringoid
//
//  Created by Victor Sukochev on 15/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

struct MainLMMProfileVMInput
{
    let profile: LMMProfile
    let feedType: LMMType
    let actionsManager: ActionsManager
    let initialIndex: Int
}

class MainLMMProfileViewModel
{
    let input: MainLMMProfileVMInput
    
    let isMessaingAvailable: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init(_ input: MainLMMProfileVMInput)
    {
        self.input = input
        
        self.setupBindings()
    }
    
    func like(at photoIndex: Int)
    {
        self.input.actionsManager.add(
            [.view(viewCount: 1, viewTimeSec: 1), .like(likeCount: 1)],
            profile: self.input.profile.actionInstance(),
            photo: self.input.profile.photos[photoIndex].actionInstance(),
            source: self.input.feedType.sourceType())
    }
    
    func block(at photoIndex: Int, reason: BlockReason)
    {
        self.input.actionsManager.blockActionProtected(
            reason,
            profile: self.input.profile.actionInstance(),
            photo: self.input.profile.photos[photoIndex].actionInstance(),
            source: self.input.feedType.sourceType())
    }
    
    // MARK: -

    fileprivate func setupBindings()
    {
        guard !self.input.profile.isInvalidated else { return }
        
        self.input.profile.photos.filter({ !$0.isInvalidated }).forEach ({ photo in
            photo.rx.observe(Photo.self, "isLiked").subscribe(onNext: { [weak self] _ in
                self?.updateMessagingState()
            }).disposed(by: self.disposeBag)
        })
    }
    
    fileprivate func updateMessagingState()
    {
        let currentValue = self.isMessaingAvailable.value
        
        if self.input.feedType != .likesYou {
            if !currentValue {
                self.isMessaingAvailable.accept(true)
            }
            
            return
        }
        
        guard !self.input.profile.isInvalidated else { return }
        
        for photo in self.input.profile.photos {
            if photo.isLiked {
                if !currentValue {
                    self.isMessaingAvailable.accept(true)
                }
                
                return
            }
        }
        
        if currentValue {
            self.isMessaingAvailable.accept(false)
        }
    }
}
