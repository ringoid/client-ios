//
//  UploaderService.swift
//  ringoid
//
//  Created by Victor Sukochev on 08/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift

protocol UploaderService
{
    func upload(_ data: Data, to: URL) -> Observable<Void>
    func cancel(_ url: URL)
}
