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

fileprivate var autoLikePhotoId: String? = nil

class NewFacePhotoViewController: UIViewController
{
    var input: NewFaceProfileVMInput!
    var photo: Photo?
    {
        didSet {
            self.update()
        }
    }
    
    var shouldPrioritizeDoubleTap: Bool = false
    {
        didSet {
            if self.shouldPrioritizeDoubleTap {
                self.tapRecognizer.require(toFail: self.doubleTapRecognizer)
            } else {
                self.doubleTapRecognizer.require(toFail: self.tapRecognizer)
            }
        }
    }
    
    var onChatBlock: (() -> ())?
    var onBottomOptionsBlock: (() -> ())?
    var onLikeBlock: (() -> ())?
    
    fileprivate var actionProfile: ActionProfile?
    fileprivate var actionPhoto: ActionPhoto?
    fileprivate var disposeBag: DisposeBag = DisposeBag()
    
    fileprivate weak var activeAppearAnimator: UIViewPropertyAnimator?
    fileprivate weak var activeDisappearAnimator: UIViewPropertyAnimator?

    fileprivate let chatSources: [SourceFeedType] = [
        .messages,        
        .inbox,
        .sent
    ]
    
    @IBOutlet fileprivate weak var photoView: UIImageView!
    @IBOutlet fileprivate weak var animationLikeView: UIImageView!
    @IBOutlet fileprivate weak var photoIdLabel: UILabel!
    @IBOutlet fileprivate weak var doubleTapRecognizer: UITapGestureRecognizer!
    @IBOutlet fileprivate weak var tapRecognizer: UITapGestureRecognizer!
    
    deinit
    {
        if self.photo?.isInvalidated == false, let url = self.photo?.filepath().url() { ImageService.shared.cancel(url) }
        
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
        
        switch self.input.sourceType {
        case .newFaces, .whoLikedMe: self.doubleTapRecognizer.numberOfTapsRequired = 2
        default: self.doubleTapRecognizer.numberOfTapsRequired = 1
        }
        
        self.tapRecognizer.delegate = self
        
//        #if STAGE
//        self.photoIdLabel.text = "Photo: " + String(self.photo?.id.prefix(4) ?? "")
//        self.photoIdLabel.isHidden = false
//        #endif
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        self.update()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        guard self.input?.profile.isInvalidated == false else { return }
        guard let createdActionProfile = self.input?.profile.actionInstance(), let origPhotoId = self.photo?.id else { return }
        guard let createdActionPhoto = createdActionProfile.orderedPhotos().filter({ $0.id == origPhotoId }).first else { return }
        
        self.actionProfile = createdActionProfile
        self.actionPhoto = createdActionPhoto
        
        self.input?.actionsManager.startViewAction(
            createdActionProfile,
            photo: createdActionPhoto,
            sourceType: self.input?.sourceType ?? .whoLikedMe
        )
        
        if autoLikePhotoId == createdActionPhoto.id, self.input.profileManager.photos.value.count > 0 {
            autoLikePhotoId = nil
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.handleTap(self.view.center)
            }
        }
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
    
    func handleTap(_ at: CGPoint)
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
                self.onLikeBlock?()
                GlobalAnimationManager.shared.playFlyUpIconAnimation(UIImage(named: "feed_effect_match")!, from: self.view, point: at, scaleFactor: 0.75)
                self.input.transitionManager.move(lmmProfile, to: .messages)
            }
            
        case .newFaces:
            self.onLikeBlock?()
            GlobalAnimationManager.shared.playFlyUpIconAnimation(UIImage(named: "feed_effect_like")!, from: self.view, point: at)
            self.input.transitionManager.removeAsLiked(input.profile)
            break
            
        default: return
        }
    }
    
    // MARK: - Actions
    
    @IBAction func  onDoubleTap(_ recognizer: UIGestureRecognizer)
    {
        let tapPoint = recognizer.location(in: self.view)
        self.handleTap(tapPoint)
    }
    
    @IBAction func onTap(_ recognizer: UIGestureRecognizer)
    {
        self.onBottomOptionsBlock?()
    }
    
    fileprivate func checkBottomArea(_ point: CGPoint) -> Bool
    {
        return point.y > self.view.bounds.height - 80.0
    }
    
    // MARK: -
    
    fileprivate func update()
    {
        guard let photoView = self.photoView else { return }
        guard let url = self.photo?.filepath().url(), let thumbnailUrl = self.photo?.thumbnailFilepath().url() else {
            photoView.image = nil
            
            return
        }
        
        ImageService.shared.load(url, thumbnailUrl: thumbnailUrl, to: photoView)
    }
    
    fileprivate func updateBindings()
    {
        self.disposeBag = DisposeBag()
    }
 
    @objc fileprivate func onAppBecomeActive()
    {
        if let url = self.photo?.filepath().url(), let thumbnailUrl = self.photo?.thumbnailFilepath().url() {
            ImageService.shared.cancel(url)
            ImageService.shared.cancel(thumbnailUrl)            
        }
        
        self.update()
        
        guard self.isVisible else { return }
        guard let profile = self.input?.profile.actionInstance(), let photo = self.photo?.actionInstance() else { return }
        
        self.input?.actionsManager.startViewAction(
            profile,
            photo: photo,
            sourceType: self.input.sourceType
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
            autoLikePhotoId = self?.photo?.id
            UIManager.shared.discoverAddPhotoModeEnabled.accept(true)
            self?.input.navigationManager.mainItem.accept(.profileAndPick)
        }))
        alertVC.addAction(UIAlertAction(title: "button_later".localized(), style: .cancel, handler: nil))
        
        self.present(alertVC, animated: true, completion: nil)
    }
}

extension NewFacePhotoViewController: UIGestureRecognizerDelegate
{
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool
    {
        let point = touch.location(in: self.view)
        return self.checkBottomArea(point)
    }
}

extension LMMType
{
    func sourceType() -> SourceFeedType
    {
        switch self {
        case .likesYou: return .whoLikedMe
        case .messages: return .messages
        case .inbox: return .inbox
        case .sent: return .sent
        }
    }
}
