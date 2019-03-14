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
import DeviceKit

class ApiServiceDefault: ApiService
{
    let config: ApiServiceConfig
    let storage: XStorageService
    
    var isAuthorized: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    var customerId: BehaviorRelay<String> = BehaviorRelay<String>(value: "")
    var error: BehaviorRelay<ApiError> = BehaviorRelay<ApiError>(value: ApiError(type: .unknown))

    fileprivate var accessToken: String?
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    fileprivate var retryMap: [String: Int] = [:]
    
    init(config: ApiServiceConfig, storage: XStorageService)
    {
        self.config = config
        self.storage = storage
        
        self.loadCredentials()
    }
    
    // MARK: - Auth
    
    func createProfile(year: Int, sex: Sex) -> Observable<Void>
    {
        let device = Device()
        
        let params: [String: Any] = [
            "yearOfBirth": year,
            "sex": sex.rawValue,
            "dtTC": Int(Date().timeIntervalSince1970),
            "dtLA": Int(Date().timeIntervalSince1970),
            "dtPN": Int(Date().timeIntervalSince1970),
            "locale": "en",
            "deviceModel": device.description,
            "osVersion": device.systemVersion
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
    func getLMM(_ resolution: String, lastActionDate: Date?, source: SourceFeedType) -> Observable<ApiLMMResult>
    {
        var params: [String: Any] = [
            "resolution": resolution,
            "lastActionTime": lastActionDate == nil ? 0 : Int(lastActionDate!.timeIntervalSince1970 * 1000.0),
            "source": source.rawValue
        ]
        
        if let accessToken = self.accessToken {
            params["accessToken"] = accessToken
        }
        
        log("LMM source: \(source.rawValue)", level: .low)
        
        return self.requestGET(path: "feeds/get_lmm", params: params)
            //.timeout(2.0, scheduler: MainScheduler.instance)
            .flatMap ({ jsonDict -> Observable<ApiLMMResult> in
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
            }).do(onError: { error in
                log("ERROR: feeds/get_lmm: \(error)", level: .high)
            })
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
        
        return self.requestGET(path: "feeds/get_new_faces", params: params)            
            .flatMap { jsonDict -> Observable<[ApiProfile]> in
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
    
    func getStatusText() -> Observable<String>
    {
        return RxAlamofire.request(.get, "web_url_error_status".localized(), parameters: [:], headers: [:]).string()
    }
    
    // MARK: - Basic
    
    fileprivate func request(_ method: HTTPMethod, path: String, jsonBody: [String: Any], id: String? = nil) -> Observable<[String: Any]>
    {
        let requestId = id ?? UUID().uuidString
        let url = self.config.endpoint + "/" + path
        let buildVersion = (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as?  String) ?? "0"
        let timestamp = Date()
        
        let retryCount = (retryMap[requestId] ?? -1) + 1
        retryMap[requestId] = retryCount
        
        log("STARTED: \(method) \(url)", level: .low)
        
        return RxAlamofire.request(method, url, parameters: jsonBody, encoding: JSONEncoding.default, headers: [
            "x-ringoid-ios-buildnum": buildVersion,
            ]).responseJSON()
            .do(onError: { [weak self] error in
                self?.checkConnectionError(error as NSError)
            })
            .flatMap({ [weak self] response -> Observable<[String: Any]> in
                guard response.response?.statusCode == 200 else {
                    self?.error.accept(ApiError(type: .non200StatusCode))
                    
                    return .error(createError("Non 200 status code", type: .hidden))
                }
                
                
                var jsonDict: [String: Any] = [:]
                
                switch response.result {
                case .success(let obj):
                    do {
                        jsonDict = try self?.validateJsonResponse(obj) ?? [:]
                    } catch {
                        let interval = Int(Date().timeIntervalSince(timestamp) * 1000.0)
                        
                        log("FAILURE: url: \(url) error: \(error)", level: .low)
                        log("Duration: \(interval) ms", level: .low)
                        self?.retryMap.removeValue(forKey: requestId)
                        
                        return .error(error)
                    }
                default: break
                }
                
                if let repeatAfter = jsonDict["repeatRequestAfter"] as? Int, repeatAfter >= 1 {
                    guard retryCount < 5 else { self?.retryMap.removeValue(forKey: requestId); return .error(createError("Retry limit exceeded", type: .hidden)) }
                    
                    SentryService.shared.send(.repeatAfterDelay)
                    log("repeating after \(repeatAfter) \(url)", level: .low)
                    
                    return Observable<Void>.just(())
                        .delay(RxTimeInterval(Double(repeatAfter) / 1000.0), scheduler: MainScheduler.instance)
                        .flatMap ({ _ -> Observable<[String: Any]> in
                            return self!.request(method, path: path, jsonBody: jsonBody, id: requestId)
                    })
                }
                
                let interval = Int(Date().timeIntervalSince(timestamp) * 1000.0)
                log("SUCCESS: url: \(url)", level: .low)
                log("Duration: \(interval) ms", level: .low)
                self?.retryMap.removeValue(forKey: requestId)
                
                return .just(jsonDict)
            })
    }
    
    fileprivate func requestGET(path: String, params: [String: Any], id: String? = nil) -> Observable<[String: Any]>
    {
        let requestId = id ?? UUID().uuidString
        let url = self.config.endpoint + "/" + path
        let buildVersion = (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as?  String) ?? "0"
        let timestamp = Date()
        
        let retryCount = (retryMap[requestId] ?? -1) + 1
        retryMap[requestId] = retryCount
        
        log("STARTED: GET \(url)", level: .low)
        
        return RxAlamofire.request(.get, url, parameters: params, headers: [
            "x-ringoid-ios-buildnum": buildVersion,
            ]).responseJSON()
            .do(onError: { [weak self] error in
                self?.checkConnectionError(error as NSError)
            }, onDispose: {
                log("DISPOSED: \(url)", level: .low)
            })
            .flatMap({ [weak self] response -> Observable<[String: Any]> in
                if Date().timeIntervalSince(timestamp) > 2.0 {
                    log("Request took more then 2000ms", level: .high)
                    SentryService.shared.send(.responseGeneralDelay)
                }
                
                guard response.response?.statusCode == 200 else {
                    self?.error.accept(ApiError(type: .non200StatusCode))
                    
                    return .error(createError("Non 200 status code", type: .hidden))
                }
                
                var jsonDict: [String: Any] = [:]
                
                switch response.result {
                case .success(let obj):
                    do {
                        jsonDict = try self?.validateJsonResponse(obj) ?? [:]
                    } catch {
                        let interval = Int(Date().timeIntervalSince(timestamp) * 1000.0)
                        log("FAILURE: url: \(url) error: \(error)", level: .low)
                        log("Duration: \(interval) ms", level: .low)
                        self?.retryMap.removeValue(forKey: requestId)
                        
                        return .error(error)
                    }
                    
                default: break
                }
                
                if let repeatAfter = jsonDict["repeatRequestAfter"] as? Int, repeatAfter >= 1 {
                    guard retryCount < 5 else { self?.retryMap.removeValue(forKey: requestId); return .error(createError("Retry limit exceeded", type: .hidden)) }
                    
                    SentryService.shared.send(.repeatAfterDelay)
                    log("repeating after \(repeatAfter) \(url)", level: .low)
                    
                    return Observable<Void>.just(())
                        .delay(RxTimeInterval(Double(repeatAfter) / 1000.0), scheduler: MainScheduler.instance)
                        .flatMap ({ _ -> Observable<[String: Any]> in
                            return self!.requestGET(path: path, params: params, id: requestId)
                        })
                }
                
                let interval = Int(Date().timeIntervalSince(timestamp) * 1000.0)
                log("SUCCESS: url: \(url)", level: .low)
                log("Duration: \(interval) ms", level: .low)
                self?.retryMap.removeValue(forKey: requestId)
                
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
    
    fileprivate func checkConnectionError(_ error: NSError)
    {
        if error.code == NSURLErrorTimedOut {
            self.error.accept(ApiError(type: .connectionTimeout))
        }
        
        if error.code == NSURLErrorNetworkConnectionLost {
            self.error.accept(ApiError(type: .connectionLost))
        }
        
        if error.code == NSURLErrorNotConnectedToInternet {
            self.error.accept(ApiError(type: .notConnectedToInternet))
        }
        
        if error.code == NSURLErrorSecureConnectionFailed {
            self.error.accept(ApiError(type: .secureConnectionFailed))
        }
    }
}
