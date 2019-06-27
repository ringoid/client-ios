//
//  UserProfilePhotosViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 07/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import RxSwift
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
    fileprivate var currentIndex: Int = 0
    fileprivate var lastClientPhotoId: String? = nil
    fileprivate let preheater = ImagePreheater(destination: .diskCache)
    fileprivate var pickedPhoto: UIImage?
    fileprivate var isViewShown: Bool = false
    
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
    @IBOutlet fileprivate weak var lmmLabel: UILabel!
    @IBOutlet fileprivate weak var lmmWidthConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var lmmIconView: UIImageView!
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
    
    override func viewDidLoad()
    {
        assert(input != nil)
        
        super.viewDidLoad()
        
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
            db: self.input.db
        )
        
        ModalUIManager.shared.show(navVC, animated: true)
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
            }
            
            self.updatePages()
            self.updateLmmCounter()
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
        
        self.viewModel?.lmmCount.asObservable().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] value in
            self?.updateLmmCounter()
        }).disposed(by: self.disposeBag)
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
            
            return vc
        })
        
        if !photos.isEmpty {
            let vc = self.photosVCs[startIndex]
            let direction: UIPageViewController.NavigationDirection = (photos.count - 1) == startIndex ? .reverse : .forward
            self.pagesVC?.setViewControllers([vc], direction: direction, animated: false, completion: nil)
        } else {
            self.pagesVC?.setViewControllers([UIViewController()], direction: .forward, animated: false, completion: nil)
        }
        
        self.currentIndex = startIndex
        self.pagesControl.numberOfPages = photos.count
        self.pagesControl.currentPage = startIndex
        self.deleteBtn.isHidden = photos.isEmpty
    }
    
    fileprivate func showDeletionAlert()
    {
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertVC.addAction(UIAlertAction(title: "profile_button_delete_image".localized(), style: .destructive, handler: ({ _ in
            guard let photo = self.viewModel?.photos.value[self.currentIndex] else { return }
            
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
    
    fileprivate func showDeletionConfirmationAlert()
    {
        let alertVC = UIAlertController(
            title: "profile_dialog_image_delete_title".localized(),
            message: "common_uncancellable".localized(),
            preferredStyle: .alert
        )
        alertVC.addAction(UIAlertAction(title: "profile_button_delete_image".localized(), style: .default, handler: ({ _ in
            guard let photo = self.viewModel?.photos.value[self.currentIndex] else { return }
            
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
        self.lmmLabel.alpha = 1.0
        self.lmmIconView.alpha = 1.0
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
        self.lmmLabel.alpha = 0.0
        self.lmmIconView.alpha = 0.0
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
    
    fileprivate func updateLmmCounter()
    {
        guard let lmmCount = self.viewModel?.lmmCount.value else { return }
        guard let photosCount = self.viewModel?.photos.value.count else { return }
        
        if lmmCount > 0 && photosCount > 0 {
            let valueStr = "\(lmmCount)"
            self.lmmLabel.text = valueStr
            self.lmmWidthConstraint.constant = (valueStr as NSString).boundingRect(
                with: CGSize(width: 300.0, height: 14.0),
                options: .usesLineFragmentOrigin,
                attributes: [.font: self.lmmLabel.font],
                context: nil
                ).width + 7.0
            
            self.lmmIconView.isHidden = false
            self.lmmLabel.isHidden = false
        } else {
            self.lmmIconView.isHidden = true
            self.lmmLabel.isHidden = true
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
        
        self.currentIndex = index
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
