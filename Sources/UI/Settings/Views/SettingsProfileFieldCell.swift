//
//  SettingsProfileFieldCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 22/06/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

fileprivate let pickerBackgroundColor = UIColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1.0)

class SettingsProfileFieldCell: BaseTableViewCell
{
    var field: ProfileField?
    {
        didSet {
            guard let type = field?.fieldType else { return }
            
            switch type {
            case .bio, .company, .education, .instagram, .job, .name, .tiktok, .whereLive, .status:
                self.setupTextPlaceholder()
                break
                
            case .children, .educationLevel, .hair, .income, .property, .height, .transport:
                self.setupValuePlaceholder()
                break
            }
        }
    }
    
    var sex: Sex = .female

    var valueIndex: Int? = nil
    {
        didSet {
            if self.valueIndex != nil { self.valueText = nil }
            
            self.update()
      
            guard let type = self.field?.fieldType else { return }
            guard let index = self.valueIndex else { return }
            
            defer {
                self.setupInput()
            }
            
            guard index != 0  else {
                self.valueField?.text = nil
                self.valueTextView?.text = nil
                
                return
            }
            
            switch type {
            case .height:
                self.valueField?.text = Height.title(index)
                break
                
            case .hair:
                self.valueField?.text = Hair(rawValue: index * 10)?.title(self.sex).localized()
                break
                
            case .educationLevel:
                self.valueField?.text = EducationLevel.at(index, locale: LocaleManager.shared.language.value).title().localized()
                break
                
            case .children:
                self.valueField?.text = Children.at(index).title().localized()
                break
                
            case .transport:
                self.valueField?.text = Transport.at(index).title().localized()
                break
                
            case .income:
                self.valueField?.text = Income.at(index).title().localized()
                break
                
            case .property:
                self.valueField?.text = Property.at(index).title().localized()
                break

            default: break
                
            }
        }
    }
    
    var valueText: String?
    {
        didSet {
            if self.valueText != nil { self.valueIndex = nil }
            
            self.update()
            
            guard let type = self.field?.fieldType else { return }
            guard let text = self.valueText else { return }
            
            switch type {
            case .education, .name, .instagram, .tiktok, .bio, .job, .whereLive, .company, .status:
                self.valueField?.text = text
                self.valueTextView?.text = text
                break
                
            default: break
            }
            
            self.valueField?.inputAccessoryView = nil
            self.valueField?.inputView = nil
        }
    }
    
    var defaultItemIndex: Int = 0
    var onSelect: ((ProfileFieldType, Int?, String?) -> ())?
    
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueField: UITextField?
    @IBOutlet weak var valueTextView: UITextView?
    
    fileprivate weak var pickerView: UIPickerView!
    fileprivate var prevIndexValue: Int? = nil
    fileprivate var prevTextValue: String? = nil
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        // Text field
        self.valueField?.layer.sublayerTransform = CATransform3DMakeTranslation(6.0, 0.0, 0.0)
        self.valueField?.layer.cornerRadius = 8.0
        self.valueField?.layer.borderColor = UIColor.darkGray.cgColor
        self.valueField?.layer.borderWidth = 1.0
        self.valueField?.clipsToBounds = true
        
        self.valueField?.delegate = self
        
        // Text view
        self.valueTextView?.layer.cornerRadius = 8.0
        self.valueTextView?.layer.borderColor = UIColor.darkGray.cgColor
        self.valueTextView?.layer.borderWidth = 1.0
        self.valueTextView?.clipsToBounds = true
        
        self.valueTextView?.delegate = self
    }
    
    override func prepareForReuse()
    {
        super.prepareForReuse()
        
        self.valueField?.text = nil
        self.valueTextView?.text = nil
    }
    
    override func updateTheme()
    {
        self.tintColor = ContentColor().uiColor()
    }
    
    override func updateLocale()
    {
        self.titleLabel.text = self.field?.title.localized()
    }
    
    func startEditing()
    {
        self.valueField?.becomeFirstResponder()
        self.valueTextView?.becomeFirstResponder()
    }
    
    func startEditingWithSelection()
    {
        self.valueField?.becomeFirstResponder()
        self.valueTextView?.becomeFirstResponder()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.valueField?.selectAll(nil)
            self.valueTextView?.selectAll(nil)
        }
    }
    
    @objc func stopEditing()
    {
        self.valueField?.resignFirstResponder()
        self.valueTextView?.resignFirstResponder()
        
        guard let type = self.field?.fieldType else { return }
        
        let row = self.pickerView.selectedRow(inComponent: 0)
        self.valueIndex = row
        
        self.onSelect?(type, row, nil)
    }
    
    func resetInput()
    {
        self.valueField?.inputView = nil
        self.valueField?.inputAccessoryView = nil
    }
    
    fileprivate func setupInput()
    {
        let width = UIScreen.main.bounds.width
        let optionsView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: width, height: 44.0))
        optionsView.backgroundColor = pickerBackgroundColor
        
        let selectBtn = UIButton(frame: CGRect(x: width - 100.0, y: 0, width: 100.0, height: 44.0))
        selectBtn.setTitle("button_select".localized(), for: .normal)
        selectBtn.setTitleColor(.white, for: .normal)
        selectBtn.addTarget(self, action: #selector(stopEditing), for: .touchUpInside)
        optionsView.addSubview(selectBtn)
        
        let cancelBtn = UIButton(frame: CGRect(x: 0.0, y: 0, width: 100.0, height: 44.0))
        cancelBtn.setTitle("button_cancel".localized(), for: .normal)
        cancelBtn.setTitleColor(.white, for: .normal)
        cancelBtn.addTarget(self, action: #selector(cancelEditing), for: .touchUpInside)
        optionsView.addSubview(cancelBtn)
  
        self.valueField?.inputView = self.createPicker()
        self.valueField?.inputAccessoryView = optionsView
    }
    
    // MARK: - Actions
    
    @IBAction func onReturn()
    {
        self.valueField?.resignFirstResponder()
    }
    
    // MARK: -
    
    fileprivate func createPicker() -> UIPickerView
    {
        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        picker.backgroundColor = pickerBackgroundColor
        
        if let index = self.valueIndex, index != 0 {
            picker.selectRow(index, inComponent: 0, animated: false)
        } else {
            picker.selectRow(self.defaultItemIndex, inComponent: 0, animated: false)
        }
        
        self.pickerView = picker
        
        return picker
    }
    
    fileprivate func update()
    {
        guard let field = self.field else { return }
        
        self.titleLabel.text = field.title.localized()
        
        if let icon = field.icon {
            self.iconView.image = UIImage(named: icon)
        } else {
            self.iconView.image = nil
        }
    }
    
    @objc fileprivate func cancelEditing()
    {
        self.valueField?.resignFirstResponder()
        self.valueTextView?.resignFirstResponder()
        
        if let index = self.prevIndexValue {
            self.valueIndex = index
        }
        
        if let text = self.prevTextValue {
            self.valueText = text
        }
    }
    
    fileprivate func setupTextPlaceholder()
    {
        
        if let placeholderText = self.field?.placeholder?.localized() {
            self.valueField?.attributedPlaceholder = NSAttributedString(string: placeholderText,  attributes: [
                .foregroundColor: UIColor.lightGray
                ])
        } else {
            self.valueField?.attributedPlaceholder = nil
        }
    }
    
    fileprivate func setupValuePlaceholder()
    {
        self.valueField?.attributedPlaceholder = NSAttributedString(string: "profile_field_not_selected".localized(),
                                                                    attributes: [
                                                                        .foregroundColor: UIColor.lightGray
            ])
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
        case .children: return Children.count()
        case .income: return Income.count()
        case .property: return Property.count()
        case .transport: return Transport.count()
       
        default: return 0
        }
    }

    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        
        guard let type = self.field?.fieldType else { return nil }
        var title: String = ""
        
        switch type {
        case .height: title = Height.title(row); break
        case .hair: title = Hair(rawValue: row * 10)?.title(self.sex).localized() ?? ""; break
        case .educationLevel: title = EducationLevel.at(row, locale: LocaleManager.shared.language.value).title().localized(); break
        case .children: title = Children.at(row).title().localized(); break
        case .property: title = Property.at(row).title().localized(); break
        case .income: title = Income.at(row).title().localized(); break
        case .transport: title = Transport.at(row).title().localized(); break
            
        default: return nil
        }
        
        return NSAttributedString(string: title, attributes: [
            .foregroundColor: UIColor.white
            ])
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        guard let type = self.field?.fieldType else { return }
        
        self.valueIndex = row
        
        self.onSelect?(type, row, nil)
    }
}

extension SettingsProfileFieldCell: UITextFieldDelegate
{
    func textFieldDidBeginEditing(_ textField: UITextField)
    {
        self.prevIndexValue = self.valueIndex
        self.prevTextValue = self.valueText
    }
    
    func textFieldDidEndEditing(_ textField: UITextField)
    {
        guard self.valueIndex == nil else { return }
        guard let type = self.field?.fieldType else { return }
        
        let text = textField.text?.trimContent()
        self.valueText = textField.text?.trimContent()
        self.onSelect?(type, nil, text)
    }
}

extension SettingsProfileFieldCell: UITextViewDelegate
{
    func textViewDidBeginEditing(_ textView: UITextView)
    {
        self.prevIndexValue = self.valueIndex
        self.prevTextValue = self.valueText
    }
    
    func textViewDidEndEditing(_ textView: UITextView)
    {
        guard let type = self.field?.fieldType else { return }
        
        let text = textView.text.trimContent()
        self.valueText = text
        self.onSelect?(type, nil, text)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}
