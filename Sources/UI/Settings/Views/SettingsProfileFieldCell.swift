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
    
    func setupInput()
    {
        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        self.valueField.inputView = picker
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
        case .height: return 0
        case .hair: return Hair.count()
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        guard let type = self.field?.fieldType else { return nil }
        
        switch type {
        case .height: return nil
        case .hair: return Hair(rawValue: row * 10)?.title(self.sex).localized()
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        guard let type = self.field?.fieldType else { return }
        
        switch type {
        case .height: return
        case .hair:
            self.valueField.text = Hair(rawValue: row * 10)?.title(self.sex).localized()
            break
        }
    }
}
