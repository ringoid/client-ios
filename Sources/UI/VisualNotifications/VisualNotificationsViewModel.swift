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
}

class VisualNotificationsViewModel
{
    var items: BehaviorRelay<[VisualNotificationInfo]>
    {
        return self.manager.items
    }
    
    fileprivate let manager: VisualNotificationsManager
    
    init(_ input: VisualNotificationsVMInput)
    {
        self.manager = input.manager
    }
}
