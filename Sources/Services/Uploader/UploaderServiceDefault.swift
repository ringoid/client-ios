
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
    fileprivate let fs: FileService
    fileprivate var activeUploads: [URL: URLSessionTask?] = [:]
    
    init(_ storage: XStorageService, fs: FileService)
    {
        self.storage = storage
        self.fs = fs
    }
    
    func upload(_ data: Data, to: URL) -> Observable<Void>
    {
        let request = Alamofire.upload(data, to: to, method: .put, headers: nil)
        self.activeUploads[to] = request.task
        
        let path = FilePath.unique(.temporary)
        try? data.write(to: path.url())
        self.storage.store(path.filename, key: to.absoluteString).subscribe().disposed(by: self.disposeBag)
        
        return Observable<Void>.create({ [weak self] observer -> Disposable in            
                request.responseData { response in
                guard let `self` = self else { return }
                    
                defer {
                    self.activeUploads.removeValue(forKey: to)
                    observer.onCompleted()
                }
                
                if let error = response.error {
                    observer.onError(error)
                    
                    return
                }
                
                self.fs.rm(path)
                self.storage.remove(to.absoluteString).subscribe().disposed(by: self.disposeBag)
                    
                observer.onNext(())
            }

            return Disposables.create()
        }).retry(3)
    }
    
    func cancel(_ url: URL)
    {
        self.activeUploads[url]??.cancel()
        self.storage.object(url.absoluteString).asObservable().subscribe(onNext: { [weak self] object in
            guard let `self` = self else { return }
            guard let filename = String.create(object) else { return }
            let path = FilePath(filename: filename, type: .temporary)
            self.fs.rm(path)
            self.storage.remove(url.absoluteString).subscribe().disposed(by: self.disposeBag)
        }).disposed(by: self.disposeBag)
    }
}
