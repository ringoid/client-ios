
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
        
        self.checkStoredUploads()
        self.uploadInterrupted()
    }
    
    func upload(_ data: Data, to: URL) -> Observable<Void>
    {
        log("Photo uploading started \(to)", level: .high)
        
        let request = Alamofire.upload(data, to: to, method: .put, headers: nil)
        self.activeUploads[to] = request.task
        self.store(to.absoluteString, data: data)
        
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
                
                self.remove(to.absoluteString)
                    
                observer.onNext(())
            }

            return Disposables.create()
        }).retry(3)
    }
    
    func cancel(_ url: URL)
    {
        self.activeUploads[url]??.cancel()
        self.remove(url.absoluteString)
    }
    
    // MARK: -
    
    fileprivate func uploadInterrupted()
    {
        self.storage.object("stored_uploads").subscribe(onNext: { [weak self] obj in
            guard let `self` = self else { return }
            guard let keys = [String].create(obj) else { return }
            
            keys.forEach { key in
                self.storage.object(key).subscribe(onNext: { [weak self] filenameObj in
                    guard let `self` = self else { return }
                    guard let filename = String.create(filenameObj) else { return }
                    
                    let path = FilePath(filename: filename, type: .temporary)
                    guard let data = try? Data(contentsOf: path.url()) else { return }
                    
                   self.upload(data, to: URL(string: key)!).subscribe().disposed(by: self.disposeBag)
                }).disposed(by: self.disposeBag)
            }
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func store(_ key: String, data: Data)
    {
        let path = FilePath.unique(.temporary)
        try? data.write(to: path.url())
        self.storage.object("stored_uploads").asObservable().subscribe(onNext: { [weak self] obj in
            guard let `self` = self else { return }
            
            var storedUploads: [String] = [String].create(obj) ?? []
            storedUploads.append(key)
            self.storage.store(path.filename, key: key).subscribe().disposed(by: self.disposeBag)
            self.storage.store(storedUploads, key: "stored_uploads").subscribe().disposed(by: self.disposeBag)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func remove(_ key: String)
    {
        self.storage.object(key).asObservable().subscribe(onNext: { [weak self] object in
            guard let `self` = self else { return }
            guard let filename = String.create(object) else { return }
            
            let path = FilePath(filename: filename, type: .temporary)
            self.fs.rm(path)
            self.storage.remove(key).subscribe().disposed(by: self.disposeBag)
            self.storage.object("stored_uploads").asObservable().subscribe(onNext: { [weak self] obj in
                guard let `self` = self else { return }
                
                var storedUploads: [String] = [String].create(obj) ?? []
                if let index = storedUploads.index(of: key) {
                    storedUploads.remove(at: index)
                    self.storage.store(storedUploads, key: "stored_uploads").subscribe().disposed(by: self.disposeBag)
                }
                
                self.storage.store(path.filename, key: key).subscribe().disposed(by: self.disposeBag)
            }).disposed(by: self.disposeBag)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func checkStoredUploads()
    {
        self.storage.object("stored_uploads").subscribe(onError: { _ in
            self.storage.store([String](), key: "stored_uploads").subscribe().disposed(by: self.disposeBag)
        }).disposed(by: self.disposeBag)
    }
}
