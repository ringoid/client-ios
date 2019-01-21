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
    
    var isLikesAvailable: Bool = true
    
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
        
        self.likeView.isHidden = !self.isLikesAvailable
        
        self.updateBindings()
        self.update()
    }
    
    // MARK: - Actions
    
    @IBAction func  onLike()
    {
        guard self.isLikesAvailable else { return }
        guard let input = self.input, let photo = self.photo else { return }
        
        var events: [FeedAction] = [.view(viewCount: 1, viewTimeSec: 1)]
        if photo.isLiked {
            events.append(.unlike)
        } else {
            events.append(.like(likeCount: 1))
        }
        
        try? self.photo?.realm?.write({ [weak self] in
            self?.photo?.isLiked = !photo.isLiked
        })
        
        input.actionsManager.add(events,
                                      profile: input.profile,
                                      photo: photo,
                                      source: .newFaces)
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
}
