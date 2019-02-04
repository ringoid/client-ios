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
    
    init(_ input: MainVMInput)
    {
        self.input = input
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
}
