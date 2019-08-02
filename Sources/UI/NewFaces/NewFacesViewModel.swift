
//
//  NewFacesViewModel.swift
//  ringoid
//
//  Created by Victor Sukochev on 08/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

struct NewFacesVMInput
{
    let newFacesManager: NewFacesManager
    let actionsManager: ActionsManager
    let profileManager: UserProfileManager
    let lmmManager: LMMManager
    let navigationManager: NavigationManager
    let notifications: NotificationService
    let location: LocationManager
    let scenario: AnalyticsScenarioManager
    let transition: TransitionManager
    let filter: FilterManager
}

class NewFacesViewModel
{
    let profiles: BehaviorRelay<[NewFaceProfile]> = BehaviorRelay<[NewFaceProfile]>(value: [])
    var isFetching : BehaviorRelay<Bool> { return self.newFacesManager.isFetching }
    var initialLocationTrigger: BehaviorRelay<Bool> { return self.location.initialTrigger }
    var isLocationDenied: Bool { return self.location.isDenied }
    
    let newFacesManager: NewFacesManager
    let profileManager: UserProfileManager
    let navigationManager: NavigationManager
    let actionsManager: ActionsManager
    let lmmManager: LMMManager
    let notifications: NotificationService
    let location: LocationManager
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init(_ input: NewFacesVMInput)
    {
        self.newFacesManager = input.newFacesManager
        self.profileManager = input.profileManager
        self.navigationManager = input.navigationManager
        self.actionsManager = input.actionsManager
        self.lmmManager = input.lmmManager
        self.notifications = input.notifications
        self.location = input.location
        
        self.setupBindings()        
    }
    
    func refresh(_ isFilteringEnabled: Bool) -> Observable<Void>
    {
        self.isFetching.accept(true)
        self.profileManager.refreshInBackground()
        self.actionsManager.finishViewActions(for: self.profiles.value, source: .newFaces)
        
        return self.actionsManager.sendQueue().flatMap({ [weak self] _ -> Observable<Void> in
            if self!.profileManager.photos.value.filter({ !$0.isBlocked }).count > 0 && !isFilteringEnabled {
                self!.lmmManager.refreshInBackground(.newFaces)
            }
            
            return self!.newFacesManager.refresh()
        })
    }
    
    func fetchNext() -> Observable<Void>
    {
        guard !self.isFetching.value else {
            let error = createError("New faces fetching in already in progress", type: .hidden)
            
            return .error(error)
        }
  
        self.isFetching.accept(true)
        
        return self.actionsManager.sendQueue().flatMap { [weak self] _ -> Observable<Void> in
            guard let `self` = self else { return .just(()) } // view model deleted
            
            return self.newFacesManager.fetch()
        }
    }
    
    func moveToProfile()
    {
        self.navigationManager.mainItem.accept(.profileAndPick)
    }
    
    func registerPushesIfNeeded()
    {
        guard self.profileManager.photos.value.filter({ !$0.isBlocked }).count >  0 else { return }
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
        
        // New faces
        self.newFacesManager.profiles.subscribe(onNext: { [weak self] _ in
            self?.updateProfiles()
        }).disposed(by: self.disposeBag)
        
        // LMHIS
        self.lmmManager.likesYou.subscribe(onNext: { [weak self] _ in
            self?.updateProfiles()
        }).disposed(by: self.disposeBag)
        
        self.lmmManager.matches.subscribe(onNext: { [weak self] _ in
            self?.updateProfiles()
        }).disposed(by: self.disposeBag)
        
        
        self.lmmManager.messages.subscribe(onNext: { [weak self] _ in
            self?.updateProfiles()
        }).disposed(by: self.disposeBag)
        
        
        self.lmmManager.inbox.subscribe(onNext: { [weak self] _ in
            self?.updateProfiles()
        }).disposed(by: self.disposeBag)
        
        
        self.lmmManager.sent.subscribe(onNext: { [weak self] _ in
            self?.updateProfiles()
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func updateProfiles()
    {
        let updatedProfiles = self.newFacesManager.profiles.value
        
        var lmhisMap: [String: Bool] = [:]
        (
            self.lmmManager.likesYou.value +
                self.lmmManager.matches.value +
                self.lmmManager.messages.value +
                self.lmmManager.inbox.value +
                self.lmmManager.sent.value
            ).forEach({ profile in
                lmhisMap[profile.id] = true
            })
        
        self.profiles.accept(updatedProfiles.filter({ lmhisMap[$0.id] == nil }))
    }
}
