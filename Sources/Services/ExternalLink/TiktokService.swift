//
//  TiktokService.swift
//  ringoid
//
//  Created by Victor Sukochev on 29/08/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

fileprivate let tiktokEscapeCharacters = CharacterSet(charactersIn: "@")

class TiktokService: ExternalLinkService
{
    var title: String
    {
        return "Tiktok"
    }
    
    func isValid(_ link: String) -> Bool
    {
        return link != "unknown"
    }
    
    func extractId(_ link: String) -> String
    {
        var result: String = ""
        
        if link.isUrlLink() {
            result = (link.replacingOccurrences(of: " ", with: "") as NSString).lastPathComponent.trimmingCharacters(in: tiktokEscapeCharacters)
        } else {
            result = link.replacingOccurrences(of: " ", with: "").trimmingCharacters(in: tiktokEscapeCharacters)
        }
        
        return result
    }
    
    func move(_ to: String)
    {
        let userId = self.extractId(to)
        
        guard let url = URL(string: "https://www.tiktok.com/@\(userId)") else { return }
        
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
