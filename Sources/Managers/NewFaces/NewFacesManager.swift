//
//  NewFacesManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 07/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift

class NewFacesManager
{
    let db: DBService
    let apiService: ApiService
    
    init(_ db: DBService, api: ApiService)
    {
        self.db = db
        self.apiService = api
    }
    
    func add(_ url: URL)
    {
        
    }
}
