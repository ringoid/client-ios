//
//  AchivementManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 16/08/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

class AchivementManager
{
    let text: BehaviorRelay<String> = BehaviorRelay<String>(value: "")
    
    fileprivate let lmm: LMMManager
    
    init(_ lmm: LMMManager)
    {
        self.lmm = lmm
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
//            self.text.accept("10 Likes achived!")
//        }
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        
    }
}
