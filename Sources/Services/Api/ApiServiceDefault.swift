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

class ApiServiceDefault: ApiService
{
    let config: ApiServiceConfig
    let storage: XStorageService
    
    var isAuthorized: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)

    fileprivate var accessToken: String?
    fileprivate var customerId: String?
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
        
        return self.request(.post, path: "auth/create_profile", jsonBody: params).json().flatMap { [weak self] jsonObj -> Observable<Void> in
            var jsonDict: [String: Any]? = nil
            
            do {
                jsonDict = try self?.validateJsonResponse(jsonObj)
            } catch {
                return .error(error)
            }
            
            guard let accessToken = jsonDict?["accessToken"] as? String else {
                let error = createError("Create profile: no token in response", code: 2)
                
                return .error(error)
            }
            
            guard let customerId = jsonDict?["customerId"] as? String else {
                let error = createError("Create profile: no customer id in response", code: 3)
                
                return .error(error)
            }
            
            self?.accessToken = accessToken
            self?.customerId = customerId
            self?.storeCredentials()
            
            return .just(())
        }        
    }
    
    // MARK: - Feeds
    func getLMM(_ resolution: PhotoResolution, lastActionDate: Date?) -> Observable<ApiLMMResult>
    {
        var params: [String: Any] = [
            "resolution": resolution.rawValue,
            "lastActionTime": 0//lastActionDate == nil ? 0 : Int(lastActionDate!.timeIntervalSince1970)
        ]
        
        if let accessToken = self.accessToken {
            params["accessToken"] = accessToken
        }
        
        return self.requestGET(path: "feeds/get_lmm", params: params).json().flatMap { [weak self] jsonObj -> Observable<ApiLMMResult> in
            var jsonDict: [String: Any]? = nil
            
            do {
                jsonDict = try self?.validateJsonResponse(jsonObj)
            } catch {
                return .error(error)
            }
            
            guard let likesYouArray = jsonDict?["likesYou"] as? [[String: Any]] else {
                let error = createError("ApiService: wrong likesYou profiles data format", code: 4)
                
                return .error(error)
            }
            
            guard let matchesArray = jsonDict?["matches"] as? [[String: Any]] else {
                let error = createError("ApiService: wrong matches profiles data format", code: 5)
                
                return .error(error)
            }
            
            guard let messagesArray = jsonDict?["messages"] as? [[String: Any]] else {
                let error = createError("ApiService: wrong messages profiles data format", code: 6)
                
                return .error(error)
            }
            
            return .just((
                likesYou: likesYouArray.compactMap({ApiLMMProfile.lmmParse($0)}),
                matches: matchesArray.compactMap({ApiLMMProfile.lmmParse($0)}),
                messages: messagesArray.compactMap({ApiLMMProfile.lmmParse($0)})
            ))
        }
    }
    
    func getNewFaces(_ resolution: PhotoResolution, lastActionDate: Date?) -> Observable<[ApiProfile]>
    {
        var params: [String: Any] = [
            "resolution": resolution.rawValue,
            "lastActionTime": lastActionDate == nil ? 0 : Int(lastActionDate!.timeIntervalSince1970),
            "limit": 20
        ]
        
        if let accessToken = self.accessToken {
            params["accessToken"] = accessToken
        }
        
        return self.requestGET(path: "feeds/get_new_faces", params: params).json().flatMap { [weak self] jsonObj -> Observable<[ApiProfile]> in
            var jsonDict: [String: Any]? = nil
            
            do {
                jsonDict = try self?.validateJsonResponse(jsonObj)
            } catch {
                return .error(error)
            }
            
            guard let profilesArray = jsonDict?["profiles"] as? [[String: Any]] else {
                let error = createError("ApiService: wrong profiles data format", code: 3)
                
                return .error(error)
            }
            
            return .just(profilesArray.compactMap({ ApiProfile.parse($0) }))
        }
    }
    
    // MARK: - Images
    
    func getPresignedImageUrl(_ photoId: String, fileExtension: String) -> Observable<ApiUserPhoto>
    {
        var params: [String: Any] = [
            "extension": fileExtension,
            "clientPhotoId": photoId
        ]

        if let accessToken = self.accessToken {
            params["accessToken"] = accessToken
        }

        return self.request(.post, path: "image/get_presigned", jsonBody: params).json().flatMap { [weak self] jsonObj -> Observable<ApiUserPhoto> in
            var jsonDict: [String: Any]? = nil
            
            do {
                jsonDict = try self?.validateJsonResponse(jsonObj)
            } catch {
                return .error(error)
            }
            
            guard let photo = ApiUserPhoto.parse(jsonDict) else {
                let error = createError("ApiService: wrong photo data format", code: 2)
                
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
        
        return self.request(.post, path: "actions/actions", jsonBody: params).json().flatMap { [weak self] jsonObj -> Observable<Date> in
            var jsonDict: [String: Any]? = nil
            
            do {
                jsonDict = try self?.validateJsonResponse(jsonObj)
            } catch {
                return .error(error)
            }
            
            guard let lastActionTime = jsonDict?["lastActionTime"] as? Int else {
                let error = createError("ApiService: no lastActionTime field provided", code: 7)
                
                return .error(error)
            }
            
            let date = Date(timeIntervalSince1970: TimeInterval(lastActionTime))
            
            return .just(date)
        }
    }
    
    // MARK: - Basic
    
    fileprivate func request(_ method: HTTPMethod, path: String, jsonBody: [String: Any]) -> Observable<DataRequest>
    {
        let url = self.config.endpoint + "/" + path
        return RxAlamofire.request(method, url, parameters: jsonBody, encoding: JSONEncoding.default, headers: [
            "x-ringoid-ios-buildnum": "100",
            ])
    }
    
    fileprivate func requestGET(path: String, params: [String: Any]) -> Observable<DataRequest>
    {
        let url = self.config.endpoint + "/" + path
        return RxAlamofire.request(.get, url, parameters: params, headers: [
            "x-ringoid-ios-buildnum": "100",
            ])
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
        
        guard let id = self.customerId else { return }
        
        self.storage.store(id, key: "customer_id").subscribe().disposed(by: self.disposeBag)
    }
    
    fileprivate func loadCredentials()
    {
        self.storage.object("access_token").subscribe(onNext: { [weak self] token in
            self?.accessToken = token as? String
            self?.isAuthorized.accept((token as? String) != nil)
        }).disposed(by: self.disposeBag)
        
        self.storage.object("customer_id").subscribe(onNext: { [weak self] id in
            self?.customerId = id as? String
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func validateJsonResponse(_ json: Any) throws -> [String: Any]?
    {
        guard let jsonDict = json as? [String: Any] else {

            throw createError("ApiService: wrong response format", code: 0)
        }
        
        if let _ = jsonDict["errorCode"] as? String,
            let errorMessage = jsonDict["errorMessage"] as? String {
            
            throw createError("External error: \(errorMessage)", code: 1)
        }
        
        return jsonDict
    }
}
