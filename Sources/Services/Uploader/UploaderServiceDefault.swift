
//
//  UploaderServiceDefault.swift
//  ringoid
//
//  Created by Victor Sukochev on 08/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxAlamofire
import Alamofire

class UploaderServiceDefault: UploaderService
{
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    fileprivate let storage: XStorageService
    
    fileprivate var activeUploads: [URL: URLSessionTask?] = [:]
    
    init(_ storage: XStorageService)
    {
        self.storage = storage
    }
    
    func upload(_ data: Data, to: URL) -> Observable<Void>
    {
        let request = Alamofire.upload(data, to: to, method: .put, headers: nil)
        self.activeUploads[to] = request.task
        
        return Observable<Void>.create({ [weak self] observer -> Disposable in            
                request.responseData { response in
                    
                defer {
                    self?.activeUploads.removeValue(forKey: to)
                    observer.onCompleted()
                }
                
                if let error = response.error {
                    observer.onError(error)
                    
                    return
                }
                
                observer.onNext(())
            }

            return Disposables.create()
        }).retry(3)
    }
    
    func cancel(_ url: URL)
    {
        self.activeUploads[url]??.cancel()
    }
}
