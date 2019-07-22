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
    var onClose: (() -> ())?
    
    fileprivate var viewModel: NewFacesFilterViewModel!
    
    @IBOutlet fileprivate weak var filtersView: UIView!
    @IBOutlet fileprivate weak var rangeSlider: RangeSeekSlider!
    @IBOutlet fileprivate weak var distanceSlider: UISlider!
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        self.viewModel = NewFacesFilterViewModel(self.input)
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(onCloseAction))
        self.view.addGestureRecognizer(recognizer)
        
        // Range
        self.rangeSlider.selectedMinValue = CGFloat(self.viewModel.minAge.value ?? 18)
        self.rangeSlider.selectedMaxValue = CGFloat(self.viewModel.maxAge.value ?? 55)
        self.rangeSlider.delegate = self
        
        // Distance
        self.distanceSlider.setThumbImage(UIImage(named: "feed_slider_handle"), for: .normal)
        self.distanceSlider.value = Float(self.viewModel.maxDistance.value ?? 350)
    }
    
    override func updateTheme() {}
    
    // MARK: - Actionss
    
    @objc fileprivate func onCloseAction(_ recognizer: UIGestureRecognizer)
    {
        guard !self.filtersView.frame.contains(recognizer.location(in: self.view)) else { return }
        
        self.onClose?()
    }
    
    @IBAction fileprivate func onDistanceChange(_ slider: UISlider)
    {
        self.viewModel.maxDistance.accept(Int(slider.value))
    }
}

extension NewFacesFilterViewController: RangeSeekSliderDelegate
{
    func rangeSeekSlider(_ slider: RangeSeekSlider, didChange minValue: CGFloat, maxValue: CGFloat)
    {
        self.viewModel.minAge.accept(Int(minValue))
        self.viewModel.maxAge.accept(Int(maxValue))
    }
}
