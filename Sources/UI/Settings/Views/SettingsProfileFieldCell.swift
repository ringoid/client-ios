//
//  SettingsProfileFieldCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 22/06/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class SettingsProfileFieldCell: BaseTableViewCell
{
    var field: ProfileField?
    {
        didSet {
            self.update()
        }
    }
    
    var sex: Sex = .female
    {
        didSet {
            self.setupInput()
        }
    }
    
    var onSelect: ((ProfileFieldType, Int?, String?) -> ())?
    
    @IBOutlet fileprivate weak var iconView: UIImageView!
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var valueField: UITextField!
    
    override func updateTheme()
    {
        self.titleLabel.textColor = ContentColor().uiColor()
        self.tintColor = ContentColor().uiColor()
    }
    
    override func updateLocale()
    {
        self.titleLabel.text = "profile_field_height".localized()
    }
    
    func startEditing()
    {
        self.valueField?.becomeFirstResponder()
    }
    
    @objc func stopEditing()
    {
        self.valueField?.resignFirstResponder()
    }
    
    func setupInput()
    {
        let width = UIScreen.main.bounds.width
        let optionsView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: width, height: 44.0))
        optionsView.backgroundColor = .white
        let selectBtn = UIButton(frame: CGRect(x: width - 100.0, y: 0, width: 100.0, height: 44.0))
        selectBtn.setTitle("button_select".localized(), for: .normal)
        selectBtn.setTitleColor(.blue, for: .normal)
        selectBtn.addTarget(self, action: #selector(stopEditing), for: .touchUpInside)
        optionsView.addSubview(selectBtn)
        
        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        picker.backgroundColor = .white
        self.valueField.inputView = picker
        self.valueField.inputAccessoryView = optionsView
    }
    
    // MARK: -
    
    fileprivate func update()
    {
        guard let field = self.field else { return }
        
        self.titleLabel.text = field.title.localized()
        self.iconView.image = UIImage(named: field.icon)
        self.valueField.placeholder = field.placeholder.localized()
        
        self.setupInput()
    }
}

extension SettingsProfileFieldCell: UIPickerViewDataSource, UIPickerViewDelegate
{
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        guard let type = self.field?.fieldType else { return 0}
        
        switch type {
        case .height: return Height.count()
        case .hair: return Hair.count()
        case .educationLevel: return EducationLevel.count(LocaleManager.shared.language.value)
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        guard let type = self.field?.fieldType else { return nil }
        
        switch type {
        case .height: return Height.title(row)
        case .hair: return Hair(rawValue: row * 10)?.title(self.sex).localized()
        case .educationLevel: return EducationLevel.at(row, locale: LocaleManager.shared.language.value).title().localized()
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        guard let type = self.field?.fieldType else { return }
        
        switch type {
        case .height:
            self.valueField.text = Height.title(row)
            
        case .hair:
            self.valueField.text = Hair(rawValue: row * 10)?.title(self.sex).localized()
            break
            
        case .educationLevel:
            self.valueField.text = EducationLevel.at(row, locale: LocaleManager.shared.language.value).title().localized()
            break
        }
        
        self.onSelect?(type, row, nil)
    }
}
