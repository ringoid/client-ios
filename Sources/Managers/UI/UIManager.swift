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
    let mainControlsVisible: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: true)
    
    static let shared = UIManager()
    
    private init() {}
}
