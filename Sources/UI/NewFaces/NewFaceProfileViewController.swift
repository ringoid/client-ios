//
//  NewFaceProfileViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 10/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class NewFaceProfileViewController: UIViewController
{
    var input: NewFaceProfileVMInput!
    
    fileprivate var viewModel: NewFaceProfileViewModel?
    fileprivate var pagesVC: UIPageViewController?
    fileprivate var photosVCs: [UIViewController] = []
    fileprivate var currentIndex: Int = 0
    
    @IBOutlet fileprivate weak var pageControl: UIPageControl!
    
    static func create(_ profile: NewFaceProfile, actionsManager: ActionsManager) -> NewFaceProfileViewController
    {
        let storyboard = Storyboards.newFaces()
        
        let vc = storyboard.instantiateViewController(withIdentifier: "new_face_profile") as! NewFaceProfileViewController
        vc.input = NewFaceProfileVMInput(profile: profile.actionInstance(), actionsManager: actionsManager, sourceType: .newFaces)
        
        return vc
    }
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        self.viewModel = NewFaceProfileViewModel(self.input)
        
        // TODO: Move all logic inside view model
        
        guard !self.input.profile.isInvalidated else { return }
        
        self.pageControl.numberOfPages = self.input.profile.photos.count
        self.photosVCs = self.input.profile.photos.map({ photo in
            let vc = NewFacePhotoViewController.create()
            vc.input = self.input
            vc.photo = photo
            
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
    
    @IBAction func onLike()
    {
        self.viewModel?.like(at: self.currentIndex)
    }
    
    @IBAction func onBlock()
    {
        self.showBlockOptions()
    }
    
    // MARK: -
    
    fileprivate func showBlockOptions()
    {
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertVC.addAction(UIAlertAction(title: "BLOCK_OPTION".localized(), style: .default, handler: { _ in
            self.viewModel?.block(at: self.currentIndex, reason: BlockReason(rawValue: 0)!)
        }))
        alertVC.addAction(UIAlertAction(title: "BLOCK_REPORT_OPTION".localized(), style: .default, handler: { _ in
            self.showBlockReasonOptions()
        }))
        alertVC.addAction(UIAlertAction(title: "CANCEL_OPTION".localized(), style: .cancel, handler: nil))
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
    fileprivate func showBlockReasonOptions()
    {
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        for reason in BlockReason.reportResons() {
            alertVC.addAction(UIAlertAction(title: reason.title(), style: .default) { _ in
                self.viewModel?.block(at: self.currentIndex, reason: reason)
            })
        }
        
        alertVC.addAction(UIAlertAction(title: "CANCEL_OPTION".localized(), style: .cancel, handler: nil))
        
        self.present(alertVC, animated: true, completion: nil)
    }
}

extension NewFaceProfileViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource
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
