//
//  ApiService.swift
//  ringoid
//
//  Created by Victor Sukochev on 02/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

protocol ApiService
{
    var isAuthorized: BehaviorRelay<Bool> { get }
    
    func createProfile(year: Int, sex: Sex) -> Observable<Void>
    func getPresignedImageUrl(_ photoId: String, fileExtension: String) -> Observable<ApiPhoto>
}
