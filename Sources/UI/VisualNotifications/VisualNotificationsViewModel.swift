//
//  VisualNotificationsViewModel.swift
//  ringoid
//
//  Created by Victor Sukochev on 27/09/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

struct VisualNotificationsVMInput
{
    let manager: VisualNotificationsManager
    let navigation: NavigationManager
}

class VisualNotificationsViewModel
{
    var items: BehaviorRelay<[VisualNotificationInfo]>
    {
        return self.manager.items
    }
    
    fileprivate let manager: VisualNotificationsManager
    fileprivate let navigation: NavigationManager
    
    init(_ input: VisualNotificationsVMInput)
    {
        self.manager = input.manager
        self.navigation = input.navigation
    }
    
    func openChat(_ profileId: String)
    {
        self.navigation.mainItem.accept(.chat(profileId))
    }
}
