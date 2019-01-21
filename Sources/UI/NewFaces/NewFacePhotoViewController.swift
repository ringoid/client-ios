//
//  NewFacePhotoViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 10/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import Nuke
import RxSwift
import RxCocoa

class NewFacePhotoViewController: UIViewController
{
    var input: NewFaceProfileVMInput?
    var photo: Photo?
    {
        didSet {
            self.update()
        }
    }
    
    fileprivate var dispatchBag: DisposeBag = DisposeBag()
    
    @IBOutlet fileprivate weak var photoView: UIImageView!
    @IBOutlet fileprivate weak var likeView: UIImageView!
    
    static func create() -> NewFacePhotoViewController
    {
        let storyboard = Storyboards.newFaces()
        return storyboard.instantiateViewController(withIdentifier: "new_face_photo") as! NewFacePhotoViewController
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.likeView.isHidden = !self.isLikesAvailable()
        
        self.updateBindings()
        self.update()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        guard let profile = self.input?.profile, let photo = self.photo else { return }
        
        self.input?.actionsManager.startViewAction(profile, photo: photo)
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        guard
            let profile = self.input?.profile,
            let photo = self.photo,
            let type = self.input?.sourceType else { return }
        
        self.input?.actionsManager.stopViewAction(profile, photo: photo, sourceType: type)
    }
    
    // MARK: - Actions
    
    @IBAction func  onLike()
    {
        guard self.isLikesAvailable() else { return }
        guard let input = self.input, let photo = self.photo else { return }
        
        if photo.isLiked {
            input.actionsManager.add([.unlike],
                                     profile: input.profile,
                                     photo: photo,
                                     source: .newFaces
            )
        } else {
            input.actionsManager.likeActionProtected(
                input.profile,
                photo: photo,
                source: input.sourceType
            )
        }
        
        try? self.photo?.realm?.write({ [weak self] in
            self?.photo?.isLiked = !photo.isLiked
        })
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
    
    fileprivate func updateBindings()
    {
        self.dispatchBag = DisposeBag()
        
        self.photo?.rx.observe(Photo.self, "isLiked").subscribe(onNext: { [weak self] _ in
            let imgName = self?.photo?.isLiked == true ? "feed_like_selected" : "feed_like"
            self?.likeView?.image = UIImage(named: imgName)
        }).disposed(by: self.dispatchBag)
    }
    
    fileprivate func isLikesAvailable() -> Bool
    {
        guard let type = self.input?.sourceType else { return false }
        
        switch type {
        case .whoLikedMe: return true
        case .matches: return false
        case .messages: return false
        case .newFaces: return true
        }
    }
}

extension LMMType
{
    func sourceType() -> SourceFeedType
    {
        switch self {
        case .likesYou: return .whoLikedMe
        case .matches: return .matches
        case .messages: return .messages
        }
    }
}
