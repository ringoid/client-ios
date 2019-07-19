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
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        self.viewModel = NewFacesFilterViewModel(self.input)
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(onCloseAction))
        self.view.addGestureRecognizer(recognizer)
        
        self.rangeSlider.delegate = self
    }
    
    override func updateTheme() {}
    
    // MARK: - Actionss
    
    @objc fileprivate func onCloseAction(_ recognizer: UIGestureRecognizer)
    {
        guard !self.filtersView.frame.contains(recognizer.location(in: self.view)) else { return }
        
        self.onClose?()
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
