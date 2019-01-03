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
    func store(_ object: XStorageObject, key: String) -> Observable<Void>
    func object(_ key: String) -> Observable<XStorageObject>
    
    func sync()
}


