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
    
    fileprivate static let newFacesStoryboard: UIStoryboard = UIStoryboard(name: "NewFaces", bundle: nil)
    fileprivate static let mainLmmStoryboard: UIStoryboard = UIStoryboard(name: "MainLMM", bundle: nil)
    fileprivate static let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
    fileprivate static let rootStoryboard: UIStoryboard = UIStoryboard(name: "Root", bundle: nil)
    fileprivate static let authStoryboard: UIStoryboard = UIStoryboard(name: "Auth", bundle: nil)
    fileprivate static let userProfileStoryboard: UIStoryboard = UIStoryboard(name: "UserProfile", bundle: nil)
    fileprivate static let chatStoryboard: UIStoryboard = UIStoryboard(name: "Chat", bundle: nil)
    
    static func root() -> UIStoryboard
    {
        return Storyboards.rootStoryboard
    }
    
    static func auth() -> UIStoryboard
    {
        return Storyboards.authStoryboard
    }
    
    static func main() -> UIStoryboard
    {
        return Storyboards.mainStoryboard
    }
    
    static func newFaces() -> UIStoryboard
    {
        return Storyboards.newFacesStoryboard
    }
    
    static func mainLMM() -> UIStoryboard
    {
        return Storyboards.mainLmmStoryboard
    }
    
    static func userProfile() -> UIStoryboard
    {
        return Storyboards.userProfileStoryboard
    }
    
    static func chat() -> UIStoryboard
    {
        return Storyboards.chatStoryboard
    }
}
