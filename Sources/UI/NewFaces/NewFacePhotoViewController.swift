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
    
    var onChatBlock: ( () -> () )?
    
    fileprivate var actionProfile: ActionProfile?
    fileprivate var actionPhoto: ActionPhoto?
    fileprivate var disposeBag: DisposeBag = DisposeBag()
    
    fileprivate weak var activeAppearAnimator: UIViewPropertyAnimator?
    fileprivate weak var activeDisappearAnimator: UIViewPropertyAnimator?
    
    @IBOutlet fileprivate weak var photoView: UIImageView!
    @IBOutlet weak var likeBtn: UIButton!
    @IBOutlet fileprivate weak var animationLikeView: UIImageView!
    
    static func create() -> NewFacePhotoViewController
    {
        let storyboard = Storyboards.newFaces()
        return storyboard.instantiateViewController(withIdentifier: "new_face_photo") as! NewFacePhotoViewController
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.likeBtn.isHidden = !self.isLikesAvailable()
        
        self.updateBindings()
        self.update()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        guard let profile = self.input?.profile.actionInstance(), let photo = self.photo?.actionInstance() else { return }
        
        self.actionProfile = profile
        self.actionPhoto = photo
        
        self.input?.actionsManager.startViewAction(
            profile,
            photo: photo
        )
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        self.stopViewAction()
    }
    
    func stopViewAction()
    {
        guard
            let profile = self.actionProfile,
            let photo = self.actionPhoto,
            let type = self.input?.sourceType
            else { return }
        
        self.input?.actionsManager.stopViewAction(profile, photo: photo, sourceType: type)
    }
    
    // MARK: - Actions
    
    @IBAction func  onLike()
    {
        guard self.isLikesAvailable() else { return }
        guard let input = self.input, let photo = self.photo else { return }
        
        if photo.isLiked {
            input.actionsManager.unlikeActionProtected(
                input.profile.actionInstance(),
                photo: photo.actionInstance(),
                source: input.sourceType
            )
        } else {
            self.playLikeAnimation()
            
            input.actionsManager.likeActionProtected(
                input.profile.actionInstance(),
                photo: photo.actionInstance(),
                source: input.sourceType
            )
        }
        
        try? self.photo?.realm?.write({ [weak self] in
            self?.photo?.isLiked = !photo.isLiked
        })
    }
    
    @IBAction func  onTap()
    {
        guard self.isLikesAvailable() else {
            self.onChatBlock?()
            
            return
        }
        
        guard let input = self.input, let photo = self.photo else { return }
        
        self.playLikeAnimation()
        
        input.actionsManager.likeActionProtected(
            input.profile.actionInstance(),
            photo: photo.actionInstance(),
            source: input.sourceType
            
        )
        
        self.photo?.write({ obj in
            (obj as? Photo)?.isLiked = true
        })
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
        self.disposeBag = DisposeBag()
        
        self.photo?.rx.observe(Photo.self, "isLiked").subscribe(onNext: { [weak self] _ in
            let imgName = self?.photo?.isLiked == true ? "feed_like_selected" : "feed_like"
            self?.likeBtn.setImage(UIImage(named: imgName), for: .normal)
        }).disposed(by: self.disposeBag)
        
        UIManager.shared.blockModeEnabled.asObservable().subscribe(onNext: { [weak self] state in
            let alpha: CGFloat = state ? 0.0 : 1.0
            
            UIViewPropertyAnimator.init(duration: 0.1, curve: .linear, animations: {
                self?.likeBtn.alpha = alpha
            }).startAnimation()
        }).disposed(by: self.disposeBag)
        
        UIManager.shared.chatModeEnabled.asObservable().subscribe(onNext: { [weak self] state in
            let alpha: CGFloat = state ? 0.0 : 1.0
            
            UIViewPropertyAnimator.init(duration: 0.1, curve: .linear, animations: {
                self?.likeBtn.alpha = alpha
            }).startAnimation()
        }).disposed(by: self.disposeBag)
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
    
    fileprivate func playLikeAnimation()
    {
        if self.activeAppearAnimator?.isRunning == true {
            self.activeAppearAnimator?.stopAnimation(true)
            self.activeAppearAnimator?.finishAnimation(at: .start)
        }
        
        if self.activeDisappearAnimator?.isRunning == true {
            self.activeDisappearAnimator?.stopAnimation(true)
            self.activeDisappearAnimator?.finishAnimation(at: .end)
        }
        
        let duration = 0.4
        let appearAnimator = UIViewPropertyAnimator(duration: duration / 2.0, curve: .easeIn) {
            self.animationLikeView.alpha = 1.0
            self.animationLikeView.transform = .init(scaleX: 3.0, y: 3.0)
            self.likeBtn.transform = .init(scaleX: 1.2, y: 1.2)
        }
        
        let disappearAnimator = UIViewPropertyAnimator(duration: duration / 2.0, curve: .easeIn) {
            self.animationLikeView.alpha = 0.0
            self.animationLikeView.transform = .identity
            self.likeBtn.transform = .identity
        }
        
        self.activeAppearAnimator = appearAnimator
        self.activeDisappearAnimator = disappearAnimator
        
        appearAnimator.addCompletion { _ in
            disappearAnimator.startAnimation()
        }
        
        appearAnimator.startAnimation()
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
