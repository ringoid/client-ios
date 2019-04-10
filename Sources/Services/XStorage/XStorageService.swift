//
//  KVStorage.swift
//  ringoid
//
//  Created by Victor Sukochev on 03/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift

protocol XStorageService
{
    func store(_ object: XStorageObject, key: String) -> Single<Void>
    func object(_ key: String) -> Single<XStorageObject>
    func remove(_ key: String) -> Single<Void>
    
    func sync()
}


