//
//  MainLMMViewModel.swift
//  ringoid
//
//  Created by Victor Sukochev on 14/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

struct MainLMMVMInput
{
    let lmmManager: LMMManager
    let actionsManager: ActionsManager
    let chatManager: ChatManager
    let profileManager: UserProfileManager
    let navigationManager: NavigationManager
    let newFacesManager: NewFacesManager
    let notifications: NotificationService
    let location: LocationManager
    let scenario: AnalyticsScenarioManager
    let transition: TransitionManager
    let settings: SettingsManager
    let filter: FilterManager
}

enum LMMType: String
{
    case likesYou = "likesYou"    
    case messages = "messages"
    case inbox = "inbox"
    case sent = "sent"
}

class MainLMMViewModel
{
    let lmmManager: LMMManager
    let profileManager: UserProfileManager
    let actionsManager: ActionsManager
    let navigationManager: NavigationManager
    let newFacesManager: NewFacesManager
    let notifications: NotificationService
    let location: LocationManager
    
    let likesYou: BehaviorRelay<[LMMProfile]> = BehaviorRelay<[LMMProfile]>(value: [])
    let matches: BehaviorRelay<[LMMProfile]>  = BehaviorRelay<[LMMProfile]>(value: [])
    let messages: BehaviorRelay<[LMMProfile]>  = BehaviorRelay<[LMMProfile]>(value: [])
    let inbox: BehaviorRelay<[LMMProfile]>  = BehaviorRelay<[LMMProfile]>(value: [])
    let sent: BehaviorRelay<[LMMProfile]>  = BehaviorRelay<[LMMProfile]>(value: [])
    
    var isFetching: BehaviorRelay<Bool> { return self.lmmManager.isFetching }
    
    var isPhotosAdded: Bool
    {
        return !self.profileManager.photos.value.isEmpty
    }
    
    var isLocationDenied: Bool
    {
        return self.location.isDenied
    }
    
    var updatedFeed: Observable<LMMType?>
    {
        return self.notifications.notificationData.map({ userInfo -> LMMType? in            
            guard let typeStr = userInfo["type"] as? String else { return nil }
            
            return RemoteFeedType(rawValue: typeStr)?.lmmType()
        })
    }
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init(_ input: MainLMMVMInput)
    {
        self.lmmManager = input.lmmManager
        self.profileManager = input.profileManager
        self.actionsManager = input.actionsManager
        self.navigationManager = input.navigationManager
        self.newFacesManager = input.newFacesManager
        self.notifications = input.notifications
        self.location = input.location
        
        self.setupBindings()
    }
    
    func refresh(_ from: LMMType) -> Observable<Void>
    {
        self.profileManager.refreshInBackground()
        
        return self.lmmManager.refreshProtected(from.sourceType())
    }
    
    func moveToProfile()
    {        
        self.navigationManager.mainItem.accept(.profileAndPick)
    }
    
    func registerPushesIfNeeded()
    {
        guard self.actionsManager.isLikedSomeone.value else { return }
        guard !self.notifications.isRegistered && !self.notifications.isGranted.value else { return }

        self.notifications.register()
    }
    
    func registerLocationsIfNeeded() -> Bool
    {
        guard !self.location.isGranted.value else { return true }
        
        self.location.requestPermissionsIfNeeded()
        
        return false
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.lmmManager.likesYou.asObservable().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] profiles in
            self?.likesYou.accept(profiles)
        }).disposed(by: self.disposeBag)
        
        self.lmmManager.matches.asObservable().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] profiles in
            self?.matches.accept(profiles)
        }).disposed(by: self.disposeBag)
        
        self.lmmManager.messages.asObservable().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] profiles in
            self?.messages.accept(profiles)
        }).disposed(by: self.disposeBag)
        
        self.lmmManager.inbox.asObservable().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] profiles in
            self?.inbox.accept(profiles)
        }).disposed(by: self.disposeBag)
        
        self.lmmManager.sent.asObservable().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] profiles in
            self?.sent.accept(profiles)
        }).disposed(by: self.disposeBag)
    }
}

extension RemoteFeedType
{
    func lmmType() -> LMMType?
    {
        switch self {
        case .likesYou: return .likesYou
        case .messages: return .messages
            
        default: return nil
        }
    }
}
