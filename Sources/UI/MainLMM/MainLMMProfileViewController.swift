//
//  MainLMMProfileViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 15/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class MainLMMProfileViewController: UIViewController
{
    var input: MainLMMProfileVMInput!
    
    var onSelected: ( ()->() )?
    
    fileprivate var pagesVC: UIPageViewController?
    fileprivate var photosVCs: [UIViewController] = []
    fileprivate var currentIndex: Int = 0
    
    @IBOutlet fileprivate weak var pageControl: UIPageControl!
    @IBOutlet fileprivate weak var messageBtn: UIButton!
    @IBOutlet fileprivate weak var chatContainerView: ContainerView!
    @IBOutlet fileprivate weak var chatConstraint: NSLayoutConstraint!
    
    static func create(_ profile: LMMProfile, feedType: LMMType, actionsManager: ActionsManager) -> MainLMMProfileViewController
    {
        let storyboard = Storyboards.mainLMM()
        let vc = storyboard.instantiateViewController(withIdentifier: "lmm_profile") as! MainLMMProfileViewController
        vc.input = MainLMMProfileVMInput(profile: profile, feedType: feedType, actionsManager: actionsManager)
        
        return vc
    }
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        let messageImageName = self.input.profile.messages.count == 0 ? "feed_messages_empty" : "feed_messages"
        self.messageBtn.setImage(UIImage(named: messageImageName), for: .normal)
        self.messageBtn.isHidden = self.input.feedType == .likesYou
        
        self.pageControl.numberOfPages = self.input.profile.photos.count
        self.photosVCs = self.input.profile.photos.map({ photo in
            let vc = NewFacePhotoViewController.create()
            vc.photo = photo
            vc.input = NewFaceProfileVMInput(profile: self.input.profile, actionsManager: self.input.actionsManager, sourceType: self.input.feedType.sourceType())
            
            return vc
        })
        
        guard let vc = self.photosVCs.first else { return }
        self.pagesVC?.setViewControllers([vc], direction: .forward, animated: false, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "embed_pages" {
            self.pagesVC = segue.destination as? UIPageViewController
            self.pagesVC?.delegate = self
            self.pagesVC?.dataSource = self
        }
    }
    
    // MARK: - Actions
    
    @IBAction func onChatSelected()
    {
        self.showChat()
    }
    
    // MARK: -
    
    fileprivate func showChat()
    {
        let vc = ChatViewController.create()
        vc.input = ChatVMInput(profile: self.input.profile, actionsManager: self.input.actionsManager, onClose: { [weak self] in
            self?.hideChat()
        })
        
        self.chatContainerView.embed(vc, to: self)
        self.chatConstraint.constant = -self.view.bounds.height
        
        self.onSelected?()
        UIViewPropertyAnimator(duration: 0.35, curve: .easeOut, animations: {
            self.view.layoutSubviews()
        }).startAnimation()
    }
    
    fileprivate func hideChat()
    {
        self.chatConstraint.constant = 0.0
        
        let animator = UIViewPropertyAnimator(duration: 0.35, curve: .easeOut, animations: {
            self.view.layoutSubviews()
        })
        animator.addCompletion({ _ in
            self.chatContainerView.remove()
        })
        animator.startAnimation()
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
        
        self.currentIndex = index
        self.pageControl.currentPage = index
    }
}
