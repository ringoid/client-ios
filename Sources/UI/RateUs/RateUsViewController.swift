//
//  RateUsViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 19/09/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

fileprivate enum RateUsState
{
    case initial;
    case suggest;
}

class RateUsViewController: BaseViewController
{
    var onLowRate: (() -> ())?
    
    fileprivate var starsView: [UIImageView] = []
    fileprivate var rating: Int? = nil
    fileprivate var state: RateUsState = .initial
    
    @IBOutlet fileprivate weak var star1ImageView: UIImageView!
    @IBOutlet fileprivate weak var star2ImageView: UIImageView!
    @IBOutlet fileprivate weak var star3ImageView: UIImageView!
    @IBOutlet fileprivate weak var star4ImageView: UIImageView!
    @IBOutlet fileprivate weak var star5ImageView: UIImageView!
    @IBOutlet fileprivate weak var panelView: UIView!
    @IBOutlet fileprivate weak var reviewBtn: UIButton!
    @IBOutlet fileprivate weak var textView: UITextView!
    
    // Constraints
    
    @IBOutlet fileprivate weak var midPositionConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var alertHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.starsView = [
            self.star1ImageView,
            self.star2ImageView,
            self.star3ImageView,
            self.star4ImageView,
            self.star5ImageView,
        ]
        
        self.textView.layer.borderColor = UIColor.lightGray.cgColor
        self.textView.layer.borderWidth = 1.0
        self.textView.layer.cornerRadius = 4.0
    }
    
    override func updateTheme() {}
    
    // MARK: - Actions
    
    @IBAction func notNowAction()
    {
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func rateAction()
    {
        self.dismiss(animated: false) { [weak self] in
            guard let `self` = self else { return }
            guard let rating = self.rating else { return }
            
            if rating > 3 {
                self.moveToAppstore()
            } else {
                self.onLowRate?()
            }
        }
    }
    
    @IBAction func tapAction(_ recognizer: UITapGestureRecognizer)
    {
        guard let barView = recognizer.view else { return }
        
        let location = recognizer.location(in: barView)
        let width = self.panelView.bounds.width
        let index = Int(location.x / (width / 5.0))
        
        self.updateStars(index)
        self.updateState(index + 1)
    }
    
    @IBAction func panAction(_ recognizer: UIPanGestureRecognizer)
    {
        guard let barView = recognizer.view else { return }
        
        let location = recognizer.location(in: barView)
        let width = self.panelView.bounds.width
        let index = Int(location.x / (width / 5.0))
        
        self.updateStars(index)
        
        guard recognizer.state == .ended || recognizer.state == .cancelled else { return }
        
        self.updateState(index + 1)
    }
    
    // MARK: -
    
    fileprivate func updateState(_ rating: Int)
    {
        if rating < 4 {
            self.toggle(.suggest)
        } else {
            self.toggle(.initial)
        }
    }
    
    fileprivate func moveToAppstore()
    {
        let urlStr = "https://itunes.apple.com/app/id1453136158?action=write-review"
        guard let writeReviewURL = URL(string: urlStr) else { return }
        
        UIApplication.shared.open(writeReviewURL)
    }
    
    fileprivate func updateStars(_ index: Int)
    {
        guard self.rating != index + 1 else { return }
        
        self.rating = index + 1
        
        self.reviewBtn.isEnabled = true
        
        let emptyStarImage = UIImage(named: "rate_us_star_empty")
        let selectedStarImage = UIImage(named: "rate_us_star_selected")
        
        for (i, starView) in self.starsView.enumerated() {
            if i <= index {
                starView.image = selectedStarImage
            } else {
                starView.image = emptyStarImage
            }
        }
    }
    
    fileprivate func toggle(_ state: RateUsState)
    {
        guard self.state != state else { return }
        
        self.state = state
        
        switch state {
        case .initial: self.hideSuggestInput()
        case .suggest: self.showSuggestInput()
        }
    }
    
    fileprivate func showSuggestInput()
    {
        self.alertHeightConstraint.constant = 300.0
        self.midPositionConstraint.constant = -108.0
        self.textView.becomeFirstResponder()
        
        let animator = UIViewPropertyAnimator(duration: 0.35, curve: .easeOut) {
            self.textView.alpha = 1.0
            self.view.layoutSubviews()
        }
        
        animator.startAnimation()
    }
    
    fileprivate func hideSuggestInput()
    {
        self.alertHeightConstraint.constant = 192.0
        self.midPositionConstraint.constant = 0.0
        self.textView.resignFirstResponder()
        
        let animator = UIViewPropertyAnimator(duration: 0.35, curve: .easeOut) {
            self.textView.alpha = 0.0
            self.view.layoutSubviews()
        }
        animator.startAnimation()
    }
}
