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
    @IBOutlet fileprivate weak var pageControl: UIPageControl!
    @IBOutlet fileprivate weak var deleteBtn: UIButton!
    @IBOutlet fileprivate weak var optionsBtn: UIButton!
    @IBOutlet fileprivate weak var addBtn: UIButton!
    @IBOutlet fileprivate weak var containerTableView: UITableView!
    
    override func viewDidLoad()
    {
        assert(input != nil)
        
        super.viewDidLoad()
        
        let height = UIScreen.main.bounds.width * AppConfig.photoRatio
        self.containerTableView.rowHeight = height
        self.containerTableView.contentInset = UIEdgeInsets(top: 56.0, left: 0.0, bottom: 0.0, right: 0.0)
        self.containerTableView.reloadData()
        
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
        if segue.identifier == SegueIds.settingsVC,
            let vc = (segue.destination as? UINavigationController)?.viewControllers.first as? SettingsViewController {
            vc.input = SettingsVMInput(
                settingsManager: self.input.settingsManager,
                actionsManager: self.input.actionsManager,
                errorsManager: self.input.errorsManager,
                device: self.input.device
            )
        }
        
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
    
    @objc func reload()
    {
        self.containerTableView.panGestureRecognizer.isEnabled = false
        
        // No internet
        guard self.input.actionsManager.checkConnectionState() else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                self.containerTableView.refreshControl?.endRefreshing()
            })
        
            self.containerTableView.panGestureRecognizer.isEnabled = true
            
            return
        }
        
        self.viewModel?.refresh().subscribe(
            onError:{ [weak self] error in
                guard let `self` = self else { return }
                
                self.containerTableView.panGestureRecognizer.isEnabled = true
                showError(error, vc: self)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                    self.containerTableView.refreshControl?.endRefreshing()
                })
            }, onCompleted:{ [weak self] in
                self?.containerTableView.panGestureRecognizer.isEnabled = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                    self?.containerTableView.refreshControl?.endRefreshing()
                })
        }).disposed(by: self.disposeBag)
    }
    
    // MARK: - Actions
    
    @IBAction func addPhoto()
    {
        guard self.input.actionsManager.checkConnectionState() else { return }
        
        self.pickPhoto()
    }
    
    @IBAction func deletePhoto()
    {
        guard self.input.actionsManager.checkConnectionState() else { return }
        
        self.showDeletionAlert()
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.viewModel = UserProfilePhotosViewModel(self.input)
        self.viewModel?.photos.asObservable().subscribe(onNext: { [weak self] photos in
            guard let `self` = self else { return }
            
            self.updatePages()
            
            if self.viewModel?.isBlocked.value == true && self.isViewShown {
                self.viewModel?.isBlocked.accept(false)
                self.showBlockedAlert()
            }
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func setupReloader()
    {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(reload), for: .valueChanged)
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
            self.viewModel?.lastPhotoId.accept(photos.first?.id)
        }
        
        self.emptyFeedLabel.isHidden = !photos.isEmpty
        self.pageControl.numberOfPages = photos.count
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
        self.pageControl.currentPage = startIndex
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
        self.pageControl.isHidden = false
        self.deleteBtn.isHidden = false
        self.optionsBtn.isHidden = false
        self.addBtn.isHidden = false
        self.titleLabel.isHidden = false
    }
    
    fileprivate func hideControls()
    {
        self.pageControl.isHidden = true
        self.deleteBtn.isHidden = true
        self.optionsBtn.isHidden = true
        self.addBtn.isHidden = true
        self.titleLabel.isHidden = true
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
        self.viewModel?.lastPhotoId.accept(self.viewModel?.photos.value[index].originId)
        self.pageControl.currentPage = index
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
