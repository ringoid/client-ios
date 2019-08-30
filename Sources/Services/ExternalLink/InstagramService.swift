//
//  InstagramService.swift
//  ringoid
//
//  Created by Victor Sukochev on 29/08/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

fileprivate let instagramEscapeCharacters = CharacterSet(charactersIn: "@")

class InstagramService: ExternalLinkService
{
    var title: String
    {
        return "Instagram"
    }
    
    func isValid(_ link: String) -> Bool
    {
        return link != "unknown"
    }
    
    func extractId(_ link: String) -> String
    {
        var result: String = ""
        
        if link.isUrlLink() {
            result = (link as NSString).lastPathComponent.trimmingCharacters(in: instagramEscapeCharacters).trimmingCharacters(in: .whitespaces)
        } else {
            result = link.trimmingCharacters(in: instagramEscapeCharacters).trimmingCharacters(in: .whitespaces)
        }
        
        return result
    }
    
    func move(_ to: String)
    {
        let userId = self.extractId(to)
        
        guard let url = URL(string: "https://www.instagram.com/\(userId)/") else { return }

        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
