//
//  ApiServiceDefault.swift
//  ringoid
//
//  Created by Victor Sukochev on 02/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxAlamofire
import Alamofire

class ApiServiceDefault: ApiService
{
    let config: ApiServiceConfig
    
    init(config: ApiServiceConfig)
    {
        self.config = config
    }
    
    func createProfile() -> Observable<ApiProfile>
    {
        return self.request(.post, path: "create_profile").json().flatMap { jsonObj -> Observable<ApiProfile> in
            guard let jsonDict = jsonObj as? [String: Any] else {
                let error = createError("Create profile: wrong response format", code: 0)
                
                return Observable<ApiProfile>.error(error)
            }
            
            if let _ = jsonDict["errorCode"] as? String,
                let errorMessage = jsonDict["errorMessage"] as? String {
                let error = createError("External error: \(errorMessage)", code: 1)
                
                return Observable<ApiProfile>.error(error)
            }
            
            guard let profile = ApiProfile.parse(jsonDict) else {
                let error = createError("Create profile: wrong profile format", code: 0)
                
                return Observable<ApiProfile>.error(error)
            }
            
            return Observable.just(profile)
        }        
    }
    
    // MARK: - Basic
    
    func request(_ method: HTTPMethod, path: String) -> Observable<DataRequest>
    {
        let url = self.config.endpoint + "/" + path
        return RxAlamofire.request(method, url)
    }
}
