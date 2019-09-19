//
//  RateUsViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 19/09/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class RateUsViewController: BaseViewController
{
    @IBOutlet fileprivate weak var star1ImageView: UIImageView!
    @IBOutlet fileprivate weak var star2ImageView: UIImageView!
    @IBOutlet fileprivate weak var star3ImageView: UIImageView!
    @IBOutlet fileprivate weak var star4ImageView: UIImageView!
    @IBOutlet fileprivate weak var star5ImageView: UIImageView!
    @IBOutlet fileprivate weak var panelView: UIView!
    
    var starsView: [UIImageView] = []
    var rating: Int? = nil
    
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
    }
    
    override func updateTheme() {}
    
    // MARK: - Actions
    
    @IBAction func notNowAction()
    {
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func rateAction()
    {
        self.moveToAppstore()
    }
    
    @IBAction func tapAction(_ recognizer: UITapGestureRecognizer)
    {
        guard let barView = recognizer.view else { return }
        
        let location = recognizer.location(in: barView)
        let width = self.panelView.bounds.width
        let index = Int(location.x / (width / 5.0))
        self.rating = index + 1
        
        self.updateStars(index)
    }
    
    @IBAction func panAction(_ recognizer: UIPanGestureRecognizer)
    {
        guard let barView = recognizer.view else { return }
        
        let location = recognizer.location(in: barView)
        let width = self.panelView.bounds.width
        let index = Int(location.x / (width / 5.0))
        self.rating = index + 1
        
        self.updateStars(index)
    }
    
    // MARK: -
    
    fileprivate func moveToAppstore()
    {
        let urlStr = "https://itunes.apple.com/app/id1453136158?action=write-review"
        guard let writeReviewURL = URL(string: urlStr) else { return }
        
        UIApplication.shared.open(writeReviewURL)
    }
    
    fileprivate func updateStars(_ index: Int)
    {
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
}
