//
//  SettingsManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 23/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift

class SettingsManager
{
    let db: DBService
    let apiService: ApiService
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init(db: DBService, api: ApiService)
    {
        self.db = db
        self.apiService = api
    }
    
    func logout()
    {
        self.apiService.logout().subscribe().disposed(by: self.disposeBag)
    }
}
