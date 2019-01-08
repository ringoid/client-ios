//
//  UserProfilePhotosViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 07/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import Photos

class UserProfilePhotosViewController: UIViewController
{
    var input: UserProfilePhotosVCInput!
    
    fileprivate var viewModel: UserProfilePhotosViewModel?
    
    override func viewDidLoad()
    {
        assert(input != nil)
        
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        self.setupBindings()
        self.pickPhotoIfNeeded()
    }
    
    fileprivate func pickPhotoIfNeeded()
    {
        guard self.input.profileManager.photos.value.count == 0 else { return }
        
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
        }
        
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.allowsEditing = true
        vc.delegate = self
        
        self.present(vc, animated: true, completion: nil)
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.viewModel = UserProfilePhotosViewModel(self.input)
    }
}

extension UserProfilePhotosViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        defer {
            picker.dismiss(animated: true, completion: nil)
        }
        
        guard let cropRect = info[.cropRect] as? CGRect, let image = info[.originalImage] as? UIImage else { return }
        guard let croppedImage = image.crop(rect: cropRect) else { return }
        
        self.viewModel?.add(croppedImage)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        picker.dismiss(animated: true, completion: nil)
    }
}
