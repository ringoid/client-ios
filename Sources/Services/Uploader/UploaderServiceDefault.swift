
//
//  UploaderServiceDefault.swift
//  ringoid
//
//  Created by Victor Sukochev on 08/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxAlamofire

class UploaderServiceDefault: UploaderService
{
    func upload(_ from: URL, to: URL) -> Observable<Void>
    {
        let request = URLRequest(url: to)
        return RxAlamofire.upload(from, urlRequest: request).flatMap { _ -> Observable<Void> in
            return .just(())
        }
    }
}
