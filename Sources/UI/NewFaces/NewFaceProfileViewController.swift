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

 struct ProfileFieldControl
{
    let iconView: UIImageView
    let titleLabel: UILabel
}

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
    fileprivate var leftFieldsControls: [ProfileFieldControl] = []
    fileprivate var rightFieldsControls: [ProfileFieldControl] = []
    
    @IBOutlet fileprivate weak var optionsBtn: UIButton!
    @IBOutlet fileprivate weak var profileIdLabel: UILabel!
    @IBOutlet fileprivate weak var pagesControl: UIPageControl!
    @IBOutlet fileprivate weak var statusView: UIView!
    @IBOutlet fileprivate weak var statusLabel: UILabel!
    @IBOutlet fileprivate weak var statusInfoLabel: UILabel!
    @IBOutlet fileprivate weak var nameLabel: UILabel!
    @IBOutlet fileprivate weak var nameConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var aboutLabel: UILabel!
    @IBOutlet fileprivate weak var leftColumnConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var rightColumnConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var aboutHeightConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var likeBtn: UIButton!
    @IBOutlet fileprivate weak var totalLikesLabel: UILabel!
    
    // Profile fields
    @IBOutlet fileprivate weak var leftFieldIcon1: UIImageView!
    @IBOutlet fileprivate weak var leftFieldLabel1: UILabel!
    @IBOutlet fileprivate weak var leftFieldIcon2: UIImageView!
    @IBOutlet fileprivate weak var leftFieldLabel2: UILabel!

    @IBOutlet fileprivate weak var rightFieldIcon1: UIImageView!
    @IBOutlet fileprivate weak var rightFieldLabel1: UILabel!
    @IBOutlet fileprivate weak var rightFieldIcon2: UIImageView!
    @IBOutlet fileprivate weak var rightFieldLabel2: UILabel!

    
    static func create(_ profile: NewFaceProfile,
                       initialIndex: Int,
                       actionsManager: ActionsManager,
                       profileManager: UserProfileManager,
                       navigationManager: NavigationManager,
                       scenarioManager: AnalyticsScenarioManager,
                       transitionManager: TransitionManager,
                       externalLinkManager: ExternalLinkManager
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
            transitionManager: transitionManager,
            externalLinkManager: externalLinkManager
        )
        vc.currentIndex.accept(initialIndex)
        
        return vc
    }
    
    deinit {
        self.preheater.stopPreheating()
        self.preheaterTimer?.invalidate()
        self.preheaterTimer = nil
    }
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        self.setupFieldsControls()
        self.setupBindings()
        //self.setupPreheaterTimer()
        self.preheatSecondPhoto()
        // TODO: Move all logic inside view model
        
        guard !self.input.profile.isInvalidated else { return }
        
        self.photosVCs = self.input.profile.orderedPhotos().map({ photo in
            let vc = NewFacePhotoViewController.create()
            vc.input = self.input
            vc.photo = photo
            vc.onBottomOptionsBlock = { [weak self] in
                self?.showBottomOptions()
            }
            vc.onLikeBlock = { [weak self] in
                self?.likeBtn.setImage(UIImage(named: "feed_like_selected"), for: .normal)
            }
            vc.shouldPrioritizeDoubleTap = true
            
            return vc
        })
        
        let count = self.input.profile.orderedPhotos().count        
        if self.currentIndex.value < count {
            let vc = self.photosVCs[self.currentIndex.value]
            self.pagesVC?.setViewControllers([vc], direction: .forward, animated: false, completion: nil)
            self.pagesControl.numberOfPages = count
            self.pagesControl.currentPage = self.currentIndex.value
        }
        
//        #if STAGE
//        self.profileIdLabel.text = "Profile: " +  String(self.input.profile.id.prefix(4))
//        self.profileIdLabel.isHidden = false
//        #endif
        
        self.statusView.layer.borderWidth = 1.0
        self.statusView.layer.borderColor = UIColor.lightGray.cgColor
        
        self.applyStatuses()
        self.applyName()
        self.applyTotalLikes()
        self.applyStatusInfo()
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
        guard let url = self.input.profile.orderedPhotos()[1].thumbnailFilepath().url() else { return }
        
        self.preheater.startPreheating(with: [url])
    }
    
    // MARK: - Actions
    
    @IBAction func onLike(sender: UIView)
    {
        let photoVC = self.photosVCs[self.currentIndex.value]        
        photoVC.handleTap(sender.center)
    }
    
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
        
        self.currentIndex.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] page in
            self?.updateFieldsContent(page)
        }).disposed(by: self.disposeBag)
    }

    fileprivate func showBlockOptions()
    {
        UIManager.shared.blockModeEnabled.accept(true)
        self.onBlockOptionsWillShow?(self.currentIndex.value)
        
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // Like
        alertVC.addAction(UIAlertAction(title: "profile_option_like".localized(), style: .default, handler: { _ in
            self.onBlockOptionsWillHide?()
            UIManager.shared.blockModeEnabled.accept(false)
            self.onLike(sender: self.view)
        }))
        
        self.input.externalLinkManager.availableServices(self.input.profile).forEach({ serviceResult in
            let service = serviceResult.0
            let userId = serviceResult.1
            let title = "\("profile_option_open".localized()) \(service.title): @\(userId)"
            alertVC.addAction(UIAlertAction(title: title, style: .default, handler: { _ in
                self.onBlockOptionsWillHide?()
                UIManager.shared.blockModeEnabled.accept(false)
                service.move(userId)
            }))
        })
        
        // Block
        alertVC.addAction(UIAlertAction(title: "block_profile_button_block".localized(), style: .default, handler: { _ in
            self.onBlockOptionsWillHide?()
            UIManager.shared.blockModeEnabled.accept(false)
            self.viewModel?.block(at: self.currentIndex.value, reason: BlockReason(rawValue: 0)!)
            AnalyticsManager.shared.send(.blocked(0, SourceFeedType.newFaces.rawValue, false))
        }))
        
        // Block options
        alertVC.addAction(UIAlertAction(title: "block_profile_button_report".localized(), style: .default, handler: { _ in
            self.showBlockReasonOptions()
        }))
        
        // Cancel
        alertVC.addAction(UIAlertAction(title: "button_cancel".localized(), style: .cancel, handler: { _ in
            self.onBlockOptionsWillHide?()
            UIManager.shared.blockModeEnabled.accept(false)
        }))
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
    fileprivate func showBottomOptions()
    {
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // Like
        alertVC.addAction(UIAlertAction(title: "profile_option_like".localized(), style: .default, handler: { _ in
            self.onLike(sender: self.view)
        }))
        
        self.input.externalLinkManager.availableServices(self.input.profile).forEach({ serviceResult in
            let service = serviceResult.0
            let userId = serviceResult.1
            let title = "\("profile_option_open".localized()) \(service.title): @\(userId)"
            alertVC.addAction(UIAlertAction(title: title, style: .default, handler: { _ in
                service.move(userId)
            }))
        })
        
        // Block
        alertVC.addAction(UIAlertAction(title: "block_profile_button_block".localized(), style: .default, handler: { _ in
            self.viewModel?.block(at: self.currentIndex.value, reason: BlockReason(rawValue: 0)!)
            AnalyticsManager.shared.send(.blocked(0, SourceFeedType.newFaces.rawValue, false))
        }))
        
        // Block options
        alertVC.addAction(UIAlertAction(title: "block_profile_button_report".localized(), style: .default, handler: { _ in
            self.showBlockReasonOptions()
        }))
        
        // Cancel
        alertVC.addAction(UIAlertAction(title: "button_cancel".localized(), style: .cancel, handler: { _ in
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
        // Options button interaction area special case
        let optionsOrig = self.optionsBtn.frame.origin
        let optionsSize = self.optionsBtn.frame.size
        let optionsFrame = CGRect(
            x: optionsOrig.x,
            y: optionsOrig.y + 11.0,
            width: optionsSize.width,
            height: optionsSize.height - 22.0
        )
        self.optionsBtn.alpha = self.discreetOpacity(for: self.bottomOpacityFor(optionsFrame, offset: value) ?? 1.0)
        
        // Status view interaction area special case
        let statusViewOrig = self.statusView.frame.origin
        let statusViewSize = self.statusView.frame.size
        let statusViewFrame = CGRect(
            x: statusViewOrig.x,
            y: statusViewOrig.y - 4.0,
            width: statusViewSize.width,
            height: statusViewSize.height + 8.0
        )
        self.statusView.alpha = self.discreetOpacity(for: self.bottomOpacityFor(statusViewFrame, offset: value) ?? 1.0)
        self.pagesControl.alpha = self.discreetOpacity(for: self.bottomOpacityFor(self.pagesControl.frame, offset: value) ?? 1.0)
        self.statusLabel.alpha = self.discreetOpacity(for: self.bottomOpacityFor(self.statusLabel.frame, offset: value) ?? 1.0)
        self.nameLabel.alpha = self.discreetOpacity(for: self.bottomOpacityFor(self.nameLabel.frame, offset: value) ?? 1.0)
        self.aboutLabel.alpha = self.discreetOpacity(for: self.bottomOpacityFor(self.aboutLabel.frame, offset: value) ?? 1.0)
        self.statusInfoLabel.alpha = self.discreetOpacity(for: self.bottomOpacityFor(self.statusInfoLabel.frame, offset: value) ?? 1.0)
        self.likeBtn.alpha = self.discreetOpacity(for: self.bottomOpacityFor(self.likeBtn.frame, offset: value) ?? 1.0)
        self.totalLikesLabel.alpha = self.discreetOpacity(for: self.bottomOpacityFor(self.totalLikesLabel.frame, offset: value) ?? 1.0)
        
        (self.leftFieldsControls + self.rightFieldsControls).forEach { controls in
            controls.iconView.alpha = self.discreetOpacity(for: self.bottomOpacityFor(controls.iconView.frame, offset: value) ?? 1.0)
            controls.titleLabel.alpha = self.discreetOpacity(for: self.bottomOpacityFor(controls.titleLabel.frame, offset: value) ?? 1.0)
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
    
    fileprivate func applyStatuses()
    {
        if let status = OnlineStatus(rawValue: self.input.profile.status), status != .unknown {
            self.statusView.backgroundColor = status.color()
            self.statusView.isHidden = false
        } else {
            self.statusView.isHidden = true
        }
        
        if let statusText = self.input.profile.statusText, statusText.lowercased() != "unknown",  statusText.count > 0 {
            self.statusLabel.text = statusText
            self.statusLabel.isHidden = false
        } else {
            self.statusLabel.isHidden = true
        }
    }
    
    fileprivate func applyName()
    {
        let profile = self.input.profile
        var title: String = ""
        if let name = profile.name, name != "unknown" {
            title += "\(name), "
        } else if let genderStr = profile.gender, let gender = Sex(rawValue: genderStr) {
            let genderStr = gender == .male ? "common_sex_male".localized() : "common_sex_female".localized()
            title += "\(genderStr), "
        } else {
            let gender = self.input.profileManager.gender.value?.opposite() ?? .male
            let genderStr = gender == .male ? "common_sex_male".localized() : "common_sex_female".localized()
            title += "\(genderStr), "
        }
        
        title += "\(profile.age)"
        self.nameLabel.text = title
    }
    
    fileprivate func applyTotalLikes()
    {
        let totalLikes = self.input.profile.totalLikes
        self.totalLikesLabel.text = "\(totalLikes)"
        self.totalLikesLabel.isHidden = totalLikes == 0
    }
    
    fileprivate func applyStatusInfo()
    {
        let profile = self.input.profile
        if let statusText = profile.statusInfo, statusText != "unknown" {
            let words = statusText.components(separatedBy: .whitespaces)
            var containsLongWorg = false
            words.forEach({ word in
                if word.count > 7 { containsLongWorg = true }
            })
            
            self.statusInfoLabel.lineBreakMode = containsLongWorg ? .byCharWrapping : .byWordWrapping
            self.statusInfoLabel.text = statusText
        } else {
            self.statusInfoLabel.text = nil
        }
    }
    
    fileprivate func setupFieldsControls()
    {
        self.leftFieldsControls = [
            ProfileFieldControl(iconView: self.leftFieldIcon1, titleLabel: self.leftFieldLabel1),
            ProfileFieldControl(iconView: self.leftFieldIcon2, titleLabel: self.leftFieldLabel2),
        ]
        
        self.rightFieldsControls = [
            ProfileFieldControl(iconView: self.rightFieldIcon1, titleLabel: self.rightFieldLabel1),
            ProfileFieldControl(iconView: self.rightFieldIcon2, titleLabel: self.rightFieldLabel2),
        ]
    }
    
    fileprivate func updateFieldsContent(_ page: Int)
    {
        guard !self.input.profile.isInvalidated else { return }
        
        if page == 0 {
            self.aboutLabel.isHidden = true
            self.updateProfileRows(0)
            
            return
        }
        
        if page == 1 {
            if let aboutText = self.input.profile.about, aboutText != "unknown" {
                (self.leftFieldsControls + self.rightFieldsControls).forEach({ controls in
                    controls.iconView.isHidden = true
                    controls.titleLabel.isHidden = true
                })
                
                var height = (aboutText as NSString).boundingRect(
                    with: CGSize(width: self.aboutLabel.bounds.width, height: 999.0),
                    options: .usesLineFragmentOrigin,
                    attributes: [NSAttributedString.Key.font: self.aboutLabel.font],
                    context: nil
                    ).size.height
                height = height < 64.0 ? height : 64.0
                
                self.aboutLabel.text = aboutText
                self.aboutLabel.isHidden = false
                self.nameConstraint.constant = height + 36.0
                self.aboutHeightConstraint.constant = height + 4.0
                self.view.layoutIfNeeded()
            } else {
                self.aboutLabel.isHidden = true
                self.updateProfileRows(1)
            }
            
            return
        }
        
        if let aboutText = self.input.profile.about, aboutText != "unknown" {
            self.aboutLabel.isHidden = true
            self.updateProfileRows(page - 1)
        } else {
            self.aboutLabel.isHidden = true
            self.updateProfileRows(page)
        }
    }
    
    fileprivate func updateProfileRows(_ page: Int)
    {
        let profileManager = self.input.profileManager
        let configuration = ProfileFieldsConfiguration(profileManager)
        let leftRows = configuration.leftColums(self.input.profile)
        let rightRows = configuration.rightColums(self.input.profile)
        let start = page * 2
        let leftCount = leftRows.count
        let rightCount = rightRows.count
        
        var nameOffset: CGFloat = 86.0
        let rightFieldMaxWidth: CGFloat = 132.0
        var rightColumnMaxWidth: CGFloat = 0.0
        
        defer {
            self.nameConstraint.constant = nameOffset
            
            let rightColumnWidth = rightColumnMaxWidth < rightFieldMaxWidth ? ( rightColumnMaxWidth + 4.0) : (rightFieldMaxWidth + 4.0)
            self.rightColumnConstraint.constant = rightColumnWidth
            
            let leftFieldMaxWidth = UIScreen.main.bounds.width - rightColumnWidth - 72.0
            self.leftColumnConstraint.constant = leftFieldMaxWidth
            self.view.layoutIfNeeded()
        }
        
        (0...1).forEach { index in
            var leftControls = self.leftFieldsControls[index]
            var rightControls = self.rightFieldsControls[index]
            let absoluteIndex = start + (1 - index)
            
            // Left
            
            var leftRow: ProfileFileRow? = nil
            
            if absoluteIndex >= leftCount {
                leftControls.iconView.isHidden = true
                leftControls.titleLabel.isHidden = true
                
                if index ==  1 && nameOffset > 41.0 { nameOffset = 60.0 }
                if index ==  0 { nameOffset = 40.0 }
                
            } else if leftCount - absoluteIndex == 1, index == 1 {
                leftControls.iconView.isHidden = true
                leftControls.titleLabel.isHidden = true
                
                nameOffset = 60.0
                
                leftRow = leftRows[absoluteIndex]
                leftControls = self.leftFieldsControls[0]
            } else {
                leftRow = leftRows[absoluteIndex]
            }
            
            if let row = leftRow {
                if let icon = row.icon {
                    leftControls.iconView.image = UIImage(named: icon)
                } else {
                    leftControls.iconView.image = nil
                }
                
                leftControls.titleLabel.text = row.title.localized()
                leftControls.iconView.isHidden = false
                leftControls.titleLabel.isHidden = false
            }
            
            // Right
            var rightRow: ProfileFileRow? = nil
            
            if absoluteIndex >= rightCount {
                rightControls.iconView.isHidden = true
                rightControls.titleLabel.isHidden = true
            } else if rightCount - absoluteIndex == 1, index == 1 { // Special case
                rightControls.iconView.isHidden = true
                rightControls.titleLabel.isHidden = true
                
                rightRow = rightRows[absoluteIndex]
                rightControls = self.rightFieldsControls[0]
            } else {
                rightRow = rightRows[absoluteIndex]
            }
            
            if let row = rightRow {
                if let icon = row.icon {
                    rightControls.iconView.image = UIImage(named: icon)
                } else {
                    rightControls.iconView.image = nil
                }
                
                rightControls.titleLabel.text = row.title.localized()
                rightControls.iconView.isHidden = false
                rightControls.titleLabel.isHidden = false
                
                let width = (row.title.localized() as NSString).size(withAttributes: [
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12.0)
                    ]).width
                
                if width > rightColumnMaxWidth {
                    rightColumnMaxWidth = width
                }
            }
        }
    }
}

extension NewFaceProfileViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource
{
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController])
    {
        self.input.scenarioManager.checkPhotoSwipe(self.input.sourceType)
        
        guard let urls = self.viewModel?.input.profile.orderedPhotos().map({ $0.thumbnailFilepath().url() }) else { return }
        
        self.preheater.startPreheating(with: urls.compactMap({ $0 }))
        UIManager.shared.feedsFabShouldBeHidden.accept(true)
        UIManager.shared.discoverTopBarShouldBeHidden.accept(true)
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
        
        self.pagesControl.currentPage = index
        self.currentIndex.accept(index)
    }
}

extension OnlineStatus
{
    func color() -> UIColor
    {
        switch self {
        case .unknown: return .red
        case .offline: return .clear
        case .away: return UIColor(red: 1.0, green: 230.0 / 255.0, blue: 64.0 / 255.0, alpha: 1.0)
        case .online: return UIColor(red: 102.0 / 255.0, green: 1.0, blue: 64.0 / 255.0, alpha: 1.0)
        }
    }
}
