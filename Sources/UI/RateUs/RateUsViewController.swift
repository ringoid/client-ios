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
    var onCancel: (() -> ())?
    var onRate:  (() -> ())?
    var onSuggest: (() -> ())?
    
    fileprivate var starsView: [UIImageView] = []
    fileprivate var rating: Int? = nil
    fileprivate var state: RateUsState = .initial
    
    @IBOutlet fileprivate weak var star1ImageView: UIImageView!
    @IBOutlet fileprivate weak var star2ImageView: UIImageView!
    @IBOutlet fileprivate weak var star3ImageView: UIImageView!
    @IBOutlet fileprivate weak var star4ImageView: UIImageView!
    @IBOutlet fileprivate weak var star5ImageView: UIImageView!
    @IBOutlet fileprivate weak var panelView: UIView!
    
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var feedbackLabel: UILabel!
    @IBOutlet fileprivate weak var cancelBtn: UIButton!
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
    
    override func updateLocale()
    {
        self.titleLabel.text = "rate_us_title".localized()
        self.feedbackLabel.text = "rate_us_feedback".localized()
        self.cancelBtn.setTitle("button_later".localized(), for: .normal)
        
        switch self.state {
        case .initial: self.reviewBtn.setTitle("rate_us_review".localized(), for: .normal)
        case .suggest: self.reviewBtn.setTitle("button_send".localized(), for: .normal)
        }
        
    }
    
    // MARK: - Actions
    
    @IBAction func notNowAction()
    {
        self.onCancel?()
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func rateAction()
    {
        self.dismiss(animated: false) { [weak self] in
            guard let `self` = self else { return }
            
            switch self.state {
            case .initial:
                self.onRate?()
                self.moveToAppstore()
                break
                
            case .suggest:
                self.onSuggest?()
                FeedbackManager.shared.send(self.textView.text, source: .chat, feedSource: .messages)
                break
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
        case .initial:
            self.hideSuggestInput()
            self.reviewBtn.setTitle("rate_us_review".localized(), for: .normal)
            break
            
        case .suggest:
            self.showSuggestInput()
            self.reviewBtn.setTitle("button_send".localized(), for: .normal)
            break
        }
    }
    
    fileprivate func showSuggestInput()
    {
        self.alertHeightConstraint.constant = 328.0
        self.midPositionConstraint.constant = -108.0
        self.textView.becomeFirstResponder()
        
        let animator = UIViewPropertyAnimator(duration: 0.35, curve: .easeOut) {
            self.feedbackLabel.alpha = 1.0
            self.textView.alpha = 1.0
            self.view.layoutSubviews()
        }
        
        animator.startAnimation()
    }
    
    fileprivate func hideSuggestInput()
    {
        self.alertHeightConstraint.constant = 220.0
        self.midPositionConstraint.constant = 0.0
        self.textView.resignFirstResponder()
        
        let animator = UIViewPropertyAnimator(duration: 0.35, curve: .easeOut) {
            self.textView.alpha = 0.0
            self.feedbackLabel.alpha = 0.0
            self.view.layoutSubviews()
        }
        animator.startAnimation()
    }
}
