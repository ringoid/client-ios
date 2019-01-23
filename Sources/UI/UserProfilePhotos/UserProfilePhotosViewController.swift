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
    
    fileprivate var viewModel: UserProfilePhotosViewModel?
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    fileprivate var pickerVC: UIViewController?
    fileprivate weak var pagesVC: UIPageViewController?
    fileprivate var photosVCs: [UIViewController] = []
    fileprivate var currentIndex: Int = 0
    
    @IBOutlet fileprivate weak var pageControl: UIPageControl!
    @IBOutlet fileprivate weak var deleteBtn: UIButton!
    
    override func viewDidLoad()
    {
        assert(input != nil)
        
        super.viewDidLoad()
        
        self.setupBindings()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        self.pickPhotoIfNeeded()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "embed_pages" {
            self.pagesVC = segue.destination as? UIPageViewController
            self.pagesVC?.delegate = self
            self.pagesVC?.dataSource = self
        }
    }
    
    fileprivate func pickPhotoIfNeeded()
    {
        guard self.input.profileManager.photos.value.count == 0 else { return }
        
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
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.viewModel = UserProfilePhotosViewModel(self.input)
        self.viewModel?.photos.asObservable().subscribe(onNext: { [weak self] photos in
            guard let `self` = self else { return }
            
            self.updatePages(startIndex: photos.count - 1)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func updatePages(startIndex: Int)
    {
        guard let photos = self.viewModel?.photos.value else { return }
        guard startIndex >= 0, startIndex < photos.count else { return }
        
        self.pageControl.numberOfPages = photos.count
        self.photosVCs = photos.map({ photo in
            let vc = UserProfilePhotoViewController.create()
            vc.photo = photo
            
            return vc
        })
        
        let vc = self.photosVCs[startIndex]
        let direction: UIPageViewController.NavigationDirection = (photos.count - 1) == startIndex ? .reverse : .forward
        self.pagesVC?.setViewControllers([vc], direction: direction, animated: false, completion: nil)
        self.currentIndex = startIndex
        self.pageControl.currentPage = startIndex
        self.deleteBtn.isHidden = photos.count == 0
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
}

extension UserProfilePhotosViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        guard let cropRect = info[.cropRect] as? CGRect, let image = info[.originalImage] as? UIImage else { return }
        guard let croppedImage = image.crop(rect: cropRect) else { return }
        
        self.viewModel?.add(croppedImage).subscribe(onNext: ({ [weak self] in
            
        }), onError: ({ [weak self] error in
            guard let `self` = self else { return }
            
            showError(error, vc: self)
        })).disposed(by: self.disposeBag)
        
        picker.dismiss(animated: true, completion: nil)
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
        self.pageControl.currentPage = index
    }
}
