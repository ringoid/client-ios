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
    let api: ApiService
    let fs: FileService
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init(db: DBService, api: ApiService, fs: FileService)
    {
        self.db = db
        self.api = api
        self.fs = fs
    }
    
    func logout()
    {
        self.api.logout().subscribe(onNext: { [weak self] _ in
            self?.reset()
        }).disposed(by: self.disposeBag)
    }
    
    // MARK: -
    
    fileprivate func reset()
    {
        self.db.reset()
        self.fs.reset()
    }
}
