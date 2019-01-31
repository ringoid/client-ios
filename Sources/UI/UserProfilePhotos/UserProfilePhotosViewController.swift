//
//  UserProfilePhotosViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 07/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import Photos
import RxSwift

class UserProfilePhotosViewController: ThemeViewController
{
    var input: UserProfilePhotosVCInput!
    var autopickEnabled: Bool = false
    
    fileprivate var viewModel: UserProfilePhotosViewModel?
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    fileprivate var pickerVC: UIViewController?
    fileprivate weak var pagesVC: UIPageViewController?
    fileprivate var photosVCs: [UIViewController] = []
    fileprivate var currentIndex: Int = 0
    fileprivate var currentPhotoId: String? = nil
    
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var emptyFeedView: UIView!
    @IBOutlet fileprivate weak var pageControl: UIPageControl!
    @IBOutlet fileprivate weak var deleteBtn: UIButton!
    @IBOutlet fileprivate weak var containerTableView: UITableView!
    fileprivate var refreshControl: UIRefreshControl!
    
    override func viewDidLoad()
    {
        assert(input != nil)
        
        super.viewDidLoad()
        
        self.containerTableView.reloadData()
        self.setupBindings()
        self.setupReloader()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        self.pickPhotoIfNeeded()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "settings_vc",
            let vc = (segue.destination as? UINavigationController)?.viewControllers.first as? SettingsViewController {
            vc.input = SettingsVMInput(settingsManager: self.input.settingsManager)
        }
    }
    
    fileprivate func pickPhotoIfNeeded()
    {
        guard self.input.profileManager.photos.value.count == 0, self.viewModel?.isFirstTime.value == true else { return }
        
        self.pickPhoto()
    }
    
    fileprivate func pickPhoto()
    {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
        }
        
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.allowsEditing = true
        vc.delegate = self
        
        self.present(vc, animated: true, completion: nil)
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
    
    @objc func onReload()
    {
        self.reload()
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
        self.refreshControl = UIRefreshControl()
        self.containerTableView.addSubview(self.refreshControl)
        self.refreshControl.addTarget(self, action: #selector(onReload), for: .valueChanged)
    }
    
    fileprivate func updatePages()
    {
        guard let photos = self.viewModel?.photos.value else { return }
        
        var startIndex = 0
        if let id = self.currentPhotoId
        {
            for (index, photo) in photos.enumerated() {
                if photo.id == id { startIndex = index }
            }
        } else {
            self.currentPhotoId = photos.first?.id
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
        }
        
        self.currentIndex = startIndex
        self.pageControl.currentPage = startIndex
        self.deleteBtn.isHidden = photos.isEmpty
    }
    
    fileprivate func showDeletionAlert()
    {
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertVC.addAction(UIAlertAction(title: "Delete Photo", style: .destructive, handler: ({ _ in
            guard let photo = self.viewModel?.photos.value[self.currentIndex] else { return }
            
            self.input.profileManager.deletePhoto(photo)
        })))
        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
    fileprivate func showOptionsAlert()
    {
        let alertVC = UIAlertController(title: "What do you want to do next?", message: nil, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "Discover users nearby", style: .default, handler: ({ [weak self] _ in
            self?.viewModel?.moveToSearch()
        })))
        
        alertVC.addAction(UIAlertAction(title: "Add another photo", style: .default, handler: ({ [weak self] _ in
            self?.pickPhoto()
        })))
        
        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
    fileprivate func reload()
    {
        self.viewModel?.refresh().subscribe(onError:{ [weak self] error in
            guard let `self` = self else { return }
            
            showError(error, vc: self)
            }, onCompleted:{ [weak self] in
                self?.refreshControl.endRefreshing()
        }).disposed(by: self.disposeBag)
    }
}

extension UserProfilePhotosViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        guard let cropRect = info[.cropRect] as? CGRect, let image = info[.originalImage] as? UIImage else { return }
        guard let croppedImage = image.crop(rect: cropRect) else { return }
        
        self.viewModel?.isFirstTime.accept(false)
        
        let prevCount = self.viewModel?.photos.value.count
        
        self.viewModel?.add(croppedImage).subscribe(onNext: ({ [weak self] photo in
            self?.currentPhotoId = photo.id
            
            guard prevCount == 0 else { return }
            
            DispatchQueue.main.async {
                self?.showOptionsAlert()
            }
        }), onError: ({ [weak self] error in
            guard let `self` = self else { return }
            
            showError(error, vc: self)
        })).disposed(by: self.disposeBag)
        
        picker.dismiss(animated: true, completion: nil)
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
        self.currentPhotoId = self.viewModel?.photos.value[index].id
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return self.containerTableView.bounds.width / 3.0 * 4.0
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
