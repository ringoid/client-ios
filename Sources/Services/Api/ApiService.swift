//
//  ApiService.swift
//  ringoid
//
//  Created by Victor Sukochev on 02/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

typealias ApiLMMResult = (likesYou: [ApiLMMProfile],  matches: [ApiLMMProfile], messages: [ApiLMMProfile])

protocol ApiService
{
    var isAuthorized: BehaviorRelay<Bool> { get }
    
    func createProfile(year: Int, sex: Sex) -> Observable<Void>
    
    func getNewFaces(_ resolution: PhotoResolution, lastActionDate: Date?) -> Observable<[ApiProfile]>
    
    func getLMM(_ resolution: PhotoResolution, lastActionDate: Date?) -> Observable<ApiLMMResult>
    
    func getPresignedImageUrl(_ photoId: String, fileExtension: String) -> Observable<ApiUserPhoto>
    
    func sendActions(_ actions: [ApiAction]) -> Observable<Date>
    
    func getUserOwnPhotos(_ resolution: PhotoResolution) -> Observable<[ApiPhoto]>
}
