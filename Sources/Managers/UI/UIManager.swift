//
//  UIManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 07/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

class UIManager
{
    let blockModeEnabled: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    let chatModeEnabled: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    let lmmRefreshModeEnabled: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    
    static let shared = UIManager()
    
    private init() {}
}
