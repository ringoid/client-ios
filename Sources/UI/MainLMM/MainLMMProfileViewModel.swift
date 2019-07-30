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
    let initialIndex: Int
    let actionsManager: ActionsManager
    let profileManager: UserProfileManager
    let navigationManager: NavigationManager
    let scenarioManager: AnalyticsScenarioManager
    let transitionManager: TransitionManager
    let lmmManager: LMMManager
    let filter: FilterManager
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
    
    func block(at photoIndex: Int, reason: BlockReason)
    {
        guard let actionProfile = self.input.profile.actionInstance() else { return }
        
        switch self.input.feedType {
        case .likesYou:
            self.input.lmmManager.allLikesYouProfilesCount.accept(self.input.lmmManager.allLikesYouProfilesCount.value - 1)
            
            if self.input.filter.isFilteringEnabled.value {
                self.input.lmmManager.filteredLikesYouProfilesCount.accept(self.input.lmmManager.filteredLikesYouProfilesCount.value - 1)
            }
            
            break
            
        case .messages:
            self.input.lmmManager.allMessagesProfilesCount.accept(self.input.lmmManager.allMessagesProfilesCount.value - 1)
            
            if self.input.filter.isFilteringEnabled.value {                
                self.input.lmmManager.filteredMessagesProfilesCount.accept(self.input.lmmManager.filteredMessagesProfilesCount.value - 1)
            }
            break
            
        default: break
        }
        
        let source = self.input.feedType.sourceType()
        self.input.actionsManager.blockActionProtected(
            reason,
            profile: actionProfile,
            photo: actionProfile.orderedPhotos()[photoIndex],
            source: source)
        self.input.lmmManager.updateFilterCounters(source)
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
