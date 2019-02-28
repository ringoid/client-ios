//
//  UserProfilePhotoCropViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 28/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

protocol UserProfilePhotoCropVCDelegate: class
{
    func cropVC(_ vc: UserProfilePhotoCropViewController, didCrop image: UIImage)
}

class UserProfilePhotoCropViewController: BaseViewController
{
    var sourceImage: UIImage?
    weak var delegate: UserProfilePhotoCropVCDelegate?
    
    fileprivate var contentImageView: UIImageView?
    
    @IBOutlet fileprivate weak var contentView: UIScrollView!
    @IBOutlet fileprivate weak var contentHeightConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var contentWidthConstraint: NSLayoutConstraint!
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.updateContent()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = true
    }

    @IBAction func onDone()
    {
        let contentViewSize = self.contentView.bounds.size
        let scale = self.contentView.zoomScale
        let scaledCropWidth: CGFloat = 336.0
        let scaledCropHeight: CGFloat = 336.0
        let scaledContentOffsetX = self.contentView.contentOffset.x
        let scaledContentOffsetY = self.contentView.contentOffset.y
        let scaledCropOffsetX = (contentViewSize.width - scaledCropWidth) / 2.0 + scaledContentOffsetX
        let scaledCropOffsetY = (contentViewSize.height - scaledCropHeight) / 2.0 + scaledContentOffsetY
        
        let cropRect = CGRect(
            x: scaledCropOffsetX / scale,
            y: scaledCropOffsetY /  scale,
            width: scaledCropWidth / scale,
            height: scaledCropHeight / scale
        )
        
        guard let croppedImage = self.sourceImage?.crop(rect: cropRect) else {
            self.dismiss(animated: true, completion: nil)
            return
        }
        
        self.delegate?.cropVC(self, didCrop: croppedImage)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onBack()
    {
        self.contentView.isHidden = true
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: -
    
    fileprivate func updateContent()
    {
        guard let image = self.sourceImage else {
            self.contentImageView?.removeFromSuperview()
            self.contentImageView = nil
            
            return
        }
        
        let imageView = UIImageView(image: image)
        self.contentImageView = imageView
        self.contentView?.addSubview(imageView)
        
        let size = image.size
        let boundsSize = self.view.bounds.size
        let photoAreaSize = boundsSize.width * 0.9
        let smallerSize = min(size.width, size.height)
        let defaultScale = boundsSize.width / smallerSize
        let minScale = photoAreaSize / smallerSize
        let maxScale = defaultScale * 3.0
        
        let contentViewHeight = size.height * minScale
        let contentViewWidth = size.width * minScale
        
        let contentInsetX = (size.width - smallerSize) * minScale / 2.0
        let contentInsetY = (size.height - smallerSize) * minScale / 2.0
        
        self.contentHeightConstraint.constant = contentViewHeight
        self.contentWidthConstraint.constant = contentViewWidth
        
        self.contentView.minimumZoomScale = minScale
        self.contentView.maximumZoomScale = maxScale
        self.contentView.contentSize = size
        self.contentView.contentInset = UIEdgeInsets(top: contentInsetY, left: contentInsetX, bottom: contentInsetY, right: contentInsetX)
        self.contentView.setZoomScale(defaultScale, animated: false)
        let initialCenterOffset = CGPoint(
            x: (self.contentView.contentSize.width - contentViewWidth) / 2.0,
            y: (self.contentView.contentSize.height - contentViewHeight) / 2.0
        )
        self.contentView.setContentOffset(initialCenterOffset, animated: false)
    }
}

extension UserProfilePhotoCropViewController: UIScrollViewDelegate
{
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.contentImageView
    }
}
