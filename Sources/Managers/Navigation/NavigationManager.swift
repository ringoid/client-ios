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
    case like
    case profile
    
    case searchAndFetch
    case profileAndFetch
    case profileAndPick
}

class NavigationManager
{
    let mainItem: BehaviorRelay<MainNavigationItem> = BehaviorRelay<MainNavigationItem>(value: .search)
}
