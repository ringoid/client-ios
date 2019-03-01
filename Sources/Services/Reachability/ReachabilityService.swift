//
//  ReachabilityService.swift
//  ringoid
//
//  Created by Victor Sukochev on 01/03/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//


import RxSwift
import RxCocoa

protocol ReachabilityService
{
    var isInternetAvailable: BehaviorRelay<Bool> { get }
    
    func check() -> Observable<Bool>
}
