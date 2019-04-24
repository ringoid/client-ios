
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
    
    func refresh() -> Observable<Void>
    {
        self.isFetching.accept(true)
        self.profileManager.refreshInBackground()
        self.actionsManager.finishViewActions(for: self.profiles.value, source: .newFaces)
        
        return self.actionsManager.sendQueue().flatMap({ [weak self] _ -> Observable<Void> in
            if self!.profileManager.photos.value.filter({ !$0.isBlocked }).count > 0 {
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
        self.newFacesManager.profiles.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] updatedProfiles in
            self?.profiles.accept(updatedProfiles)
        }).disposed(by: self.disposeBag)
    }
}
