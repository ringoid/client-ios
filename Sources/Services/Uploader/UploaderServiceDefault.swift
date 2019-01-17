
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
    fileprivate let disposeBag = DisposeBag()
    
    func upload(_ data: Data, to: URL) -> Observable<Void>
    {
        return Observable<Void>.create({ [weak self] observer -> Disposable in
            Alamofire.upload(data, to: to, method: .put, headers: nil).responseData { response in
                defer {
                    observer.onCompleted()
                }
                
                if let error = response.error {
                    observer.onError(error)
                    
                    return
                }
                
                observer.onNext(())
            }

            return Disposables.create()
        })
    }
}
