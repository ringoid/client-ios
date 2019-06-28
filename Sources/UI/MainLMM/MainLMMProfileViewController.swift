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
import Nuke

class MainLMMProfileViewController: UIViewController
{
    var input: MainLMMProfileVMInput!
    
    var topVisibleBorderDistance: CGFloat = 0.0
    {
        didSet {
            self.handleTopBorderDistanceChange(self.topVisibleBorderDistance)
        }
    }
    
    var bottomVisibleBorderDistance: CGFloat = 0.0
    {
        didSet {
            self.handleBottomBorderDistanceChange(self.bottomVisibleBorderDistance)
        }
    }
    
    var currentIndex: BehaviorRelay<Int> = BehaviorRelay<Int>(value: 0)
    var onChatShow: ((LMMProfile, Photo, MainLMMProfileViewController?) -> ())?
    var onChatHide: ((LMMProfile, Photo, MainLMMProfileViewController?) -> ())?
    var onBlockOptionsWillShow: ((Int) -> ())?
    var onBlockOptionsWillHide: (() -> ())?
    
    fileprivate let diposeBag: DisposeBag = DisposeBag()
    fileprivate var viewModel: MainLMMProfileViewModel?
    fileprivate var pagesVC: UIPageViewController?
    fileprivate var photosVCs: [NewFacePhotoViewController] = []
    fileprivate let preheater = ImagePreheater(destination: .diskCache)
    fileprivate var preheaterTimer: Timer?
    fileprivate var leftFieldsControls: [ProfileFieldControl] = []
    fileprivate var rightFieldsControls: [ProfileFieldControl] = []
    
    @IBOutlet fileprivate weak var messageBtn: UIButton!
    @IBOutlet fileprivate weak var optionsBtn: UIButton!
    @IBOutlet fileprivate weak var messageBtnTopConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var profileIdLabel: UILabel!
    @IBOutlet fileprivate weak var seenLabel: UILabel!
    @IBOutlet fileprivate weak var pagesControl: UIPageControl!
    @IBOutlet fileprivate weak var statusView: UIView!
    @IBOutlet fileprivate weak var statusLabel: UILabel!
    @IBOutlet fileprivate weak var nameLabel: UILabel!
    @IBOutlet fileprivate weak var nameConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var aboutLabel: UILabel!
    @IBOutlet fileprivate weak var rightColumnConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var aboutHeightConstraint: NSLayoutConstraint!
    
    // Profile fields
    @IBOutlet fileprivate weak var leftFieldIcon1: UIImageView!
    @IBOutlet fileprivate weak var leftFieldLabel1: UILabel!
    @IBOutlet fileprivate weak var leftFieldIcon2: UIImageView!
    @IBOutlet fileprivate weak var leftFieldLabel2: UILabel!
    
    @IBOutlet fileprivate weak var rightFieldIcon1: UIImageView!
    @IBOutlet fileprivate weak var rightFieldLabel1: UILabel!
    @IBOutlet fileprivate weak var rightFieldIcon2: UIImageView!
    @IBOutlet fileprivate weak var rightFieldLabel2: UILabel!
    
    static func create(_ profile: LMMProfile,
                       feedType: LMMType,
                       initialIndex: Int,
                       actionsManager: ActionsManager,
                       profileManager: UserProfileManager,
                       navigationManager: NavigationManager,
                       scenarioManager: AnalyticsScenarioManager,
                       transitionManager: TransitionManager
        ) -> MainLMMProfileViewController
    {
        let storyboard = Storyboards.mainLMM()
        let vc = storyboard.instantiateViewController(withIdentifier: "lmm_profile") as! MainLMMProfileViewController
        vc.input = MainLMMProfileVMInput(
            profile: profile,
            feedType: feedType,
            initialIndex: initialIndex,
            actionsManager: actionsManager,
            profileManager: profileManager,
            navigationManager: navigationManager,
            scenarioManager: scenarioManager,
            transitionManager: transitionManager
        )
        
        return vc
    }
    
    deinit {
        self.preheaterTimer?.invalidate()
        self.preheaterTimer = nil
    }
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        self.setupFieldsControls()
        
        // TODO: Move logic inside view model
        self.setupBindings()
        //self.setupPreheaterTimer()
        self.preheatSecondPhoto()
        
        guard !self.input.profile.isInvalidated else { return }
        
        self.updateMessageBtnOffset()
        
        let input = NewFaceProfileVMInput(
            profile: self.input.profile,
            sourceType: self.input.feedType.sourceType(),
            actionsManager: self.input.actionsManager,
            profileManager: self.input.profileManager,
            navigationManager: self.input.navigationManager,
            scenarioManager: self.input.scenarioManager,
            transitionManager: self.input.transitionManager
        )
        self.photosVCs = self.input.profile.orderedPhotos().map({ photo in
            let vc = NewFacePhotoViewController.create()
            vc.photo = photo
            vc.input = input
            vc.onChatBlock = { [weak self] in
                self?.onChatSelected()
            }
            
            return vc
        })
        
        let index = self.input.initialIndex
        guard index < self.photosVCs.count else { return }
        
        let vc = self.photosVCs[index]
        self.pagesVC?.setViewControllers([vc], direction: .forward, animated: false, completion: nil)
        self.currentIndex.accept(index)
        
        self.pagesControl.numberOfPages = self.input.profile.orderedPhotos().count
        self.pagesControl.currentPage = index
        
//        #if STAGE
//        self.profileIdLabel.text = "Profile: " + String(self.input.profile.id.prefix(4))
//        self.profileIdLabel.isHidden = false
//        #endif
        
        self.statusView.layer.borderWidth = 1.0
        self.statusView.layer.borderColor = UIColor.lightGray.cgColor  
        self.applyStatuses()
        self.applyName()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "embed_pages" {
            self.pagesVC = segue.destination as? UIPageViewController
            self.pagesVC?.delegate = self
            self.pagesVC?.dataSource = self
        }
    }
    
    func showNotChatControls()
    {
        if let iconName =  self.input.profile.state.iconName() {
            self.messageBtn.setImage(UIImage(named: iconName), for: .normal)
        } else {
            self.messageBtn.setImage(nil, for: .normal)
        }
        
        UIManager.shared.chatModeEnabled.accept(false)
    }
    
    func hideNotChatControls()
    {
        UIManager.shared.chatModeEnabled.accept(true)
    }
    
    func preheatSecondPhoto()
    {
        guard self.input.profile.photos.count >= 2 else { return }
        
        if let url = self.input.profile.orderedPhotos()[1].thumbnailFilepath().url() {
            self.preheater.startPreheating(with: [url])
        }
    }
    
    func block(_ isChat: Bool)
    {
        guard self.input.actionsManager.checkConnectionState() else { return }
        
        weak var weakSelf = self
        let profile = self.input.profile
        self.onChatHide?(profile, profile.orderedPhotos()[self.currentIndex.value], weakSelf)
        self.showBlockOptions(isChat)
    }
    
    // MARK: - Actions
    
    @IBAction func onChatSelected()
    {
        guard self.input.actionsManager.checkConnectionState() else { return }
        
        weak var weakSelf = self
        let profile = self.input.profile
        
        guard !profile.isInvalidated else { return }
        
        self.onChatShow?(profile, profile.orderedPhotos()[self.currentIndex.value], weakSelf)
    }
    
    @IBAction func onBlock()
    {
        self.block(false)
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.viewModel = MainLMMProfileViewModel(self.input)
        
        UIManager.shared.blockModeEnabled.asObservable().subscribe(onNext: { [weak self] state in
            guard let `self` = self else { return }
            
            self.messageBtn.isHidden =  ![
                LMMType.messages,
                LMMType.matches
                ].contains(self.input.feedType)  || state
            self.optionsBtn.isHidden = state
        }).disposed(by: self.diposeBag)
        
        UIManager.shared.chatModeEnabled.asObservable().subscribe(onNext: { [weak self] state in
            guard let `self` = self else { return }
            
            self.messageBtn.isHidden =  ![
                LMMType.messages,
                LMMType.matches
                ].contains(self.input.feedType)  || state
        }).disposed(by: self.diposeBag)
        
        Observable.from(object:self.input.profile).observeOn(MainScheduler.instance).subscribe({ [weak self] _ in
            self?.updateSeenState()
            self?.applyStatuses()
        }).disposed(by: self.diposeBag)
        
        self.currentIndex.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] page in
            self?.updateFieldsContent(page)
        }).disposed(by: self.diposeBag)
    }
    
    fileprivate func showBlockOptions(_ isChat: Bool)
    {
        UIManager.shared.blockModeEnabled.accept(true)
        onBlockOptionsWillShow?(self.currentIndex.value)
        
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertVC.addAction(UIAlertAction(title: "block_profile_button_block".localized(), style: .default, handler: { _ in
            UIManager.shared.blockModeEnabled.accept(false)
            self.onBlockOptionsWillHide?()
            self.viewModel?.block(at: self.currentIndex.value, reason: BlockReason(rawValue: 0)!)
            AnalyticsManager.shared.send(.blocked(0, self.input.feedType.sourceType().rawValue, isChat))
        }))
        alertVC.addAction(UIAlertAction(title: "block_profile_button_report".localized(), style: .default, handler: { _ in
            self.showBlockReasonOptions(isChat)
        }))
        alertVC.addAction(UIAlertAction(title: "button_cancel".localized(), style: .cancel, handler: { _ in
            self.onBlockOptionsWillHide?()
            UIManager.shared.blockModeEnabled.accept(false)
        }))
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
    fileprivate func showBlockReasonOptions(_ isChat: Bool)
    {
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let reasons = isChat ? BlockReason.reportChatResons() : BlockReason.reportResons()
        for reason in reasons {            
            alertVC.addAction(UIAlertAction(title: reason.title(), style: .default) { _ in
                self.showBlockReasonConfirmation(reason, isChat: isChat)
            })
        }
        
        alertVC.addAction(UIAlertAction(title: "button_cancel".localized(), style: .cancel, handler: { _ in
            self.onBlockOptionsWillHide?()
            UIManager.shared.blockModeEnabled.accept(false)
        }))
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
    fileprivate func showBlockReasonConfirmation(_ reason: BlockReason, isChat: Bool)
    {
        let alertVC = UIAlertController(
            title: nil,
            message: "block_profile_alert_title".localized() + " " + reason.title(),
            preferredStyle: .alert
        )
        alertVC.addAction(UIAlertAction(title: "block_profile_button_report".localized(), style: .default, handler: { _ in
            UIManager.shared.blockModeEnabled.accept(false)
            self.onBlockOptionsWillHide?()
            self.viewModel?.block(at: self.currentIndex.value, reason: reason)
            AnalyticsManager.shared.send(.blocked(reason.rawValue, self.input.feedType.sourceType().rawValue, isChat))
        }))
        alertVC.addAction(UIAlertAction(title: "button_cancel".localized(), style: .cancel, handler: { _ in
            self.onBlockOptionsWillHide?()
            UIManager.shared.blockModeEnabled.accept(false)
        }))
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
    fileprivate func updateMessageBtnOffset()
    {
        self.messageBtnTopConstraint.constant = self.input.feedType != .likesYou ? 138.0 : 228.0
    }
    
    fileprivate func handleTopBorderDistanceChange(_ value: CGFloat)
    {
        self.optionsBtn.alpha = self.discreetOpacity(for: self.topOpacityFor(self.optionsBtn.frame, offset: value) ?? 1.0)
        self.messageBtn.alpha = self.discreetOpacity(for: self.topOpacityFor(self.messageBtn.frame, offset: value) ?? 1.0)
        self.pagesControl.alpha = self.discreetOpacity(for: self.topOpacityFor(self.pagesControl.frame, offset: value) ?? 1.0)
        self.statusView.alpha = self.discreetOpacity(for: self.topOpacityFor(self.statusView.frame, offset: value) ?? 1.0)
        self.statusLabel.alpha = self.discreetOpacity(for: self.topOpacityFor(self.statusLabel.frame, offset: value) ?? 1.0)
        
        self.nameLabel.alpha = self.discreetOpacity(for: self.topOpacityFor(self.nameLabel.frame, offset: value) ?? 1.0)
        self.aboutLabel.alpha = self.discreetOpacity(for: self.topOpacityFor(self.aboutLabel.frame, offset: value) ?? 1.0)
        
        (self.leftFieldsControls + self.rightFieldsControls).forEach { controls in
            controls.iconView.alpha = self.discreetOpacity(for: self.topOpacityFor(controls.iconView.frame, offset: value) ?? 1.0)
            controls.titleLabel.alpha = self.discreetOpacity(for: self.topOpacityFor(controls.titleLabel.frame, offset: value) ?? 1.0)
        }
    }
    
    fileprivate func handleBottomBorderDistanceChange(_ value: CGFloat)
    {
        if let optionBtnOpacity = self.bottomOpacityFor(self.optionsBtn.frame, offset: value) {
            self.optionsBtn.alpha = self.discreetOpacity(for: optionBtnOpacity)
        }
        
        if let messageBtnOpacity = self.bottomOpacityFor(self.messageBtn.frame, offset: value) {
            self.messageBtn.alpha = self.discreetOpacity(for: messageBtnOpacity)
        }
        
        if let pagesControlOpacity = self.bottomOpacityFor(self.pagesControl.frame, offset: value) {
            self.pagesControl.alpha = self.discreetOpacity(for: pagesControlOpacity)
        }
        
        if let statusViewControlOpacity = self.bottomOpacityFor(self.statusView.frame, offset: value) {
            self.statusView.alpha = self.discreetOpacity(for: statusViewControlOpacity)
        }

        if let statusLabelControlOpacity = self.bottomOpacityFor(self.statusLabel.frame, offset: value) {
            self.statusLabel.alpha = self.discreetOpacity(for: statusLabelControlOpacity)
        }
        
        if let nameLabelControlOpacity = self.bottomOpacityFor(self.nameLabel.frame, offset: value) {
            self.nameLabel.alpha = self.discreetOpacity(for: nameLabelControlOpacity)
        }
        
        if let aboutLabelControlOpacity = self.bottomOpacityFor(self.aboutLabel.frame, offset: value) {
            self.aboutLabel.alpha = self.discreetOpacity(for: aboutLabelControlOpacity)
        }
        
        (self.leftFieldsControls + self.rightFieldsControls).forEach { controls in
            
            if let iconViewControlOpacity = self.bottomOpacityFor(controls.iconView.frame, offset: value) {
                controls.iconView.alpha = self.discreetOpacity(for: iconViewControlOpacity)
            }
            
            if let titleLabelControlOpacity = self.bottomOpacityFor(controls.titleLabel.frame, offset: value) {
                controls.titleLabel.alpha = self.discreetOpacity(for: titleLabelControlOpacity)
            }
        }
    }
    
    fileprivate func topOpacityFor(_ frame: CGRect, offset: CGFloat) -> CGFloat?
    {
        let y = frame.origin.y
        let inset = abs(offset)
        
        guard offset < 0.0 else { return nil }
        guard inset > y else { return nil }
        
        let t = 1.0 - (inset - y) / (frame.height / 2.0)
        
        guard t > 0.0 else { return 0.0 }
        
        return pow(t, 2.0)
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
        guard !self.input.profile.isInvalidated else { return }
        
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
    
    fileprivate func updateSeenState()
    {
        guard !self.input.profile.isInvalidated else { return }
        
//        #if STAGE
//        self.seenLabel.text = self.input.profile.notSeen == true ? "Not seen" : "Seen"
//        self.seenLabel.isHidden = false
//        #endif
        
        if let iconName =  self.input.profile.state.iconName() {
            self.messageBtn.setImage(UIImage(named: iconName), for: .normal)
        } else {
            self.messageBtn.setImage(nil, for: .normal)
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
        guard let gender: Sex = self.input.profileManager.gender.value?.opposite() else { return }
        
        // MALE
        if gender == .male {
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
                    
                    self.aboutLabel.text = aboutText
                    self.aboutLabel.isHidden = false
                    self.nameConstraint.constant = 86.0
                    self.aboutHeightConstraint.constant = (aboutText as NSString).boundingRect(
                        with: CGSize(width: self.aboutLabel.bounds.width, height: 999.0),
                        options: .usesLineFragmentOrigin,
                        attributes: [NSAttributedString.Key.font: self.aboutLabel.font],
                        context: nil
                        ).size.height
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
        
        // FEMALE
        if gender == .female {
            if page == 0 {
                if let aboutText = self.input.profile.about, aboutText != "unknown" {
                    (self.leftFieldsControls + self.rightFieldsControls).forEach({ controls in
                        controls.iconView.isHidden = true
                        controls.titleLabel.isHidden = true
                    })
                    
                    self.aboutLabel.text = aboutText
                    self.aboutLabel.isHidden = false
                    self.nameConstraint.constant = 86.0
                    self.aboutHeightConstraint.constant = (aboutText as NSString).boundingRect(
                        with: CGSize(width: self.aboutLabel.bounds.width, height: 999.0),
                        options: .usesLineFragmentOrigin,
                        attributes: [NSAttributedString.Key.font: self.aboutLabel.font],
                        context: nil
                        ).size.height + 4.0
                    self.view.layoutIfNeeded()
                } else {
                    self.aboutLabel.isHidden = true
                    self.updateProfileRows(0)
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
        var rightColumnMaxWidth: CGFloat = 0.0
        
        (0...1).forEach { index in
            let leftControls = self.leftFieldsControls[index]
            let rightControls = self.rightFieldsControls[index]
            let absoluteIndex = start + index
            
            if absoluteIndex >= leftCount {
                leftControls.iconView.isHidden = true
                leftControls.titleLabel.isHidden = true
                
                if index ==  1 && nameOffset > 41.0 { nameOffset = 60.0 }
                if index ==  0 { nameOffset = 40.0 }
                
            } else {
                let row = leftRows[absoluteIndex]
                leftControls.iconView.image = UIImage(named: row.icon ?? "")
                leftControls.titleLabel.text = row.title.localized()
                leftControls.iconView.isHidden = false
                leftControls.titleLabel.isHidden = false
            }
            
            if absoluteIndex >= rightCount {
                rightControls.iconView.isHidden = true
                rightControls.titleLabel.isHidden = true
            } else {
                let row = rightRows[absoluteIndex]
                rightControls.iconView.image = UIImage(named: row.icon ?? "")
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
        
        self.nameConstraint.constant = nameOffset
        self.rightColumnConstraint.constant = rightColumnMaxWidth + 4.0
        self.view.layoutIfNeeded()
    }
    
    fileprivate func applyName()
    {
        let profile = self.input.profile
        var title: String = ""
        if let name = profile.name, name != "unknown" {
            title += "\(name), "
        } else {
            let gender = self.input.profileManager.gender.value?.opposite() ?? .male
            let genderStr = gender == .male ? "common_sex_male".localized() : "common_sex_female".localized()
            title += "\(genderStr), "
        }
        
        title += "\(profile.age)"
        self.nameLabel.text = title
    }
}

extension MainLMMProfileViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource
{
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController])
    {
        self.input.scenarioManager.checkPhotoSwipe(self.input.feedType.sourceType())
        
        guard let urls = self.viewModel?.input.profile.orderedPhotos().map({ $0.thumbnailFilepath().url() }) else { return }
        
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
        
        self.pagesControl.currentPage = index
        self.currentIndex.accept(index)
    }
}

extension MessagingState
{
    func iconName() -> String?
    {
        switch self {
        case .chatUnread: return "feed_chat_unread"
        default: return nil
        }
    }
}
