//
//  ApiService.swift
//  ringoid
//
//  Created by Victor Sukochev on 02/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift

protocol ApiService
{
    func createProfile() -> Observable<ApiProfile>
}
