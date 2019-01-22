//
//  UserProfilePhotoViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 22/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Nuke

class UserProfilePhotoViewController: UIViewController
{
    var photo: UserPhoto?
    {
        didSet {
            self.update()
        }
    }
    
    static func create() -> UserProfilePhotoViewController
    {
        return Storyboards.userProfile().instantiateViewController(withIdentifier: "user_profile_photo_vc") as! UserProfilePhotoViewController
    }
    
    @IBOutlet fileprivate weak var photoView: UIImageView?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.update()
    }
    
    // MARK: -
    
    fileprivate func update()
    {
        guard let photoView = self.photoView else { return }
        guard let urlStr = self.photo?.url, let url = URL(string: urlStr) else {
            photoView.image = nil
            
            return
        }
        
        Nuke.loadImage(with: url, into: photoView)
    }
}
