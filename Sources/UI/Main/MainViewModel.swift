//
//  MainViewModel.swift
//  ringoid
//
//  Created by Victor Sukochev on 09/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

struct MainVMInput
{
    let actionsManager: ActionsManager
    let newFacesManager: NewFacesManager
    let lmmManager: LMMManager
    let profileManager: UserProfileManager
    let settingsManager: SettingsManager
    let chatManager: ChatManager
    let navigationManager: NavigationManager
    let errorsManager: ErrorsManager
    let promotionManager: PromotionManager
    let device: DeviceService
    let notifications: NotificationService
    let location: LocationManager
    let scenario: AnalyticsScenarioManager
    let transition: TransitionManager
}

class MainViewModel
{
    let input: MainVMInput
    
    var availablePhotosCount: Observable<Int>
    {
        return self.input.profileManager.photos.asObservable().map { photos -> Int in
            var count = 0
            
            photos.forEach({ photo in
                guard !photo.isBlocked else { return }
                
                count += 1
            })
            
            return count
        }
    }
    
    var incomingLikesCount: Observable<Int>
    {
        return self.input.lmmManager.incomingLikesYouCount
    }
    
    var incomingMatches: Observable<Int>
    {
        return self.input.lmmManager.incomingMatches
    }
    
    var incomingHellos: Observable<Int>
    {
        return self.input.lmmManager.incomingHellos
    }
    
    let isNotSeenProfilesAvailable: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    let isNotSeenInboxAvailable: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    fileprivate var notSeenLikesCount: Int = 0
    fileprivate var notSeenMatchesCount: Int = 0
    fileprivate var notSeenHellosCount: Int = 0

    init(_ input: MainVMInput)
    {
        self.input = input
        
        self.setupBindings()
    }
    
    func purgeNewFaces()
    {
        self.input.newFacesManager.purgeInBackground()
    }
    
    func moveToSearch()
    {
        self.input.navigationManager.mainItem.accept(.search)
    }
    
    func moveToLike()
    {
        self.input.navigationManager.mainItem.accept(.like)
    }
    
    func moveToMessages()
    {
        self.input.navigationManager.mainItem.accept(.messages)
    }
    
    func moveToProfile()
    {
        self.input.navigationManager.mainItem.accept(.profile)
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.input.lmmManager.notSeenLikesYouCount.subscribe(onNext:{ [weak self] count in
            guard let `self` = self else { return }
            
            self.notSeenLikesCount = count
            self.isNotSeenProfilesAvailable.accept(count + self.notSeenHellosCount + self.notSeenHellosCount != 0)
        }).disposed(by: self.disposeBag)
        
        self.input.lmmManager.notSeenMatchesCount.subscribe(onNext:{ [weak self] count in
            guard let `self` = self else { return }
            
            self.notSeenMatchesCount = count
            self.isNotSeenProfilesAvailable.accept(count + self.notSeenLikesCount + self.notSeenHellosCount != 0)
        }).disposed(by: self.disposeBag)
        
        self.input.lmmManager.notSeenHellosCount.subscribe(onNext:{ [weak self] count in
            guard let `self` = self else { return }
            
            self.notSeenHellosCount = count
            self.isNotSeenProfilesAvailable.accept(count + self.notSeenMatchesCount + self.notSeenLikesCount != 0)
        }).disposed(by: self.disposeBag)
        
        self.input.lmmManager.notSeenInboxCount.subscribe(onNext:{ [weak self] count in
            guard let `self` = self else { return }
            
            self.isNotSeenInboxAvailable.accept(count != 0)
        }).disposed(by: self.disposeBag)
    }
}
