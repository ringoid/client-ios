//
//  NavigationManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 28/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

enum MainNavigationItem
{
    case search
    case likes    
    case chats
    case profile
    
    case searchAndFetch
    case searchAndFetchFirstTime
    case profileAndFetch
    case profileAndPick
    
    case likeAndFetch
}

class NavigationManager
{
    let mainItem: BehaviorRelay<MainNavigationItem> = BehaviorRelay<MainNavigationItem>(value: .search)
}
