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
    fileprivate let preheater = ImagePreheater()
    
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var emptyFeedView: UIView!
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
        self.containerTableView.reloadData()
        
        self.setupBindings()
        self.setupReloader()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        self.pickPhotoIfNeeded()
        
        guard let photos = self.viewModel?.photos.value else { return }
        
        self.preheater.startPreheating(with: photos.map({ $0.filepath().url() }))        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "settings_vc",
            let vc = (segue.destination as? UINavigationController)?.viewControllers.first as? SettingsViewController {
            vc.input = SettingsVMInput(settingsManager: self.input.settingsManager)
        }
    }
    
    override func updateTheme()
    {
        self.view.backgroundColor = BackgroundColor().uiColor()
    }
    
    func showPhotoPicker()
    {
        self.pickPhoto()
    }
    
    @objc func reload()
    {
        MainLMMViewController.resetStates() // TODO: Think about more elegant solution to reset offset caches
        
        self.viewModel?.refresh().subscribe(onError:{ [weak self] error in
            guard let `self` = self else { return }
            
            self.containerTableView.refreshControl?.endRefreshing()
            showError(error, vc: self)
            }, onCompleted:{ [weak self] in
                self?.containerTableView.refreshControl?.endRefreshing()
        }).disposed(by: self.disposeBag)
    }
    
    // MARK: - Actions
    
    @IBAction func addPhoto()
    {
        self.pickPhoto()
    }
    
    @IBAction func deletePhoto()
    {
        self.showDeletionAlert()
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.viewModel = UserProfilePhotosViewModel(self.input)
        self.viewModel?.photos.asObservable().subscribe(onNext: { [weak self] photos in
            guard let `self` = self else { return }
            
            self.updatePages()
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func setupReloader()
    {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(reload), for: .valueChanged)
        self.containerTableView.refreshControl = refreshControl
    }
    
    fileprivate func pickPhotoIfNeeded()
    {
        guard
            self.input.profileManager.photos.value.count == 0,
            self.viewModel?.isFirstTime.value == true,
            self.viewModel?.isAuthorized.value == true
            else { return }
        
        self.pickPhoto()
    }
    
    fileprivate func pickPhoto()
    {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.allowsEditing = true
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
        
        self.emptyFeedView.isHidden = !photos.isEmpty
        self.titleLabel.isHidden = !photos.isEmpty
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
        alertVC.addAction(UIAlertAction(title: "PROFILE_DELETE_PHOTO".localized(), style: .destructive, handler: ({ _ in
            self.showControls()
            
            guard let photo = self.viewModel?.photos.value[self.currentIndex] else { return }
            
            self.viewModel?.delete(photo)
        })))
        alertVC.addAction(UIAlertAction(title: "COMMON_CANCEL".localized(), style: .cancel, handler: { _ in
            self.showControls()
        }))
        
        self.hideControls()
        self.present(alertVC, animated: true, completion: nil)
    }
    
    fileprivate func showOptionsAlert()
    {
        let alertVC = UIAlertController(title: "PROFILE_ADD_ALERT_TITLE".localized(), message: nil, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "PROFILE_ADD_PHOTO".localized(), style: .default, handler: ({ [weak self] _ in
            self?.pickPhoto()
        })))
        alertVC.addAction(UIAlertAction(title: "PROFILE_DISCOVER_USERS".localized(), style: .default, handler: ({ [weak self] _ in
            self?.viewModel?.isFirstTime.accept(false)
            self?.viewModel?.moveToSearch()
        })))
        
        alertVC.addAction(UIAlertAction(title: "COMMON_CLOSE".localized(), style: .cancel, handler: { [weak self] _ in
            self?.viewModel?.isFirstTime.accept(false)
        }))
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
    fileprivate func showControls()
    {
        self.pageControl.isHidden = false
        self.deleteBtn.isHidden = false
        self.optionsBtn.isHidden = false
        self.addBtn.isHidden = false
    }
    
    fileprivate func hideControls()
    {
        self.pageControl.isHidden = true
        self.deleteBtn.isHidden = true
        self.optionsBtn.isHidden = true
        self.addBtn.isHidden = true
    }
}

extension UserProfilePhotosViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        defer {
            picker.dismiss(animated: true, completion: nil)
        }
        
        guard let image = info[.editedImage] as? UIImage else { return }
        
        let size = image.size
        let width = size.width / 4.0 * 3.0
        let adjustedCropRect = CGRect(
            x: (size.width - width) / 2.0,
            y: 0.0,
            width: width,
            height: size.height
        )
        guard let croppedImage = image.crop(rect: adjustedCropRect) else { return }

        self.viewModel?.add(croppedImage).subscribe(onNext: ({ [weak self] photo in
            self?.viewModel?.lastPhotoId.accept(nil)
            self?.lastClientPhotoId = photo.clientId
            
            guard self?.viewModel?.isFirstTime.value == true else { return }
            
            DispatchQueue.main.async {
                self?.showOptionsAlert()
            }
        }), onError: ({ [weak self] error in
            guard let `self` = self else { return }
            
            showError(error, vc: self)
        })).disposed(by: self.disposeBag)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        self.viewModel?.isFirstTime.accept(false)
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
