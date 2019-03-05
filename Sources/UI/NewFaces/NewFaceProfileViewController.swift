//
//  NewFaceProfileViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 10/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Nuke

class NewFaceProfileViewController: UIViewController
{
    var input: NewFaceProfileVMInput!
    
    var onBlockOptionsWillShow: (() -> ())?
    
    var bottomVisibleBorderDistance: CGFloat = 0.0
    {
        didSet {
            self.handleBottomBorderDistanceChange(self.bottomVisibleBorderDistance)
        }
    }
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    fileprivate var viewModel: NewFaceProfileViewModel?
    fileprivate var pagesVC: UIPageViewController?
    fileprivate var photosVCs: [NewFacePhotoViewController] = []
    fileprivate var currentIndex: Int = 0
    fileprivate let preheater = ImagePreheater()
    
    @IBOutlet fileprivate weak var pageControl: UIPageControl!
    @IBOutlet fileprivate weak var optionsBtn: UIButton!
    
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
        
        self.setupBindings()
        // TODO: Move all logic inside view model
        
        guard !self.input.profile.isInvalidated else { return }
        
        self.pageControl.numberOfPages = self.input.profile.photos.count
        self.photosVCs = self.input.profile.orderedPhotos().map({ photo in
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
    
    func preheatSecondPhoto()
    {
        guard self.input.profile.photos.count >= 2 else { return }
        
        self.preheater.startPreheating(with: [self.input.profile.orderedPhotos()[1].filepath().url()])
    }
    
    // MARK: - Actions
        
    @IBAction func onBlock()
    {
        self.input.actionsManager.checkConnectionState()
        
        self.showBlockOptions()
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.viewModel = NewFaceProfileViewModel(self.input)
        
        UIManager.shared.blockModeEnabled.asObservable().subscribe(onNext: { [weak self] state in
            let alpha: CGFloat = state ? 0.0 : 1.0
            
            UIViewPropertyAnimator.init(duration: 0.1, curve: .linear, animations: {
                self?.pageControl.alpha = alpha
                self?.optionsBtn.alpha = alpha
            }).startAnimation()
        }).disposed(by: self.disposeBag)
        
        UIManager.shared.chatModeEnabled.asObservable().subscribe(onNext: { [weak self] state in
            let alpha: CGFloat = state ? 0.0 : 1.0
            
            UIViewPropertyAnimator.init(duration: 0.1, curve: .linear, animations: {
                self?.pageControl.alpha = alpha
            }).startAnimation()
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func showBlockOptions()
    {
        UIManager.shared.blockModeEnabled.accept(true)
        onBlockOptionsWillShow?()
        
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertVC.addAction(UIAlertAction(title: "BLOCK_OPTION".localized(), style: .default, handler: { _ in
            UIManager.shared.blockModeEnabled.accept(false)
            self.viewModel?.block(at: self.currentIndex, reason: BlockReason(rawValue: 0)!)
        }))
        alertVC.addAction(UIAlertAction(title: "BLOCK_REPORT_OPTION".localized(), style: .default, handler: { _ in
            self.showBlockReasonOptions()
        }))
        alertVC.addAction(UIAlertAction(title: "button_cancel".localized(), style: .cancel, handler: { _ in
            UIManager.shared.blockModeEnabled.accept(false)
        }))
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
    fileprivate func showBlockReasonOptions()
    {
        onBlockOptionsWillShow?()
        
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        for reason in BlockReason.reportResons() {
            alertVC.addAction(UIAlertAction(title: reason.title(), style: .default) { _ in
                UIManager.shared.blockModeEnabled.accept(false)
                self.viewModel?.block(at: self.currentIndex, reason: reason)
            })
        }
        
        alertVC.addAction(UIAlertAction(title: "button_cancel".localized(), style: .cancel, handler: { _ in
            UIManager.shared.blockModeEnabled.accept(false)
        }))
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
    fileprivate func handleBottomBorderDistanceChange(_ value: CGFloat)
    {
        self.pageControl.alpha = self.discreetOpacity(for: self.bottomOpacityFor(self.pageControl.frame, offset: value) ?? 1.0)
        self.optionsBtn.alpha = self.discreetOpacity(for: self.bottomOpacityFor(self.optionsBtn.frame, offset: value) ?? 1.0)
        
        self.photosVCs.forEach { vc in
            guard let likeBtn = vc.likeBtn else { return }
            
            likeBtn.alpha = self.discreetOpacity(for: self.bottomOpacityFor(likeBtn.frame, offset: value) ?? 1.0)
        }
    }
    
    fileprivate func bottomOpacityFor(_ frame: CGRect, offset: CGFloat) -> CGFloat?
    {
        let inset = abs(offset)
        let y = self.view.bounds.height - frame.maxY
        
        guard offset < 0.0 else { return nil }
        guard inset > frame.height else { return nil }
        
        let t = 1.0 - (inset - y) / (frame.height / 2.0)
        
        guard t > 0.0 else { return 0.0 }
        
        return pow(t, 2.0)
    }
    
    fileprivate func discreetOpacity(for opacity: CGFloat) -> CGFloat
    {
        return opacity < 0.5 ? 0.0 : 1.0
    }
}

extension NewFaceProfileViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource
{
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController])
    {
        guard let urls = self.viewModel?.input.profile.orderedPhotos().map({ $0.filepath().url() }) else { return }
        
        self.preheater.startPreheating(with: urls)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController?
    {
        guard let vc = viewController as? NewFacePhotoViewController else { return nil }
        guard let index = self.photosVCs.index(of: vc) else { return nil }
        guard index > 0 else { return nil }
        
        return self.photosVCs[index-1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController?
    {
        guard let vc = viewController as? NewFacePhotoViewController else { return nil }
        guard let index = self.photosVCs.index(of: vc) else { return nil}
        guard index < (self.photosVCs.count - 1) else { return nil }
        
        return self.photosVCs[index+1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool)
    {
        guard let photoVC = pageViewController.viewControllers?.first as? NewFacePhotoViewController else { return }
  
        guard finished, completed else { return }
        guard let index = self.photosVCs.index(of: photoVC) else { return }
        
        self.currentIndex = index
        self.pageControl.currentPage = index
    }
}
