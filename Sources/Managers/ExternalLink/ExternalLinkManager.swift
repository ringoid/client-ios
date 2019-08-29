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

    func availableServices(_ profile: Profile) -> [(ExternalLinkService, String)]
    {
        var result: [(ExternalLinkService, String)] = []
        
        if let link = profile.instagram, self.instagram.isValid(link) {
            result.append((self.instagram, self.instagram.extractId(link)))
        }
        
        return result
    }
}
