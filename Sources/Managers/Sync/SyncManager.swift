//
//  SyncManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 04/04/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

class SyncManager
{
    let notifications: NotificationService
    let lmm: LMMManager
    let newFaces: NewFacesManager
    let profile: UserProfileManager
    let navigation: NavigationManager
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init(_ notifications: NotificationService, lmm: LMMManager, newFaces: NewFacesManager, profile: UserProfileManager, navigation: NavigationManager)
    {
        self.notifications = notifications
        self.lmm = lmm
        self.newFaces = newFaces
        self.profile = profile
        self.navigation = navigation
        
        self.setupBindings()
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.notifications.responses.subscribe(onNext: { [weak self] _ in
            self?.navigation.mainItem.accept(.profileAndFetch)
        }).disposed(by: self.disposeBag)
    }
}
