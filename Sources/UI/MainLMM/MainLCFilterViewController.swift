//
//  MainLCFilterViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 23/07/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxCocoa
import RxSwift

class MainLCFilterViewController: BaseViewController
{
    var input: MainLCFilterVMInput!
    var onShowAll: (() -> ())?
    var onUpdate: ((Bool) -> ())?
    var onClose: (() -> ())?
    
    fileprivate var viewModel: MainLCFilterViewModel!
    fileprivate var prevMinAge: Int? = nil
    fileprivate var prevMaxAge: Int? = nil
    fileprivate var prevMaxDistance: Int? = nil
    
    @IBOutlet fileprivate weak var filtersView: UIView!
    @IBOutlet fileprivate weak var rangeSlider: RangeSeekSlider!
    @IBOutlet fileprivate weak var distanceSlider: UISlider!
    @IBOutlet fileprivate weak var distanceLabel: UILabel!
    @IBOutlet fileprivate weak var ageLabel: UILabel!
    @IBOutlet fileprivate weak var filtersAreaOffsetConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var filtersAreaHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet fileprivate weak var maxDistanceTitleLabel: UILabel!
    @IBOutlet fileprivate weak var ageTitleLabel: UILabel!
    @IBOutlet fileprivate weak var filterBtn: UIButton!
    @IBOutlet fileprivate weak var showAllBtn: UIButton!
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        self.viewModel = MainLCFilterViewModel(self.input)
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(onCloseAction))
        self.view.addGestureRecognizer(recognizer)
        
        let swipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(onCloseAction))
        swipeRecognizer.direction = .up
        self.view.addGestureRecognizer(swipeRecognizer)
        
        // Range
        self.prevMinAge = self.viewModel?.minAge.value
        self.prevMaxAge = self.viewModel?.maxAge.value
        self.prevMaxDistance = self.viewModel?.maxDistance.value
        
        self.rangeSlider.selectedMinValue = CGFloat(self.viewModel.minAge.value ?? 18)
        self.rangeSlider.selectedMaxValue = CGFloat(self.viewModel.maxAge.value ?? 55)
        self.rangeSlider.delegate = self
        
        var ageText: String = ""
        if let minAge = self.viewModel.minAge.value {
            ageText += "\(minAge)"
        } else {
            ageText += "18"
        }
        
        if let maxAge = self.viewModel.maxAge.value {
            ageText += " - \(maxAge)"
        } else {
            ageText += " - 55+"
        }
        
        self.ageLabel.text = ageText
        
        // Distance
        self.distanceSlider.setThumbImage(UIImage(named: "feed_slider_handle"), for: .normal)
        self.distanceSlider.value = Float(self.viewModel.maxDistance.value ?? 350)
        
        if let maxDistance = self.viewModel.maxDistance.value {
            self.distanceLabel.text = "\(maxDistance) km"
        } else {
            self.distanceLabel.text = "150+ km"
        }
        
        self.filtersView.layer.cornerRadius = 16.0
        self.filtersView.clipsToBounds = true
        self.filtersView.layer.maskedCorners = [
            .layerMinXMaxYCorner,
            .layerMaxXMaxYCorner
        ]
    }
    
    override func viewWillLayoutSubviews()
    {
        super.viewWillLayoutSubviews()
        
        let height = self.view.safeAreaInsets.top + 245.0
        self.filtersAreaHeightConstraint.constant = height
    }
    
    override func updateLocale()
    {
        self.ageTitleLabel.text = "filter_age".localized()
        self.maxDistanceTitleLabel.text = "filter_max_distance".localized()
        self.filterBtn.setTitle("filter_filter".localized(), for: .normal)
        self.showAllBtn.setTitle("filter_show_all".localized(), for: .normal)
    }
    
    override func updateTheme() {}
    
    // MARK: - Actionss
    
    @IBAction func onFilterAction()
    {
        self.onUpdate?(true)
        
        let height = self.view.safeAreaInsets.top + 245.0
        self.filtersAreaOffsetConstraint.constant = -height
        UIView.animate(withDuration: 0.2, animations: {
            self.view.layoutSubviews()
        }) { _ in
            self.onClose?()
        }
    }
    
    @IBAction func onShowAllAction()
    {
        self.onShowAll?()
        
        let height = self.view.safeAreaInsets.top + 245.0
        self.filtersAreaOffsetConstraint.constant = -height
        UIView.animate(withDuration: 0.2, animations: {
            self.view.layoutSubviews()
        }) { _ in
            self.onClose?()
        }
    }
    
    @objc fileprivate func onCloseAction(_ recognizer: UIGestureRecognizer)
    {
        guard !self.filtersView.frame.contains(recognizer.location(in: self.view)) else { return }
        
        let isUpdated = self.prevMinAge != self.viewModel?.minAge.value ||
            self.prevMaxAge != self.viewModel?.maxAge.value ||
            self.prevMaxDistance != self.viewModel?.maxDistance.value
        self.onUpdate?(isUpdated)
        
        let height = self.view.safeAreaInsets.top + 245.0
        self.filtersAreaOffsetConstraint.constant = -height
        UIView.animate(withDuration: 0.2, animations: {
            self.view.layoutSubviews()
        }) { _ in
            self.onClose?()
        }
    }
    
    @IBAction fileprivate func onDistanceChange(_ slider: UISlider)
    {
        let distanceValue = Int(slider.value)
        self.viewModel.maxDistance.accept(distanceValue < 150 ? distanceValue : nil)
        
        let distanceStr: String = distanceValue < 150 ? "\(distanceValue)" : "150+"
        self.distanceLabel.text = "\(distanceStr) km"
    }
}

extension MainLCFilterViewController: RangeSeekSliderDelegate
{
    func rangeSeekSlider(_ slider: RangeSeekSlider, didChange minValue: CGFloat, maxValue: CGFloat)
    {
        let minAgeValue = Int(minValue)
        let maxAgeValue = Int(maxValue)
        
        self.viewModel.minAge.accept(minAgeValue)
        self.viewModel.maxAge.accept(maxAgeValue < 55 ? maxAgeValue : nil)
        
        let maxAgeStr: String = maxAgeValue < 55 ? "\(maxAgeValue)" : "55+"
        self.ageLabel.text = "\(minAgeValue) - \(maxAgeStr)"
    }
}
