//
//  ErrorsManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 29/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

class ErrorsManager
{
    let api: ApiService
    let settings: SettingsManager
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init(_ api: ApiService, settings: SettingsManager)
    {
        self.api = api
        self.settings = settings
        
        self.setupBindings()
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.api.error.asObservable().subscribe(onNext: { [weak self] error in
            self?.handleApiError(error)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func handleApiError(_ error: ApiError)
    {
        switch error.type {
        case .unknown: return
        case .internalServerError: return
        case .invalidAccessTokenClientError:
            self.settings.reset()
            break
        case .tooOldAppVersionClientError: return
        }
    }
}
