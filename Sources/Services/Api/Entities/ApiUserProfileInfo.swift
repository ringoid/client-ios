//
//  ApiUserProfileInfo.swift
//  ringoid
//
//  Created by Victor Sukochev on 24/06/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

struct ApiUserProfileInfo
{
    let property: Int
    let transport: Int
    let income: Int
    let height: Int
    let educationLevel: Int
    let hairColor: Int
    let children: Int
    let name: String
    let jobTitle: String
    let company: String
    let education: String
    let about: String
    let instagram: String
    let tikTok: String
    let whereLive: String
    let whereFrom: String
}

extension ApiUserProfileInfo
{
    static func parse(_ dict: [String: Any]) -> ApiUserProfileInfo?
    {
        guard let property = dict["property"] as? Int else { return nil }
        guard let transport = dict["transport"] as? Int else { return nil }
        guard let income = dict["income"] as? Int else { return nil }
        guard let height = dict["height"] as? Int else { return nil }
        guard let educationLevel = dict["educationLevel"] as? Int else { return nil }
        guard let hairColor = dict["hairColor"] as? Int else { return nil }
        guard let children = dict["children"] as? Int else { return nil }
        guard let name = dict["name"] as? String else { return nil }
        guard let jobTitle = dict["jobTitle"] as? String else { return nil }
        guard let company = dict["company"] as? String else { return nil }
        guard let education = dict["education"] as? String else { return nil }
        guard let about = dict["about"] as? String else { return nil }
        guard let instagram = dict["instagram"] as? String else { return nil }
        guard let tikTok = dict["tikTok"] as? String else { return nil }
        guard let whereLive = dict["whereLive"] as? String else { return nil }
        guard let whereFrom = dict["whereFrom"] as? String else { return nil }
        
        return ApiUserProfileInfo(
            property: property,
            transport: transport,
            income: income,
            height: height,
            educationLevel: educationLevel,
            hairColor: hairColor,
            children: children,
            name: name,
            jobTitle: jobTitle,
            company: company,
            education: education,
            about: about,
            instagram: instagram,
            tikTok: tikTok,
            whereLive: whereLive,
            whereFrom: whereFrom
        )
    }
    
    func json() -> [String: Any]
    {
        return [
            "property": self.property,
            "transport": self.transport,
            "income": self.income,
            "height": self.height,
            "educationLevel": self.educationLevel,
            "hairColor": self.hairColor,
            "children": self.children,
            "name": self.name,            
            "company": self.company,
            "jobTitle": self.jobTitle,
            "education": self.education,
            "about": self.about,
            "instagram": self.instagram,
            "tikTok": self.tikTok,
            "whereLive": self.whereLive,
            "whereFrom": self.whereFrom
        ]
    }
}
