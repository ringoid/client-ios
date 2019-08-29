//
//  ExternalLinkManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 29/08/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

class ExternalLinkManager
{
    fileprivate let instagram = InstagramService()
    fileprivate let tiktok = TiktokService()

    func availableServices(_ profile: Profile) -> [(ExternalLinkService, String)]
    {
        var result: [(ExternalLinkService, String)] = []
        
        if let link = profile.instagram, self.instagram.isValid(link) {
            result.append((self.instagram, self.instagram.extractId(link)))
        }
        
        if let link = profile.tikTok, self.tiktok.isValid(link) {
            result.append((self.tiktok, self.tiktok.extractId(link)))
        }
        
        return result
    }
    
    func availableServices(_ profile: UserProfile) -> [(ExternalLinkService, String)]
    {
        var result: [(ExternalLinkService, String)] = []
        
        if let link = profile.instagram, self.instagram.isValid(link) {
            result.append((self.instagram, self.instagram.extractId(link)))
        }
        
        if let link = profile.tikTok, self.tiktok.isValid(link) {
            result.append((self.tiktok, self.tiktok.extractId(link)))
        }
        
        return result
    }
}
