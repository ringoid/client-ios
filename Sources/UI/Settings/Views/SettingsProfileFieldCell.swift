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
    var sex: Sex = .female

    var valueIndex: Int? = nil
    {
        didSet {
            self.update()
            
            guard let type = self.field?.fieldType else { return }
            guard let index = self.valueIndex else { return }
            
            switch type {
            case .height:
                self.valueField.text = Height.title(index)
                
            case .hair:
                self.valueField.text = Hair(rawValue: index * 10)?.title(self.sex).localized()
                break
                
            case .educationLevel:
                self.valueField.text = EducationLevel.at(index, locale: LocaleManager.shared.language.value).title().localized()
                break
                
            case .education, .name: break
                
            }
            
            self.setupInput()
        }
    }
    
    var valueText: String?
    {
        didSet {
            self.update()
            
            guard let type = self.field?.fieldType else { return }
            guard let text = self.valueText else { return }
            
            switch type {
            case .height: break
            case .hair: break
            case .educationLevel: break
                
            case .education, .name:
                self.valueField.text = text
                break
            }
            
            self.valueField.inputAccessoryView = nil
            self.valueField.inputView = nil
        }
    }
    
    var onSelect: ((ProfileFieldType, Int?, String?) -> ())?
    
    @IBOutlet fileprivate weak var iconView: UIImageView!
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var valueField: UITextField!
    
    fileprivate weak var pickerView: UIPickerView!
    
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
        
        guard let type = self.field?.fieldType else { return }
        
        let index = self.pickerView.selectedRow(inComponent: 0)
        self.valueIndex = index
        
        self.onSelect?(type, index, nil)
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
        
        let cancelBtn = UIButton(frame: CGRect(x: 0.0, y: 0, width: 100.0, height: 44.0))
        cancelBtn.setTitle("button_cancel".localized(), for: .normal)
        cancelBtn.setTitleColor(.blue, for: .normal)
        cancelBtn.addTarget(self, action: #selector(cancelEditing), for: .touchUpInside)
        optionsView.addSubview(cancelBtn)
  
        self.valueField.inputView = self.createPicker()
        self.valueField.inputAccessoryView = optionsView
    }
    
    // MARK: - Actions
    
    @IBAction func onReturn()
    {
        self.valueField.resignFirstResponder()
        
        guard let type = self.field?.fieldType else { return }
        
        self.onSelect?(type, nil, self.valueField.text)
    }
    
    // MARK: -
    
    fileprivate func createPicker() -> UIPickerView
    {
        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        picker.backgroundColor = .white
        
        self.pickerView = picker
        
        return picker
    }
    
    fileprivate func update()
    {
        guard let field = self.field else { return }
        
        self.titleLabel.text = field.title.localized()
        self.iconView.image = UIImage(named: field.icon)
        self.valueField.placeholder = field.placeholder.localized()                
    }
    
    @objc fileprivate func cancelEditing()
    {
        self.valueField?.resignFirstResponder()
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
        case .education, .name: return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        guard let type = self.field?.fieldType else { return nil }
        
        switch type {
        case .height: return Height.title(row)
        case .hair: return Hair(rawValue: row * 10)?.title(self.sex).localized()
        case .educationLevel: return EducationLevel.at(row, locale: LocaleManager.shared.language.value).title().localized()
            
        case .education, .name: return nil
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {

    }
}
