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

    let disconnection: BehaviorRelay<ApiError?> = BehaviorRelay<ApiError?>(value: nil)
    let oldVersion: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    
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
            self?.handleConnectionError(error)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func handleApiError(_ error: ApiError)
    {
        switch error.type {
        case .unknown: return
        case .internalServerError:
            log("Internal Server Error")
            SentryService.shared.send(.internalError)
            break
            
        case .invalidAccessTokenClientError:
            log("Invalid Access Token Client Error")
            self.settings.reset()
            self.api.reset()
            break
            
        case .tooOldAppVersionClientError:
            log("Too old app version client error")
            self.oldVersion.accept(true)
            return
            
        default: return
        }
    }
    
    fileprivate func handleConnectionError(_ error: ApiError)
    {
        switch error.type {
        case .notConnectedToInternet, .connectionLost, .secureConnectionFailed, .connectionTimeout:
            self.disconnection.accept(error)
            break
            
        default: return
        }
    }
}
