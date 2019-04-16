//
//  LocationService.swift
//  ringoid
//
//  Created by Victor Sukochev on 15/04/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

struct Location
{
    let latitude: Double
    let longitude: Double
}

protocol LocationService
{
    var locations: Observable<Location>! { get }
    var isGranted: BehaviorRelay<Bool> { get }
    var isDenied: BehaviorRelay<Bool> { get }
    var initialTrigger: BehaviorRelay<Bool> { get }
    
    func requestPermissionsIfNeeded()
}
