//
//  SettingsManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 23/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

class SettingsManager
{
    let db: DBService
    let api: ApiService
    let fs: FileService
    let storage: XStorageService
    let actions: ActionsManager
    
    let isFirstTimePhoto: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init(db: DBService, api: ApiService, fs: FileService, storage: XStorageService, actions: ActionsManager)
    {
        self.db = db
        self.api = api
        self.fs = fs
        self.storage = storage
        self.actions = actions
        
        self.loadSettings()
        self.setupBindings()
    }
    
    func logout()
    {
        self.api.logout().subscribe(onNext: { [weak self] _ in
            self?.reset()
        }).disposed(by: self.disposeBag)
    }
    
    func reset()
    {
        self.isFirstTimePhoto.accept(true)
        self.db.reset()
        self.fs.reset()
        self.actions.lastActionDate = nil
    }
    
    // MARK: -
    
    fileprivate func loadSettings()
    {
        self.storage.object("is_first_time").subscribe(onNext:{ [weak self] obj in
            guard let state = Bool.create(obj) else { return }
            
            self?.isFirstTimePhoto.accept(state)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func setupBindings()
    {
        self.isFirstTimePhoto.asObservable().subscribe(onNext: { [weak self] state in
            guard let `self` = self else { return }
            
            self.storage.store(state, key: "is_first_time").subscribe().disposed(by: self.disposeBag)
        }).disposed(by: self.disposeBag)
    }
}
