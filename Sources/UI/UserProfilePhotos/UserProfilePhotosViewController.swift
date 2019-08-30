//
//  UserProfilePhotosViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 07/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Nuke
import MobileCoreServices

class UserProfilePhotosViewController: BaseViewController
{
    var input: UserProfilePhotosVCInput!
    var autopickEnabled: Bool = false
    
    fileprivate var viewModel: UserProfilePhotosViewModel?
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    fileprivate var pickerVC: UIViewController?
    fileprivate weak var pagesVC: UIPageViewController?
    fileprivate var photosVCs: [UIViewController] = []
    fileprivate var currentIndex: BehaviorRelay<Int> = BehaviorRelay<Int>(value: 0)
    fileprivate var lastClientPhotoId: String? = nil
    fileprivate let preheater = ImagePreheater(destination: .diskCache)
    fileprivate var pickedPhoto: UIImage?
    fileprivate var isViewShown: Bool = false
    fileprivate var leftFieldsControls: [ProfileFieldControl] = []
    fileprivate var rightFieldsControls: [ProfileFieldControl] = []
    fileprivate let photoHeight: CGFloat = UIScreen.main.bounds.width * AppConfig.photoRatio
    
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var emptyFeedLabel: UILabel!
    @IBOutlet fileprivate weak var deleteBtn: UIButton!
    @IBOutlet fileprivate weak var optionsBtn: UIButton!
    @IBOutlet fileprivate weak var addBtn: UIButton!
    @IBOutlet fileprivate weak var containerTableView: UITableView!
    @IBOutlet fileprivate weak var pagesControl: UIPageControl!
    @IBOutlet fileprivate weak var pagesTopConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var statusView: UIView!
    @IBOutlet fileprivate weak var statusLabel: UILabel!
    @IBOutlet fileprivate weak var statusInfoLabel: UILabel!
    @IBOutlet fileprivate weak var statusInfoBtn: UIButton!
    @IBOutlet fileprivate weak var nameLabel: UILabel!
    @IBOutlet fileprivate weak var nameConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var aboutLabel: UILabel!
    @IBOutlet fileprivate weak var leftColumnConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var rightColumnConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var aboutHeightConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var fieldsBottomConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var pencilIconView: UIImageView!
    @IBOutlet fileprivate weak var addPhotoCenterBtn: UIButton!
    @IBOutlet fileprivate weak var statusInfoCenterConstraing: NSLayoutConstraint!
    @IBOutlet fileprivate weak var pencilBtn: UIButton!
    @IBOutlet fileprivate weak var bottomOptionsBtn: UIButton!
    
    // Profile fields
    @IBOutlet fileprivate weak var leftFieldIcon1: UIImageView!
    @IBOutlet fileprivate weak var leftFieldLabel1: UILabel!
    @IBOutlet fileprivate weak var leftFieldIcon2: UIImageView!
    @IBOutlet fileprivate weak var leftFieldLabel2: UILabel!
    
    @IBOutlet fileprivate weak var rightFieldIcon1: UIImageView!
    @IBOutlet fileprivate weak var rightFieldLabel1: UILabel!
    @IBOutlet fileprivate weak var rightFieldIcon2: UIImageView!
    @IBOutlet fileprivate weak var rightFieldLabel2: UILabel!
    
    override func viewDidLoad()
    {
        assert(input != nil)
        
        super.viewDidLoad()
        
        self.fieldsBottomConstraint.constant = self.photoHeight + 20.0
        self.setupFieldsControls()        
        
        let height = UIScreen.main.bounds.width * AppConfig.photoRatio
        self.containerTableView.rowHeight = height
        self.containerTableView.contentInset = UIEdgeInsets(top: 56.0, left: 0.0, bottom: 0.0, right: 0.0)
        self.containerTableView.reloadData()
        
        self.pagesControl.numberOfPages = self.viewModel?.photos.value.count ?? 0
        self.pagesControl.currentPage = 0
        self.pagesTopConstraint.constant = height + 24.0
        
        self.statusView.layer.borderWidth = 1.0

        self.setupBindings()
        self.setupReloader()
        
        self.applyName()
        self.applyStatusInfo()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        self.isViewShown = true
        
        if self.viewModel?.isBlocked.value == true {
            self.viewModel?.isBlocked.accept(false)
            self.showBlockedAlert()
        }

        guard let photos = self.viewModel?.photos.value else { return }
        
        self.preheater.startPreheating(with: photos.compactMap({ $0.filepath().url() }))
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        self.isViewShown = false
    }
    
    override func viewWillLayoutSubviews()
    {
        super.viewWillLayoutSubviews()
        
        self.setupStatusInfoConstraint()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == SegueIds.cropVC, let vc = segue.destination as? UserProfilePhotoCropViewController {
            vc.sourceImage = self.pickedPhoto
            vc.delegate = self
        }
    }
    
    override func updateTheme()
    {
        self.view.backgroundColor = BackgroundColor().uiColor()
    }
    
    override func updateLocale()
    {
        self.emptyFeedLabel.text = "profile_empty_images".localized()
    }
    
    func showPhotoPicker()
    {
        self.pickPhoto()
    }
    
    @objc fileprivate func onReload()
    {
        AnalyticsManager.shared.send(.pullToRefresh(SourceFeedType.profile.rawValue))
        self.reload()
    }
    
    func reload()
    {
        self.containerTableView.panGestureRecognizer.isEnabled = false
        
        // Location
        guard self.viewModel?.isLocationDenied != true else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                self.containerTableView.refreshControl?.endRefreshing()
            })
            
            self.containerTableView.panGestureRecognizer.isEnabled = true
            self.showLocationsSettingsAlert()
            
            return
        }
        
        guard self.viewModel?.registerLocationsIfNeeded() == true else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                self.containerTableView.refreshControl?.endRefreshing()
            })
            
            self.containerTableView.panGestureRecognizer.isEnabled = true
            
            return
        }
        
        // No internet
        guard self.input.actionsManager.checkConnectionState() else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                self.containerTableView.refreshControl?.endRefreshing()
            })
        
            self.containerTableView.panGestureRecognizer.isEnabled = true
            
            return
        }
        
        UIManager.shared.userProfileLikesVisible.accept(false)
        
        self.viewModel?.refresh().subscribe(
            onError:{ [weak self] error in
                guard let `self` = self else { return }
                
                self.containerTableView.panGestureRecognizer.isEnabled = true
                showError(error, vc: self)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                    UIManager.shared.userProfileLikesVisible.accept(true)
                    self.containerTableView.refreshControl?.endRefreshing()
                })
            }, onCompleted:{ [weak self] in
                self?.containerTableView.panGestureRecognizer.isEnabled = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                    UIManager.shared.userProfileLikesVisible.accept(true)
                    self?.containerTableView.refreshControl?.endRefreshing()
                })
        }).disposed(by: self.disposeBag)
    }
    
    // MARK: - Actions
    
    @IBAction func addPhoto()
    {
        guard self.viewModel?.isLocationDenied != true else {
            self.showLocationsSettingsAlert()
            
            return
        }
        
        guard self.viewModel?.registerLocationsIfNeeded() == true else { return }
        guard self.input.actionsManager.checkConnectionState() else { return }
        
        self.input.scenario.checkPhotoAddedManually()
        self.pickPhoto()
    }
    
    @IBAction func deletePhoto()
    {
        guard self.input.actionsManager.checkConnectionState() else { return }
        
        self.showDeletionAlert()
    }
    
    @IBAction func showSettings()
    {
        let storyboard = Storyboards.settings()
        guard let navVC = storyboard.instantiateInitialViewController() else { return }
        guard let vc = (navVC as? UINavigationController)?.viewControllers.first as? SettingsViewController else { return }
        vc.input = SettingsVMInput(
            settingsManager: self.input.settingsManager,
            actionsManager: self.input.actionsManager,
            errorsManager: self.input.errorsManager,
            profileManager: self.input.profileManager,
            device: self.input.device,
            db: self.input.db,
            navigationManager: self.input.navigationManager,
            filter: self.input.filter,
            lmm: self.input.lmmManager,
            newFaces: self.input.newFacesManager
        )
        
        ModalUIManager.shared.show(navVC, animated: true)
    }
    
    @IBAction func onStatusTap()
    {
        let storyboard = Storyboards.settings()
        guard let profileVC = storyboard.instantiateViewController(withIdentifier: "settings_profile") as? SettingsProfileViewController else { return }
        
        profileVC.input = SettingsProfileVMInput(
            profileManager: self.input.profileManager,
            db: self.input.db,
            navigationManager: self.input.navigationManager,
            defaultField: .status
        )
        profileVC.isModal = true
        
        ModalUIManager.shared.show(profileVC, animated: true)
    }
    
    @IBAction func onEditProfileFields()
    {
        let storyboard = Storyboards.settings()
        guard let profileVC = storyboard.instantiateViewController(withIdentifier: "settings_profile") as? SettingsProfileViewController else { return }
        
        profileVC.input = SettingsProfileVMInput(
            profileManager: self.input.profileManager,
            db: self.input.db,
            navigationManager: self.input.navigationManager,
            defaultField: nil
        )
        profileVC.isModal = true
        
        ModalUIManager.shared.show(profileVC, animated: true)
    }
    
    @IBAction func onBottomOptions()
    {
        guard self.input.actionsManager.checkConnectionState() else { return }
        
        self.showBottomOptions()
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.viewModel = UserProfilePhotosViewModel(self.input)
        self.viewModel?.photos.observeOn(MainScheduler.instance).asObservable().subscribe(onNext: { [weak self] photos in
            guard let `self` = self else { return }
            
            if photos.count == 0 {
                self.statusView.isHidden = true
                self.statusLabel.isHidden = true
                self.pencilIconView.isHidden = true
                self.pencilBtn.isEnabled = false
                self.addPhotoCenterBtn.isEnabled = true
            } else if self.viewModel?.status.value != nil {
                self.statusView.isHidden = false
                self.statusLabel.isHidden = false
                self.pencilIconView.isHidden = false
                self.pencilBtn.isEnabled = true
                self.addPhotoCenterBtn.isEnabled = false
            } else {
                self.pencilIconView.isHidden = false
                self.pencilBtn.isEnabled = true
                self.addPhotoCenterBtn.isEnabled = false
            }
            
            let alpha: CGFloat = photos.count == 0 ? 0.0 : 1.0
            self.nameLabel.alpha = alpha
            self.aboutLabel.alpha = alpha
            self.statusInfoLabel.alpha = alpha
            self.statusInfoBtn.isHidden = photos.count == 0
            self.bottomOptionsBtn.isHidden = photos.count == 0
            
            (self.leftFieldsControls + self.rightFieldsControls).forEach({ control in
                control.iconView.alpha = alpha
                control.titleLabel.alpha = alpha
            })
            
            self.updatePages()
        }).disposed(by: self.disposeBag)
        
        self.viewModel?.isBlocked.observeOn(MainScheduler.instance).asObservable().subscribe(onNext: { [weak self] state in
            guard let `self` = self else { return }
            guard state else { return }
            
            if self.isViewShown {
                self.viewModel?.isBlocked.accept(false)
                self.showBlockedAlert()
            }
        }).disposed(by: self.disposeBag)
        
        self.viewModel?.status.observeOn(MainScheduler.init()).subscribe(onNext: { [weak self] onlineStatus in
            guard let count = self?.viewModel?.photos.value.count, count > 0 else {
                self?.statusView.isHidden = true
                
                return
            }
            
            if let status = onlineStatus, status != .unknown {
                self?.statusView.backgroundColor = status.color()
                self?.statusView.isHidden = false
            } else {
                self?.statusView.isHidden = true
            }
        }).disposed(by: self.disposeBag)
        
        self.viewModel?.statusText.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] onlineText in
            guard let count = self?.viewModel?.photos.value.count, count > 0 else {
                self?.statusLabel.isHidden = true
                
                return
            }
            
            if let text = onlineText, text.lowercased() != "unknown", text.count > 0 {
                self?.statusLabel.text = text
                self?.statusLabel.isHidden = false
            } else {
                self?.statusLabel.isHidden = true
            }
        }).disposed(by: self.disposeBag)
        
        self.currentIndex.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] page in
            self?.updateFieldsContent(page)
        }).disposed(by: self.disposeBag)
        
        if let profile = self.input.profileManager.profile.value {
            Observable.from(object: profile).observeOn(MainScheduler.instance).subscribe({ [weak self] _ in
                guard let `self` = self else { return }
                
                self.updateFieldsContent(self.currentIndex.value)
                self.applyName()
                self.applyStatusInfo()
            }).disposed(by: self.disposeBag)
        }
    }
    
    fileprivate func setupReloader()
    {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(onReload), for: .valueChanged)
        self.containerTableView.refreshControl = refreshControl
    }
    
    fileprivate func pickPhoto()
    {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.mediaTypes = [kUTTypeImage] as [String]
        vc.delegate = self
        
        self.present(vc, animated: true, completion: nil)
    }
    
    fileprivate func updatePages()
    {
        guard let photos = self.viewModel?.photos.value else { return }
        
        var startIndex = 0
        if let id = self.viewModel?.lastPhotoId.value
        {
            for (index, photo) in photos.enumerated() {
                if photo.originId == id { startIndex = index }
            }
        } else if let clientId = self.lastClientPhotoId {
            for (index, photo) in photos.enumerated() {
                if photo.clientId == clientId { startIndex = index }
            }
        } else {
            guard let photo = photos.first else { return }
            
            self.viewModel?.lastPhotoId.accept(photo.originId)            
        }
        
        self.emptyFeedLabel.isHidden = !photos.isEmpty
        self.photosVCs = photos.map({ photo in
            let vc = UserProfilePhotoViewController.create()
            vc.photo = photo
            vc.input = SettingsProfileVMInput(
                profileManager: self.input.profileManager,
                db: self.input.db,
                navigationManager: self.input.navigationManager,
                defaultField: nil
            )

            return vc
        })
        
        if !photos.isEmpty {
            let vc = self.photosVCs[startIndex]
            let direction: UIPageViewController.NavigationDirection = (photos.count - 1) == startIndex ? .reverse : .forward
            self.pagesVC?.setViewControllers([vc], direction: direction, animated: false, completion: nil)
        } else {
            self.pagesVC?.setViewControllers([UIViewController()], direction: .forward, animated: false, completion: nil)
        }
        
        self.currentIndex.accept(startIndex)
        self.pagesControl.numberOfPages = photos.count
        self.pagesControl.currentPage = startIndex
        self.deleteBtn.isHidden = photos.isEmpty
    }
    
    fileprivate func showDeletionAlert()
    {
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertVC.addAction(UIAlertAction(title: "profile_button_delete_image".localized(), style: .destructive, handler: ({ _ in
            guard let photo = self.viewModel?.photos.value[self.currentIndex.value] else { return }
            
            if photo.likes > 0 {
                self.showDeletionConfirmationAlert()
                
                return
            }
            
            self.showControls()
            self.viewModel?.delete(photo)
        })))
        alertVC.addAction(UIAlertAction(title: "button_cancel".localized(), style: .cancel, handler: { _ in
            self.showControls()
        }))
        
        self.hideControls()
        self.present(alertVC, animated: true, completion: nil)
    }
    
    fileprivate func showBottomOptions()
    {
        guard let profile = self.input.profileManager.profile.value else { return }
        
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // Delete
        alertVC.addAction(UIAlertAction(title: "profile_button_delete_image".localized(), style: .destructive, handler: ({ _ in
            guard let photo = self.viewModel?.photos.value[self.currentIndex.value] else { return }
            
            if photo.likes > 0 {
                self.showDeletionConfirmationAlert()
                
                return
            }
            
            self.showControls()
            self.viewModel?.delete(photo)
        })))
        
        // Add
        alertVC.addAction(UIAlertAction(title: "profile_button_add_image".localized(), style: .default, handler: ({ _ in
            self.addPhoto()
            self.showControls()
        })))
        
        // Edit status
        alertVC.addAction(UIAlertAction(title: "profile_button_edit_status".localized(), style: .default, handler: ({ _ in
            self.onStatusTap()
            self.showControls()
        })))
        
        // Edit profile
        alertVC.addAction(UIAlertAction(title: "profile_button_edit".localized(), style: .default, handler: ({ _ in
            self.onEditProfileFields()
            self.showControls()
        })))
        
        // Options
        self.input.externalLinkManager.availableServices(profile).forEach({ serviceResult in
            let service = serviceResult.0
            let userId = serviceResult.1
            let title = "\("profile_option_open".localized()) \(service.title): @\(userId)"
            alertVC.addAction(UIAlertAction(title: title, style: .default, handler: { _ in
                service.move(userId)
                self.showControls()
            }))
        })
        
        // Cancel
        alertVC.addAction(UIAlertAction(title: "button_cancel".localized(), style: .cancel, handler: { _ in
            self.showControls()
        }))
        
        self.hideControls()
        self.present(alertVC, animated: true, completion: nil)
    }
    
    fileprivate func showDeletionConfirmationAlert()
    {
        let alertVC = UIAlertController(
            title: "profile_dialog_image_delete_title".localized(),
            message: "common_uncancellable".localized(),
            preferredStyle: .alert
        )
        alertVC.addAction(UIAlertAction(title: "profile_button_delete_image".localized(), style: .default, handler: ({ _ in
            guard let photo = self.viewModel?.photos.value[self.currentIndex.value] else { return }
            
            self.showControls()
            self.viewModel?.delete(photo)
        })))
        alertVC.addAction(UIAlertAction(title: "button_cancel".localized(), style: .cancel, handler: { _ in
            self.showControls()
        }))
        
        self.hideControls()
        self.present(alertVC, animated: true, completion: nil)
    }
    
    fileprivate func showControls()
    {
        self.deleteBtn.isHidden = false
        self.optionsBtn.isHidden = false
        self.addBtn.isHidden = false
        self.titleLabel.isHidden = false
        self.pagesControl.isHidden = false
        
        self.statusLabel.alpha = 1.0
        self.statusView.alpha = 1.0
        self.pencilIconView.alpha = 1.0
        
        self.nameLabel.alpha = 1.0
        self.aboutLabel.alpha = 1.0
        self.statusInfoLabel.alpha = 1.0
        self .statusInfoBtn.isHidden = false
        self.bottomOptionsBtn.isHidden = false
        (self.leftFieldsControls + self.rightFieldsControls).forEach({ control in
            control.iconView.alpha = 1.0
            control.titleLabel.alpha = 1.0
        })
    }
    
    fileprivate func hideControls()
    {
        self.deleteBtn.isHidden = true
        self.optionsBtn.isHidden = true
        self.addBtn.isHidden = true
        self.titleLabel.isHidden = true
        self.pagesControl.isHidden = true
        
        self.statusLabel.alpha = 0.0
        self.statusView.alpha = 0.0
        self.pencilIconView.alpha = 0.0
        
        self.nameLabel.alpha = 0.0
        self.aboutLabel.alpha = 0.0
        self.statusInfoLabel.alpha = 0.0
        self.statusInfoBtn.isHidden = true
        self.bottomOptionsBtn.isHidden = true
        
        (self.leftFieldsControls + self.rightFieldsControls).forEach({ control in
            control.iconView.alpha = 0.0
            control.titleLabel.alpha = 0.0
        })
    }
    
    fileprivate func showBlockedAlert()
    {
        let alertVC = UIAlertController(title: nil, message: "profile_dialog_image_blocked_title".localized(), preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "profile_dialog_image_blocked_button".localized(), style: .default, handler: { _ in
            UIApplication.shared.open(AppConfig.termsUrl, options: [:], completionHandler: nil)
        }))
        alertVC.addAction(UIAlertAction(title: "button_close".localized(), style: .cancel, handler: nil))
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
    fileprivate func showFieldsEditor()
    {
        let storyboard = Storyboards.settings()
        guard let profileVC = storyboard.instantiateViewController(withIdentifier: "settings_profile") as? SettingsProfileViewController else { return }
        
        profileVC.input = SettingsProfileVMInput(
            profileManager: self.input.profileManager,
            db: self.input.db,
            navigationManager: self.input.navigationManager,
            defaultField: nil
        )
        profileVC.isModal = true
        
        ModalUIManager.shared.show(profileVC, animated: true)
    }
    
    fileprivate func showLocationsSettingsAlert()
    {
        let alertVC = UIAlertController(title: nil, message: "settings_location_permission".localized(), preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "button_later".localized(), style: .cancel, handler: nil))
        alertVC.addAction(UIAlertAction(title: "button_settings".localized(), style: .default, handler: { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        }))
        
        self.present(alertVC, animated: true, completion: nil)
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
    
    fileprivate func setupStatusInfoConstraint()
    {
        let screenHeight = UIScreen.main.bounds.height
        let topOffset = self.view.safeAreaInsets.top + 56.0 + self.photoHeight / 2.0
        self.statusInfoCenterConstraing.constant = topOffset - screenHeight / 2.0
    }
    
    fileprivate func updateFieldsContent(_ page: Int)
    {
        guard let profile = self.input.profileManager.profile.value, !profile.isInvalidated else { return }
        
        if page == 0 {
            self.aboutLabel.isHidden = true
            self.updateProfileRows(0)
            
            return
        }
        
        if page == 1 {
            if let aboutText = profile.about, aboutText != "unknown", !aboutText.isEmpty {
                (self.leftFieldsControls + self.rightFieldsControls).forEach({ controls in
                    controls.iconView.isHidden = true
                    controls.titleLabel.isHidden = true
                })
                
                var height = (aboutText as NSString).boundingRect(
                    with: CGSize(width: self.aboutLabel.bounds.width, height: 999.0),
                    options: .usesLineFragmentOrigin,
                    attributes: [NSAttributedString.Key.font: self.aboutLabel.font],
                    context: nil
                    ).size.height + 4.0
                height = height < 120.0 ? height : 120.0
                
                self.aboutLabel.text = aboutText
                self.aboutLabel.isHidden = false
                self.nameConstraint.constant = self.photoHeight - height + 24.0
                self.aboutHeightConstraint.constant = height
                self.view.layoutIfNeeded()
            } else {
                self.aboutLabel.isHidden = true
                self.updateProfileRows(1)
            }
            
            return
        }
        
        if let aboutText = profile.about, aboutText != "unknown", !aboutText.isEmpty {
            self.aboutLabel.isHidden = true
            self.updateProfileRows(page - 1)
        } else {
            self.aboutLabel.isHidden = true
            self.updateProfileRows(page)
        }
    }
    
    fileprivate func updateProfileRows(_ page: Int)
    {
        guard let profile = self.input.profileManager.profile.value else { return }
        
        let profileManager = self.input.profileManager
        let configuration = ProfileFieldsConfiguration(profileManager)
        let leftRows = configuration.leftUserColumns(profile)
        let rightRows = configuration.rightUserColumns(profile)
        let start = page * 2
        let leftCount = leftRows.count
        let rightCount = rightRows.count
        
        var nameOffset: CGFloat = self.photoHeight - 26.0
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
                
                if index ==  1 && nameOffset <  self.photoHeight - 1.0 { nameOffset =  self.photoHeight}
                if index ==  0 { nameOffset =  self.photoHeight + 20.0 }
                
            } else if leftCount - absoluteIndex == 1, index == 1 {
                leftControls.iconView.isHidden = true
                leftControls.titleLabel.isHidden = true
                
                nameOffset =  self.photoHeight
                
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
    
    fileprivate func applyName()
    {
        guard let profile = self.input.profileManager.profile.value, !profile.isInvalidated else { return }
        
        var title: String = ""
        if let name = profile.name, name != "unknown" {
            title += "\(name)"
        } else {
            let gender = self.input.profileManager.gender.value ?? .male
            let genderStr = gender == .male ? "common_sex_male".localized() : "common_sex_female".localized()
            title += "\(genderStr)"
        }
        
        if let yob = self.input.profileManager.yob.value {
            let age =  Calendar.current.component(.year, from: Date()) - yob
            title += ", \(age)"
        }
        
        self.nameLabel.text = title
    }
    
    fileprivate func applyStatusInfo()
    {
        guard let profile = self.input.profileManager.profile.value, !profile.isInvalidated else { return }
        
        if let statusText = profile.statusInfo, statusText != "unknown" {
            let words = statusText.components(separatedBy: .whitespaces)
            var containsLongWord = false
            words.forEach({ word in
                if word.count > 7 { containsLongWord = true }
            })
            
            self.statusInfoLabel.lineBreakMode = containsLongWord ? .byCharWrapping : .byWordWrapping
            self.statusInfoLabel.text = statusText
        } else if UserDefaults.standard.integer(forKey: "settings_profile_fields_opened") < 2 {
            self.statusInfoLabel.lineBreakMode = .byWordWrapping
            self.statusInfoLabel.text = "profile_field_status_placeholder".localized()
        } else {
            self.statusInfoLabel.text = nil
        }
    }
}

extension UserProfilePhotosViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        guard let image = info[.originalImage] as? UIImage else { return }
        
        self.pickedPhoto = image

        guard let cropVC = Storyboards.userProfile().instantiateViewController(withIdentifier: "crop_vc") as? UserProfilePhotoCropViewController else { return }
        cropVC.sourceImage = image
        cropVC.delegate = self
        picker.pushViewController(cropVC, animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        if UIManager.shared.discoverAddPhotoModeEnabled.value {
            picker.dismiss(animated: false, completion: { [weak self] in
                UIManager.shared.discoverAddPhotoModeEnabled.accept(false)
                self?.input.navigationManager.mainItem.accept(.search)
            })
            
            return
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
}

extension UserProfilePhotosViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource
{
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController])
    {
        self.input.scenario.checkPhotoSwipe(.profile)
    }
    
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
        self.pagesControl.currentPage = index
        
        guard let photo = self.viewModel?.photos.value[index] else { return }
        
        self.viewModel?.lastPhotoId.accept(photo.originId)        
    }
}

extension UserProfilePhotosViewController: UITableViewDataSource, UITableViewDelegate
{
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "container_cell") as! UserProfileContainerCell
        
        let storyboard = Storyboards.userProfile()
        let vc = storyboard.instantiateViewController(withIdentifier: "pages_vc") as! UIPageViewController
        vc.delegate = self
        vc.dataSource = self
        self.pagesVC = vc
        
        cell.containerView.embed(vc, to: self)

        self.updatePages()
        
        return cell
    }
}

extension UserProfilePhotosViewController: UserProfilePhotoCropVCDelegate
{
    func cropVC(_ vc: UserProfilePhotoCropViewController, didCrop image: UIImage)
    {
        self.viewModel?.add(image).subscribe(onNext: ({ [weak self] photo in
            self?.viewModel?.lastPhotoId.accept(nil)
            self?.lastClientPhotoId = photo.clientId
            self?.updatePages()
            
            if let profile = self?.input.profileManager.profile.value {
                if profile.name == nil ||
                    profile.name == "unknown" ||
                    profile.whereLive == nil ||
                    profile.whereLive == "unknown" {
                    self?.showFieldsEditor()
                    
                    return
                }
            }
            
            if UIManager.shared.discoverAddPhotoModeEnabled.value {
                UIManager.shared.discoverAddPhotoModeEnabled.accept(false)
                self?.input.navigationManager.mainItem.accept(.search)
            }
            
        }), onError: ({ [weak self] error in
            guard let `self` = self else { return }
            
            showError(error, vc: self)
        })).disposed(by: self.disposeBag)
    }
}

extension UserProfilePhotosViewController
{
    struct SegueIds
    {
        static let cropVC = "crop_vc"
        static let settingsVC = "settings_vc"
    }
}
