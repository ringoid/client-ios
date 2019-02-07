//
//  MainLMMProfileViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 15/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class MainLMMProfileViewController: UIViewController
{
    var input: MainLMMProfileVMInput!
    
    var currentIndex: BehaviorRelay<Int> = BehaviorRelay<Int>(value: 0)
    var onChatShow: ((LMMProfile, Photo, MainLMMProfileViewController?) -> ())?
    var onChatHide: ((LMMProfile, Photo, MainLMMProfileViewController?) -> ())?
    var onBlockOptionsWillShow: (() -> ())?
    
    fileprivate var viewModel: MainLMMProfileViewModel?
    fileprivate var pagesVC: UIPageViewController?
    fileprivate var photosVCs: [UIViewController] = []
    
    @IBOutlet fileprivate weak var pageControl: UIPageControl!
    @IBOutlet fileprivate weak var messageBtn: UIButton!
    
    static func create(_ profile: LMMProfile, feedType: LMMType, actionsManager: ActionsManager, initialIndex: Int) -> MainLMMProfileViewController
    {
        let storyboard = Storyboards.mainLMM()
        let vc = storyboard.instantiateViewController(withIdentifier: "lmm_profile") as! MainLMMProfileViewController
        vc.input = MainLMMProfileVMInput(profile: profile, feedType: feedType, actionsManager: actionsManager, initialIndex: initialIndex)
        
        return vc
    }
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        // TODO: Move logic inside view model
        self.viewModel = MainLMMProfileViewModel(self.input)
        
        guard !self.input.profile.isInvalidated else { return }
        
        self.messageBtn.setImage(UIImage(named: self.input.profile.state.iconName()), for: .normal)
        self.messageBtn.isHidden = self.input.feedType == .likesYou
        
        self.pageControl.numberOfPages = self.input.profile.photos.count
        self.photosVCs = self.input.profile.photos.map({ photo in
            let vc = NewFacePhotoViewController.create()
            vc.photo = photo
            vc.input = NewFaceProfileVMInput(profile: self.input.profile.actionInstance(), actionsManager: self.input.actionsManager, sourceType: self.input.feedType.sourceType())
            
            return vc
        })
        
        let index = self.input.initialIndex
        guard index < self.photosVCs.count else { return }
        
        let vc = self.photosVCs[index]
        self.pagesVC?.setViewControllers([vc], direction: .forward, animated: false, completion: nil)
        self.pageControl.currentPage = index
        self.currentIndex.accept(index)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "embed_pages" {
            self.pagesVC = segue.destination as? UIPageViewController
            self.pagesVC?.delegate = self
            self.pagesVC?.dataSource = self
        }
    }
    
    func showControls()
    {
        self.messageBtn.setImage(UIImage(named: self.input.profile.state.iconName()), for: .normal)
        self.pageControl.isHidden = false
        self.messageBtn.isHidden = false
    }
    
    func hideControls()
    {
        self.pageControl.isHidden = true
        self.messageBtn.isHidden = true
    }
    
    // MARK: - Actions
    
    @IBAction func onChatSelected()
    {
        weak var weakSelf = self
        let profile = self.input.profile
        self.onChatShow?(profile, profile.photos[self.currentIndex.value], weakSelf)
    }
    
    @IBAction func onLike()
    {
        self.viewModel?.like(at: self.currentIndex.value)
    }
    
    @IBAction func onBlock()
    {
        weak var weakSelf = self
        let profile = self.input.profile
        self.onChatHide?(profile, profile.photos[self.currentIndex.value], weakSelf)
        self.showBlockOptions()
    }
    
    // MARK: -
    
    fileprivate func showBlockOptions()
    {
        UIManager.shared.mainControlsVisible.accept(false)
        onBlockOptionsWillShow?()
        
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertVC.addAction(UIAlertAction(title: "BLOCK_OPTION".localized(), style: .default, handler: { _ in
            UIManager.shared.mainControlsVisible.accept(true)
            self.viewModel?.block(at: self.currentIndex.value, reason: BlockReason(rawValue: 0)!)
        }))
        alertVC.addAction(UIAlertAction(title: "BLOCK_REPORT_OPTION".localized(), style: .default, handler: { _ in
            self.showBlockReasonOptions()
        }))
        alertVC.addAction(UIAlertAction(title: "CANCEL_OPTION".localized(), style: .cancel, handler: { _ in
            UIManager.shared.mainControlsVisible.accept(true)
        }))
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
    fileprivate func showBlockReasonOptions()
    {
        onBlockOptionsWillShow?()
        
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        for reason in BlockReason.reportResons() {            
            alertVC.addAction(UIAlertAction(title: reason.title(), style: .default) { _ in
                UIManager.shared.mainControlsVisible.accept(true)
                self.viewModel?.block(at: self.currentIndex.value, reason: reason)
            })
        }
        
        alertVC.addAction(UIAlertAction(title: "CANCEL_OPTION".localized(), style: .cancel, handler: { _ in
            UIManager.shared.mainControlsVisible.accept(true)
        }))
        
        self.present(alertVC, animated: true, completion: nil)
    }
}

extension MainLMMProfileViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource
{
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {}
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController?
    {
        guard let index = self.photosVCs.index(of: viewController) else { return nil }
        guard index > 0 else { return nil }
        
        return self.photosVCs[index-1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController?
    {
        guard let index = self.photosVCs.index(of: viewController) else { return nil}
        guard index < (self.photosVCs.count - 1) else { return nil }
        
        return self.photosVCs[index+1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool)
    {
        guard let photoVC = pageViewController.viewControllers?.first else { return }
        
        guard finished, completed else { return }
        guard let index = self.photosVCs.index(of: photoVC) else { return }
        
        self.currentIndex.accept(index)
        self.pageControl.currentPage = index
    }
}

extension MessagingState
{
    func iconName() -> String
    {
        switch self {
        case .empty: return "feed_messages_empty"
        case .incomingOnly: return "feed_messages"
        case .chatRead: return "feed_chat_read"
        case .chatUnread: return "feed_chat_unread"
        }
    }
}
