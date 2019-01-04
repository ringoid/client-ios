//
//  DefaultStorageService.swift
//  ringoid
//
//  Created by Victor Sukochev on 03/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift

class DefaultStorageService: XStorageService
{
    func store(_ object: XStorageObject, key: String) -> Observable<Void>
    {
        UserDefaults.standard.set(object.storableObject(), forKey: key)
        
        return Observable.just(())
    }
    
    func object(_ key: String) -> Observable<XStorageObject>
    {
        guard let storageObject = UserDefaults.standard.value(forKey: key), let object = String.create(storageObject) else {
            let error = createError("Object not stored", code: 0)
            
            return Observable<XStorageObject>.error(error)
        }
        
        return Observable<XStorageObject>.just(object)
    }
    
    func sync()
    {
        UserDefaults.standard.synchronize()
    }
}
