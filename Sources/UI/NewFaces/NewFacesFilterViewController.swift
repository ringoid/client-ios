//
//  NewFacesFilterViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 19/07/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxCocoa
import RxSwift

class NewFacesFilterViewController: BaseViewController
{
    var input: NewFacesFilterVMInput!
    var onClose: ( (Bool) -> ())?
    
    fileprivate var viewModel: NewFacesFilterViewModel!
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
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        self.viewModel = NewFacesFilterViewModel(self.input)
        
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
        
        // Distance
        self.distanceSlider.setThumbImage(UIImage(named: "feed_slider_handle"), for: .normal)
        self.distanceSlider.value = Float(self.viewModel.maxDistance.value ?? 350)
        
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
        self.filtersAreaOffsetConstraint.constant = -height
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        self.filtersAreaOffsetConstraint.constant = 0.0
        UIView.animate(withDuration: 0.2) {
            self.view.layoutSubviews()
        }
    }
    
    override func updateTheme() {}
    
    // MARK: - Actionss
    
    @IBAction func onDiscoverAction()
    {
        let isUpdated = self.prevMinAge != self.viewModel?.minAge.value ||
            self.prevMaxAge != self.viewModel?.maxAge.value ||
            self.prevMaxDistance != self.viewModel?.maxDistance.value
        
        let height = self.view.safeAreaInsets.top + 245.0
        self.filtersAreaOffsetConstraint.constant = -height
        UIView.animate(withDuration: 0.2, animations: {
            self.view.layoutSubviews()
        }) { _ in
            self.onClose?(isUpdated)
        }
    }
    
    @objc fileprivate func onCloseAction(_ recognizer: UIGestureRecognizer)
    {
        guard !self.filtersView.frame.contains(recognizer.location(in: self.view)) else { return }
        
        let isUpdated = self.prevMinAge != self.viewModel?.minAge.value ||
            self.prevMaxAge != self.viewModel?.maxAge.value ||
            self.prevMaxDistance != self.viewModel?.maxDistance.value
        
        let height = self.view.safeAreaInsets.top + 245.0
        self.filtersAreaOffsetConstraint.constant = -height
        UIView.animate(withDuration: 0.2, animations: {
            self.view.layoutSubviews()
        }) { _ in
            self.onClose?(isUpdated)
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

extension NewFacesFilterViewController: RangeSeekSliderDelegate
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
