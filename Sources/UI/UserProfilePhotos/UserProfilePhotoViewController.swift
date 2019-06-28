//
//  UserProfilePhotoViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 22/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import Nuke
import RxSwift
import RxCocoa

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
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    @IBOutlet fileprivate weak var photoView: UIImageView?
    @IBOutlet fileprivate weak var photoIdLabel: UILabel?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.update()
        self.updateBindings()
        
        #if STAGE
        self.photoIdLabel?.text = "Photo: " + String(self.photo?.id?.prefix(4) ?? "")
        self.photoIdLabel?.isHidden = false
        #endif
    }
    
    // MARK: -
    
    fileprivate func update()
    {
        guard let photoView = self.photoView else { return }
        guard let url = self.photo?.filepath().url() else {
            photoView.image = nil
            
            return
        }
        
        ImageService.shared.load(url, thumbnailUrl: nil, to: photoView)
    }
    
    fileprivate func updateBindings()
    {
        
    }
}
