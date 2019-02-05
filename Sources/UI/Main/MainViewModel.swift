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
}

class MainViewModel
{
    let input: MainVMInput
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    fileprivate var notSeenLikesCount: Int = 0
    fileprivate var notSeenMatchesCount: Int = 0
    fileprivate var notSeenMessagesCount: Int = 0
    
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
    
    var isNotSeenProfilesAvailable: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)

    init(_ input: MainVMInput)
    {
        self.input = input
        
        self.setupBindings()
    }
    
    func purgeNewFaces()
    {
        self.input.newFacesManager.purge()
    }
    
    func moveToSearch()
    {
        self.input.navigationManager.mainItem.accept(.search)
    }
    
    func moveToLike()
    {
        self.input.navigationManager.mainItem.accept(.like)
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
            self.isNotSeenProfilesAvailable.accept(count + self.notSeenMatchesCount + self.notSeenMessagesCount != 0)
        }).disposed(by: self.disposeBag)
        
        self.input.lmmManager.notSeenMatchesCount.subscribe(onNext:{ [weak self] count in
            guard let `self` = self else { return }
            
            self.notSeenMatchesCount = count
            self.isNotSeenProfilesAvailable.accept(count + self.notSeenLikesCount + self.notSeenMessagesCount != 0)
        }).disposed(by: self.disposeBag)
        
        self.input.lmmManager.notSeenMessagesCount.subscribe(onNext:{ [weak self] count in
            guard let `self` = self else { return }
            
            self.notSeenMessagesCount = count
            self.isNotSeenProfilesAvailable.accept(count + self.notSeenMatchesCount + self.notSeenLikesCount != 0)
        }).disposed(by: self.disposeBag)
    }
}
