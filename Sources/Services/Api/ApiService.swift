//
//  ApiService.swift
//  ringoid
//
//  Created by Victor Sukochev on 02/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

typealias ApiLMMResult = (
    likesYou: [ApiLMMProfile],
    messages: [ApiLMMProfile],
    allLikesYouProfilesNum: Int,
    allMessagesProfilesNum: Int
)

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
    func login(_ email: String)  -> Observable<String>
    func change(_ email: String)  -> Observable<String>
    func verify(_ email: String, authSessionId: String, code: String) -> Observable<Void>
    func logout() -> Observable<Void>
    func reset()
    func claim(_ code: String) -> Observable<Void>
    
    func getNewFaces(_ resolution: String, lastActionDate: Date?) -> Observable<[ApiProfile]>
    func discover(_ resolution: String, lastActionDate: Date?, minAge: Int?, maxAge: Int?, maxDistance: Int?) -> Observable<[ApiProfile]>
    func getLMM(_ resolution: String, lastActionDate: Date?, source: SourceFeedType) -> Observable<ApiLMMResult>
    func getLC(_ resolution: String, lastActionDate: Date?, source: SourceFeedType, minAge: Int?, maxAge: Int?, maxDistance: Int?) -> Observable<ApiLMMResult>
    func getChat(_ profileId: String, resolution: String, lastActionDate: Date?) -> Observable<(ApiLMMProfile, Int)>
    
    func getProfile() -> Observable<ApiUserProfileInfo>
    func updateProfile(_ profile: ApiUserProfileInfo) -> Observable<Void>
    
    func getPresignedImageUrl(_ photoId: String, fileExtension: String) -> Observable<ApiUserPhotoPlaceholder>
    func getUserOwnPhotos(_ resolution: String) -> Observable<ApiUserProfile>
    func deletePhoto(_ photoId: String) -> Observable<Void>
    
    func sendActions(_ actions: [ApiAction]) -> Observable<Date>
    
    func getStatusText() -> Observable<String>
    
    func updatePush(_ token: String) -> Observable<Void>
    func updateSettings(_ locale: String?, eveningPush: Bool, likePush: Bool, matchPush: Bool, messagePush: Bool, timezone: Int?) -> Observable<Void>
}
