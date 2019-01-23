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
    @IBOutlet fileprivate weak var likeView: UIView?
    @IBOutlet fileprivate weak var likeLabel: UILabel?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.update()
        self.updateBindings()
    }
    
    // MARK: -
    
    fileprivate func update()
    {
        guard let photoView = self.photoView else { return }
        guard let url = self.photo?.filepath().url() else {
            photoView.image = nil
            
            return
        }
        
        Nuke.loadImage(with: url, into: photoView)
    }
    
    fileprivate func updateBindings()
    {
        self.photo?.rx.observe(UserPhoto.self, "likes").subscribe(onNext: { [weak self] _ in
            guard let photo = self?.photo else {
                self?.likeView?.isHidden = true
                self?.likeLabel?.isHidden = true
                
                return
            }
            
            self?.likeLabel?.text = "\(photo.likes)"
            self?.likeView?.isHidden = photo.likes == 0
            self?.likeLabel?.isHidden = photo.likes == 0
        }).disposed(by: self.disposeBag)
    }
}