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
    func store(_ object: XStorageObject, key: String) -> Single<Void>
    {
        UserDefaults.standard.set(object.storableObject(), forKey: key)
        
        return .just(())
    }
    
    func object(_ key: String) -> Single<XStorageObject>
    {
        guard let storageObject = UserDefaults.standard.value(forKey: key), let object = String.create(storageObject) else {
            let error = createError("Object not stored", type: .hidden)
            
            return .error(error)
        }
        
        return .just(object)
    }
    
    func remove(_ key: String) -> Single<Void> {
        UserDefaults.standard.removeObject(forKey: key)
        
        return .just(())
    }
    
    func sync()
    {
        UserDefaults.standard.synchronize()
    }
}
