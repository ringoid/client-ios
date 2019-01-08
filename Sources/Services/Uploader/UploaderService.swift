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
    func upload(_ from: URL, to: URL) -> Observable<Void>
}
