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
                return
            }
            
            let shadow = NSShadow()
            shadow.shadowColor = UIColor.black.withAlphaComponent(0.5)
            shadow.shadowOffset = CGSize(width: 1.0, height: 1.0)
            shadow.shadowBlurRadius = 1.0
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attributes: [NSAttributedString.Key : Any] = [
                .font: UIFont.systemFont(ofSize: 20.0, weight: .medium),
                .foregroundColor: UIColor.white,
                .shadow: shadow,
                .paragraphStyle: paragraphStyle
            ]
            
            self?.likeLabel?.attributedText = NSAttributedString(string: "\(photo.likes)", attributes: attributes)
        }).disposed(by: self.disposeBag)
    }
}
