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
    var input: NewFaceProfileVMInput!
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

    fileprivate let chatSources: [SourceFeedType] = [
        .hellos,
        .matches,
        .inbox,
        .sent
    ]
    
    @IBOutlet fileprivate weak var photoView: UIImageView!
    @IBOutlet fileprivate weak var animationLikeView: UIImageView!
    @IBOutlet fileprivate weak var photoIdLabel: UILabel!
    
    deinit
    {
        if let url = self.photo?.filepath().url() { ImageService.shared.cancel(url) }
        
        NotificationCenter.default.removeObserver(self)
    }
    
    static func create() -> NewFacePhotoViewController
    {
        let storyboard = Storyboards.newFaces()
        return storyboard.instantiateViewController(withIdentifier: "new_face_photo") as! NewFacePhotoViewController
    }
    
    override func viewDidLoad()
    {
        assert( self.input != nil )
        
        super.viewDidLoad()

        self.updateBindings()
        self.update()
        
        NotificationCenter.default.addObserver(self, selector: #selector(onAppBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAppBecomeInactive), name: UIApplication.willResignActiveNotification, object: nil)
        
        #if STAGE
        self.photoIdLabel.text = "Photo: " + String(self.photo?.id.suffix(4) ?? "")
        self.photoIdLabel.isHidden = false
        #endif
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        guard self.input?.profile.isInvalidated == false else { return }
        guard let actionProfile = self.input?.profile.actionInstance(), let origPhotoId = self.photo?.id else { return }
        guard let actionPhoto = actionProfile.orderedPhotos().filter({ $0.id == origPhotoId }).first else { return }
        
        self.actionProfile = actionProfile
        self.actionPhoto = actionPhoto
        
        self.input?.actionsManager.startViewAction(
            actionProfile,
            photo: actionPhoto
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
    
    @IBAction func  onTap(_ recognizer: UIGestureRecognizer)
    {
        UIManager.shared.feedsFabShouldBeHidden.accept(true)
        
        guard self.input.profileManager.isPhotosAdded else {
            self.showAddPhotoAlert()
            
            return
        }
        
        if self.chatSources.contains(self.input.sourceType) {
            self.onChatBlock?()
            
            return
        }

        let tapPoint = recognizer.location(in: self.view)
        
        guard let input = self.input, let photoId = self.photo?.id else { return }
        
        guard let actionProfile = input.profile.actionInstance() else { return }
        guard let actionPhoto = actionProfile.orderedPhotos().filter({ $0.id == photoId }).first else { return }
        
        input.actionsManager.likeActionProtected(
            actionProfile,
            photo: actionPhoto,
            source: input.sourceType
        )
        
        switch input.sourceType {
            
        case .whoLikedMe:
            if let lmmProfile = input.profile as? LMMProfile {
                self.input.transitionManager.move(lmmProfile, to: .matches)
                GlobalAnimationManager.shared.playFlyUpIconAnimation(UIImage(named: "feed_effect_match")!, from: self.view, point: tapPoint, scaleFactor: 0.75)
            }
            
        case .newFaces:
            self.input.transitionManager.removeAsLiked(input.profile)
            GlobalAnimationManager.shared.playFlyUpIconAnimation(UIImage(named: "feed_effect_like")!, from: self.view, point: tapPoint)
            break
            
        default: return
        }
    }
        
    // MARK: -
    
    fileprivate func update()
    {
        guard let photoView = self.photoView else { return }
        guard let url = self.photo?.filepath().url() else {
            photoView.image = nil
            
            return
        }
        
        ImageService.shared.load(url, to: photoView)
    }
    
    fileprivate func updateBindings()
    {
        self.disposeBag = DisposeBag()
    }
 
    @objc fileprivate func onAppBecomeActive()
    {
        guard self.isVisible else { return }
        guard let profile = self.input?.profile.actionInstance(), let photo = self.photo?.actionInstance() else { return }
        
        self.input?.actionsManager.startViewAction(
            profile,
            photo: photo
        )
    }
    
    @objc fileprivate func onAppBecomeInactive()
    {
        guard self.isVisible else { return }
        
        self.stopViewAction()
    }
    
    fileprivate func showAddPhotoAlert()
    {
        let alertVC = UIAlertController(title: nil, message: "feed_explore_dialog_no_user_photo_description".localized(), preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "button_add_photo".localized(), style: .default, handler: { [weak self] _ in
            self?.input.navigationManager.mainItem.accept(.profileAndPick)
        }))
        alertVC.addAction(UIAlertAction(title: "button_later".localized(), style: .cancel, handler: nil))
        
        self.present(alertVC, animated: true, completion: nil)
    }
}

extension LMMType
{
    func sourceType() -> SourceFeedType
    {
        switch self {
        case .likesYou: return .whoLikedMe
        case .matches: return .matches
        case .hellos: return .hellos
        case .inbox: return .inbox
        case .sent: return .sent
        }
    }
}
