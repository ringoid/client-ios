//
//  ApiService.swift
//  ringoid
//
//  Created by Victor Sukochev on 02/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

typealias ApiLMMResult = (likesYou: [ApiLMMProfile],  matches: [ApiLMMProfile], hellos: [ApiLMMProfile])

enum ApiErrorType: String
{
    case unknown = "Unknown"
    case internalServerError = "InternalServerError"
    case invalidAccessTokenClientError = "InvalidAccessTokenClientError"
    case tooOldAppVersionClientError = "TooOldAppVersionClientError"
    case wrongRequestParamsClientError = "WrongRequestParamsClientError"
    
    case notConnectedToInternet
    case connectionLost
    case secureConnectionFailed
    case connectionTimeout
    case non200StatusCode
}

struct ApiError
{
    let type: ApiErrorType
    let error: Error?
}

protocol ApiService
{
    var isAuthorized: BehaviorRelay<Bool> { get }
    var customerId: BehaviorRelay<String> { get }
    var error: BehaviorRelay<ApiError> { get }
    
    func createProfile(year: Int, sex: Sex, privateKey: String?, referralCode: String?) -> Observable<Void>
    func logout() -> Observable<Void>
    func reset()
    func claim(_ code: String) -> Observable<Void>
    
    func getNewFaces(_ resolution: String, lastActionDate: Date?) -> Observable<[ApiProfile]>
    
    func getLMHIS(_ resolution: String, lastActionDate: Date?, source: SourceFeedType) -> Observable<ApiLMMResult>
    
    func getPresignedImageUrl(_ photoId: String, fileExtension: String) -> Observable<ApiUserPhotoPlaceholder>
    func getUserOwnPhotos(_ resolution: String) -> Observable<[ApiUserPhoto]>
    func deletePhoto(_ photoId: String) -> Observable<Void>
    
    func sendActions(_ actions: [ApiAction]) -> Observable<Date>
    
    func getStatusText() -> Observable<String>
    
    func updatePush(_ token: String) -> Observable<Void>
    func updateSettings(_ locale: String?, push: Bool?, timezone: Int?) -> Observable<Void>
}
