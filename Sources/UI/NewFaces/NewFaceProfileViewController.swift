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
    
    var onBlockOptionsWillShow: ((Int) -> ())?
    var onBlockOptionsWillHide: (() -> ())?
    
    let currentIndex: BehaviorRelay<Int> = BehaviorRelay<Int>(value: 0)
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
    fileprivate let preheater = ImagePreheater(destination: .diskCache)
    fileprivate var preheaterTimer: Timer?
    
    @IBOutlet fileprivate weak var optionsBtn: UIButton!
    @IBOutlet fileprivate weak var profileIdLabel: UILabel!
    
    static func create(_ profile: NewFaceProfile,
                       initialIndex: Int,
                       actionsManager: ActionsManager,
                       profileManager: UserProfileManager,
                       navigationManager: NavigationManager,
                       scenarioManager: AnalyticsScenarioManager,
                       transitionManager: TransitionManager
        ) -> NewFaceProfileViewController
    {
        let storyboard = Storyboards.newFaces()
        
        let vc = storyboard.instantiateViewController(withIdentifier: "new_face_profile") as! NewFaceProfileViewController
        vc.input = NewFaceProfileVMInput(
            profile: profile,
            sourceType: .newFaces,
            actionsManager: actionsManager,
            profileManager: profileManager,
            navigationManager: navigationManager,
            scenarioManager: scenarioManager,
            transitionManager: transitionManager
        )
        vc.currentIndex.accept(initialIndex)
        
        return vc
    }
    
    deinit {
        self.preheaterTimer?.invalidate()
        self.preheaterTimer = nil
        
        self.preheater.stopPreheating()
    }
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        self.setupBindings()
        self.setupPreheaterTimer()
        // TODO: Move all logic inside view model
        
        guard !self.input.profile.isInvalidated else { return }
        
        self.photosVCs = self.input.profile.orderedPhotos().map({ photo in
            let vc = NewFacePhotoViewController.create()
            vc.input = self.input
            vc.photo = photo
            
            return vc
        })
        
        let vc = self.photosVCs[self.currentIndex.value]
        self.pagesVC?.setViewControllers([vc], direction: .forward, animated: false, completion: nil)
        
        #if STAGE
        self.profileIdLabel.text = "Profile: " +  String(self.input.profile.id.suffix(4))
        self.profileIdLabel.isHidden = false
        #endif
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
        guard !self.input.profile.isInvalidated else { return }
        guard self.input.profile.photos.count >= 2 else { return }
        guard let url = self.input.profile.orderedPhotos()[1].filepath().url() else { return }
        
        self.preheater.startPreheating(with: [url])
    }
    
    // MARK: - Actions
        
    @IBAction func onBlock()
    {
        guard self.input.actionsManager.checkConnectionState() else { return }
        
        self.showBlockOptions()
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.viewModel = NewFaceProfileViewModel(self.input)
        
        UIManager.shared.blockModeEnabled.asObservable().subscribe(onNext: { [weak self] state in
            let alpha: CGFloat = state ? 0.0 : 1.0
            
            UIViewPropertyAnimator.init(duration: 0.1, curve: .linear, animations: {
                self?.optionsBtn.alpha = alpha
            }).startAnimation()
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func showBlockOptions()
    {
        UIManager.shared.blockModeEnabled.accept(true)
        self.onBlockOptionsWillShow?(self.currentIndex.value)
        
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertVC.addAction(UIAlertAction(title: "block_profile_button_block".localized(), style: .default, handler: { _ in
            self.onBlockOptionsWillHide?()
            UIManager.shared.blockModeEnabled.accept(false)
            self.viewModel?.block(at: self.currentIndex.value, reason: BlockReason(rawValue: 0)!)
            AnalyticsManager.shared.send(.blocked(0, SourceFeedType.newFaces.rawValue, false))
        }))
        alertVC.addAction(UIAlertAction(title: "block_profile_button_report".localized(), style: .default, handler: { _ in
            self.showBlockReasonOptions()
        }))
        alertVC.addAction(UIAlertAction(title: "button_cancel".localized(), style: .cancel, handler: { _ in
            self.onBlockOptionsWillHide?()
            UIManager.shared.blockModeEnabled.accept(false)
        }))
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
    fileprivate func showBlockReasonOptions()
    {
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        for reason in BlockReason.reportResons() {
            alertVC.addAction(UIAlertAction(title: reason.title(), style: .default) { _ in
                self.showBlockReasonConfirmation(reason)
            })
        }
        
        alertVC.addAction(UIAlertAction(title: "button_cancel".localized(), style: .cancel, handler: { _ in
            self.onBlockOptionsWillHide?()
            UIManager.shared.blockModeEnabled.accept(false)
        }))
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
    fileprivate func showBlockReasonConfirmation(_ reason: BlockReason)
    {
        let alertVC = UIAlertController(
            title: nil,
            message: "block_profile_alert_title".localized() + " " + reason.title(),
            preferredStyle: .alert
        )
        alertVC.addAction(UIAlertAction(title: "block_profile_button_report".localized(), style: .default, handler: { _ in
            self.onBlockOptionsWillHide?()
            UIManager.shared.blockModeEnabled.accept(false)
            self.viewModel?.block(at: self.currentIndex.value, reason: reason)
            AnalyticsManager.shared.send(.blocked(reason.rawValue, SourceFeedType.newFaces.rawValue, false))
        }))
        alertVC.addAction(UIAlertAction(title: "button_cancel".localized(), style: .cancel, handler: { _ in
            self.onBlockOptionsWillHide?()
            UIManager.shared.blockModeEnabled.accept(false)
        }))
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
    fileprivate func handleBottomBorderDistanceChange(_ value: CGFloat)
    {
        self.optionsBtn.alpha = self.discreetOpacity(for: self.bottomOpacityFor(self.optionsBtn.frame, offset: value) ?? 1.0)
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
    
    fileprivate func setupPreheaterTimer()
    {
        self.preheaterTimer?.invalidate()
        self.preheaterTimer = nil
        
        let timer = Timer(timeInterval: 0.75, repeats: false) { [weak self] _ in
            self?.preheatSecondPhoto()
        }
        
        self.preheaterTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }
}

extension NewFaceProfileViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource
{
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController])
    {
        self.input.scenarioManager.checkPhotoSwipe(self.input.sourceType)
        
        guard let urls = self.viewModel?.input.profile.orderedPhotos().map({ $0.filepath().url() }) else { return }
        
        self.preheater.startPreheating(with: urls.compactMap({ $0 }))
        UIManager.shared.feedsFabShouldBeHidden.accept(true)
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
        
        self.currentIndex.accept(index)
    }
}
