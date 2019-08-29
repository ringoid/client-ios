//
//  ExternalLinkService.swift
//  ringoid
//
//  Created by Victor Sukochev on 29/08/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

protocol ExternalLinkService
{
    var title: String { get }
    
    func isValid(_ link: String) -> Bool
    func extractId(_ link: String) -> String
    func move(_ to: String)
}

extension String
{
    func isUrlLink() -> Bool
    {
        return self.contains("https://") || self.contains("http://")
    }
}
