//
//  SettingsFilterViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 24/07/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxCocoa
import RxSwift

class SettingsFilterViewController: BaseViewController
{
    var input: SettingsFilterVMInput!

    fileprivate var viewModel: SettingsFilterViewModel!
    fileprivate var prevMinAge: Int? = nil
    fileprivate var prevMaxAge: Int? = nil
    fileprivate var prevMaxDistance: Int? = nil
    
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var backBtn: UIButton!
    @IBOutlet fileprivate weak var suggestLabel: UILabel!
    
    @IBOutlet fileprivate weak var rangeSlider: RangeSeekSlider!
    @IBOutlet fileprivate weak var distanceSlider: UISlider!
    @IBOutlet fileprivate weak var distanceLabel: UILabel!
    @IBOutlet fileprivate weak var ageLabel: UILabel!
    
    @IBOutlet fileprivate weak var maxDistanceTitleLabel: UILabel!
    @IBOutlet fileprivate weak var ageTitleLabel: UILabel!
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        self.viewModel = SettingsFilterViewModel(self.input)
        
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
    }

    override func updateLocale()
    {
        self.ageTitleLabel.text = "filter_age".localized()
        self.maxDistanceTitleLabel.text = "filter_max_distance".localized()
        self.titleLabel.text = "settings_filter".localized()
        self.suggestLabel.text = "feedback_suggest_improvements".localized()
    }
    
    override func updateTheme()
    {
        self.view.backgroundColor = BackgroundColor().uiColor()
        self.titleLabel.textColor = ContentColor().uiColor()
        self.backBtn.tintColor = ContentColor().uiColor()
    }
    
    // MARK: - Actions
    
    @IBAction func onBack()
    {
        self.updateFeedsIfNeed()
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction fileprivate func onDistanceChange(_ slider: UISlider)
    {
        let distanceValue = Int(slider.value)
        self.viewModel.maxDistance.accept(distanceValue < 150 ? distanceValue : nil)
        
        let distanceStr: String = distanceValue < 150 ? "\(distanceValue)" : "150+"
        self.distanceLabel.text = "\(distanceStr) km"
    }
    
    @IBAction fileprivate func onSuggest()
    {
        FeedbackManager.shared.showSuggestion(self, source: .filtersSettings, feedSource: nil)
    }
    
    // MARK: -
    
    fileprivate func updateFeedsIfNeed()
    {
        let isUpdated = self.prevMinAge != self.viewModel?.minAge.value ||
            self.prevMaxAge != self.viewModel?.maxAge.value ||
            self.prevMaxDistance != self.viewModel?.maxDistance.value
        
        guard isUpdated else { return }
        
        self.viewModel.updateFeeds()
    }
}

extension SettingsFilterViewController: RangeSeekSliderDelegate
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
