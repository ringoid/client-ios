//
//  Storyboards.swift
//  ringoid
//
//  Created by Victor Sukochev on 10/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class Storyboards
{
    private init() {}
    
    static func root() -> UIStoryboard
    {
        return UIStoryboard(name: "Root", bundle: nil)
    }
    
    static func auth() -> UIStoryboard
    {
        return UIStoryboard(name: "Auth", bundle: nil)
    }
    
    static func main() -> UIStoryboard
    {
        return UIStoryboard(name: "Main", bundle: nil)
    }
    
    static func newFaces() -> UIStoryboard
    {
        return UIStoryboard(name: "NewFaces", bundle: nil)
    }
    
    static func mainLMM() -> UIStoryboard
    {
        return UIStoryboard(name: "MainLMM", bundle: nil)
    }
    
    static func userProfile() -> UIStoryboard
    {
        return UIStoryboard(name: "UserProfile", bundle: nil)
    }
    
    static func chat() -> UIStoryboard
    {
        return UIStoryboard(name: "Chat", bundle: nil)
    }
}
