//
//  ApiServiceDefault.swift
//  ringoid
//
//  Created by Victor Sukochev on 02/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa
import RxAlamofire
import Alamofire
import Sentry

class ApiServiceDefault: ApiService
{
    let config: ApiServiceConfig
    let storage: XStorageService
    
    var isAuthorized: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    var customerId: BehaviorRelay<String> = BehaviorRelay<String>(value: "")
    var error: BehaviorRelay<ApiError> = BehaviorRelay<ApiError>(value: ApiError(type: .unknown))

    fileprivate var accessToken: String?
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init(config: ApiServiceConfig, storage: XStorageService)
    {
        self.config = config
        self.storage = storage
        
        self.loadCredentials()
    }
    
    // MARK: - Auth
    
    func createProfile(year: Int, sex: Sex) -> Observable<Void>
    {
        let params: [String: Any] = [
            "yearOfBirth": year,
            "sex": sex.rawValue,
            "dtTC": Int(Date().timeIntervalSince1970),
            "dtLA": Int(Date().timeIntervalSince1970),
            "dtPN": Int(Date().timeIntervalSince1970),
            "locale": "en",
            "deviceModel": "iPhone",
            "osVersion": "11.0"
        ]
        
        return self.request(.post, path: "auth/create_profile", jsonBody: params).flatMap { [weak self] jsonDict -> Observable<Void> in
            guard let accessToken = jsonDict["accessToken"] as? String else {
                let error = createError("Create profile: no token in response", type: .hidden)
                
                return .error(error)
            }
            
            guard let customerId = jsonDict["customerId"] as? String else {
                let error = createError("Create profile: no customer id in response", type: .hidden)
                
                return .error(error)
            }
            
            self?.accessToken = accessToken
            self?.customerId.accept(customerId)
            self?.storeCredentials()
            
            return .just(())
        }        
    }
    
    func logout() -> Observable<Void>
    {
        var params: [String: Any] = [:]
        
        if let accessToken = self.accessToken {
            params["accessToken"] = accessToken
        }
        
        return self.request(.post, path: "auth/delete", jsonBody: params).flatMap { [weak self] _ -> Observable<Void> in
            self?.clearCredentials()
            
            return .just(())
        }
    }
    
    func reset()
    {
        self.clearCredentials()
    }
    
    // MARK: - Feeds
    func getLMM(_ resolution: String, lastActionDate: Date?) -> Observable<ApiLMMResult>
    {
        var params: [String: Any] = [
            "resolution": resolution,
            "lastActionTime": lastActionDate == nil ? 0 : Int(lastActionDate!.timeIntervalSince1970 * 1000.0)
        ]
        
        if let accessToken = self.accessToken {
            params["accessToken"] = accessToken
        }
        
        return self.requestGET(path: "feeds/get_lmm", params: params)
            .take(1.5, scheduler: MainScheduler.instance)
            .flatMap { jsonDict -> Observable<ApiLMMResult> in
            guard let likesYouArray = jsonDict["likesYou"] as? [[String: Any]] else {
                let error = createError("ApiService: wrong likesYou profiles data format", type: .hidden)
                
                return .error(error)
            }
            
            guard let matchesArray = jsonDict["matches"] as? [[String: Any]] else {
                let error = createError("ApiService: wrong matches profiles data format", type: .hidden)
                
                return .error(error)
            }
            
            guard let messagesArray = jsonDict["messages"] as? [[String: Any]] else {
                let error = createError("ApiService: wrong messages profiles data format", type: .hidden)
                
                return .error(error)
            }
            
            return .just((
                likesYou: likesYouArray.compactMap({ApiLMMProfile.lmmParse($0)}),
                matches: matchesArray.compactMap({ApiLMMProfile.lmmParse($0)}),
                messages: messagesArray.compactMap({ApiLMMProfile.lmmParse($0)})
            ))
        }
    }
    
    func getNewFaces(_ resolution: String, lastActionDate: Date?) -> Observable<[ApiProfile]>
    {
        var params: [String: Any] = [
            "resolution": resolution,
            "lastActionTime": lastActionDate == nil ? 0 : Int(lastActionDate!.timeIntervalSince1970 * 1000.0),
            "limit": 20
        ]
        
        if let accessToken = self.accessToken {
            params["accessToken"] = accessToken
        }
        
        return self.requestGET(path: "feeds/get_new_faces", params: params).flatMap { jsonDict -> Observable<[ApiProfile]> in
            guard let profilesArray = jsonDict["profiles"] as? [[String: Any]] else {
                let error = createError("ApiService: wrong profiles data format", type: .hidden)
                
                return .error(error)
            }
            
            return .just(profilesArray.compactMap({ ApiProfile.parse($0) }))
        }
    }
    
    // MARK: - Images
    
    func getPresignedImageUrl(_ photoId: String, fileExtension: String) -> Observable<ApiUserPhotoPlaceholder>
    {
        var params: [String: Any] = [
            "extension": fileExtension,
            "clientPhotoId": photoId
        ]

        if let accessToken = self.accessToken {
            params["accessToken"] = accessToken
        }

        return self.request(.post, path: "image/get_presigned", jsonBody: params).flatMap { jsonDict -> Observable<ApiUserPhotoPlaceholder> in
            guard let photo = ApiUserPhotoPlaceholder.parse(jsonDict) else {
                let error = createError("ApiService: wrong photo data format", type: .hidden)
                
                return .error(error)
            }
            
            return .just(photo)
        }
    }
    
    // MARK: - Actions
    
    func sendActions(_ actions: [ApiAction]) -> Observable<Date>
    {
        var params: [String: Any] = [
            "actions": actions.map({ $0.json() })
        ]
        
        if let accessToken = self.accessToken {
            params["accessToken"] = accessToken
        }
        
        return self.request(.post, path: "actions/actions", jsonBody: params).flatMap { jsonDict -> Observable<Date> in
            guard let lastActionTime = jsonDict["lastActionTime"] as? Int else {
                let error = createError("ApiService: no lastActionTime field provided", type: .hidden)
                
                return .error(error)
            }
            
            let date = Date(timeIntervalSince1970: TimeInterval(lastActionTime) / 1000.0)
            
            return .just(date)
        }
    }
    
    // MARK: - User profile
    
    func getUserOwnPhotos(_ resolution: String) -> Observable<[ApiUserPhoto]>
    {
        var params: [String: Any] = [
            "resolution": resolution
        ]
        
        if let accessToken = self.accessToken {
            params["accessToken"] = accessToken
        }
        
        return self.requestGET(path: "image/get_own_photos", params: params).flatMap { jsonDict -> Observable<[ApiUserPhoto]> in
            guard let photosArray = jsonDict["photos"] as? [[String: Any]] else {
                let error = createError("ApiService: wrong photos data format", type: .hidden)
                
                return .error(error)
            }
            
            return .just(photosArray.compactMap({ ApiUserPhoto.parse($0) }))
        }
    }
    
    func deletePhoto(_ photoId: String) -> Observable<Void>
    {
        var params: [String: Any] = [
            "photoId": photoId
        ]
        
        if let accessToken = self.accessToken {
            params["accessToken"] = accessToken
        }
        
        return self.request(.post, path: "image/delete_photo", jsonBody: params).flatMap { _ -> Observable<Void> in
            return .just(())
        }
    }
    
    // MARK: - Basic
    
    fileprivate func request(_ method: HTTPMethod, path: String, jsonBody: [String: Any]) -> Observable<[String: Any]>
    {
        let url = self.config.endpoint + "/" + path
        let buildVersion = (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as?  String) ?? "0"
        let timestamp = Date()
        
        return RxAlamofire.request(method, url, parameters: jsonBody, encoding: JSONEncoding.default, headers: [
            "x-ringoid-ios-buildnum": buildVersion,
            ]).json().flatMap({ [weak self] obj -> Observable<[String: Any]> in
                if Date().timeIntervalSince(timestamp) > 1.0 {
                    SentryService.shared.send(.responseGeneralDelay)
                }
                
                var jsonDict: [String: Any] = [:]
                
                do {
                    jsonDict = try self?.validateJsonResponse(obj) ?? [:]
                } catch {
                    return .error(error)
                }
                
                if let repeatAfter = jsonDict["repeatRequestAfter"] as? Int, repeatAfter >= 1 {
                    SentryService.shared.send(.repeatAfterDelay)
                    print("repeating after \(repeatAfter)")
                    return self!.request(method, path: path, jsonBody: jsonBody).delay(RxTimeInterval(Double(repeatAfter) * 1000.0), scheduler: MainScheduler.instance)
                }
                
                return .just(jsonDict)
            })
    }
    
    fileprivate func requestGET(path: String, params: [String: Any]) -> Observable<[String: Any]>
    {
        let url = self.config.endpoint + "/" + path
        let buildVersion = (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as?  String) ?? "0"
        let timestamp = Date()
        
        return RxAlamofire.request(.get, url, parameters: params, headers: [
            "x-ringoid-ios-buildnum": buildVersion,
            ]).json().flatMap({ [weak self] obj -> Observable<[String: Any]> in
                if Date().timeIntervalSince(timestamp) > 1.0 {
                    SentryService.shared.send(.responseGeneralDelay)
                }
                
                var jsonDict: [String: Any] = [:]
                
                do {
                    jsonDict = try self?.validateJsonResponse(obj) ?? [:]
                } catch {
                    return .error(error)
                }
                
                if let repeatAfter = jsonDict["repeatRequestAfter"] as? Int, repeatAfter >= 1 {
                    SentryService.shared.send(.repeatAfterDelay)
                    print("repeating after \(repeatAfter)")
                    return self!.requestGET(path: path, params: params).delay(RxTimeInterval(Double(repeatAfter) / 1000.0), scheduler: MainScheduler.instance)
                }
                
                return .just(jsonDict)
            })
    }
    
    // MARK: -
    
    fileprivate func storeCredentials()
    {
        defer {
            self.storage.sync()
        }
        
        guard let token = self.accessToken else { return }
        
        self.storage.store(token, key: "access_token").asObservable().subscribe().disposed(by: self.disposeBag)
        self.isAuthorized.accept(true)
        
        let id = self.customerId.value
        self.storage.store(id, key: "customer_id").subscribe().disposed(by: self.disposeBag)
        self.customerId.accept(id)
    }
    
    fileprivate func loadCredentials()
    {
        self.storage.object("access_token").subscribe(onNext: { [weak self] token in
            self?.accessToken = token as? String
            self?.isAuthorized.accept((token as? String) != nil)
        }).disposed(by: self.disposeBag)
        
        self.storage.object("customer_id").subscribe(onNext: { [weak self] id in
            self?.customerId.accept(id as? String ?? "")
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func clearCredentials()
    {
        self.storage.remove("access_token").subscribe().disposed(by: self.disposeBag)
        self.storage.remove("customer_id").subscribe().disposed(by: self.disposeBag)
        self.isAuthorized.accept(false)
    }
    
    fileprivate func validateJsonResponse(_ json: Any) throws -> [String: Any]?
    {
        guard let jsonDict = json as? [String: Any] else {
            throw createError("ApiService: wrong response format", type: .visible)
        }
        
        if let errorCode = jsonDict["errorCode"] as? String,
            let errorMessage = jsonDict["errorMessage"] as? String {
            
            if let apiErrorType = ApiErrorType(rawValue: errorCode) {
                self.error.accept(ApiError(type: apiErrorType))
            }
            
            throw createError("API error: \(errorMessage)", type: .api)
        }
        
        return jsonDict
    }
}
