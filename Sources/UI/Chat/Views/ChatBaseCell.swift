//
//  ChatBaseCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 24/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

fileprivate let chatLabelMaxWidth: CGFloat = 211.0
fileprivate let chatLabelFont: UIFont = UIFont.systemFont(ofSize: 15.0, weight: .medium)

class ChatBaseCell: UITableViewCell
{
    var message: Message?
    {
        didSet {
            self.update()
        }
    }
    
    @IBOutlet fileprivate weak var labelWidthConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var labelHeightConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var contentLabel: UILabel!
    
    static func height(_ text: String) -> CGFloat
    {
        return contentSize(text).height + 4.0 + 24.0 + 14.0
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        self.transform = CGAffineTransform(rotationAngle: .pi)
    }
    
    // MARK: -
    
    fileprivate func update()
    {
        let size = contentSize(self.message?.text ?? "")
        self.labelWidthConstraint.constant = size.width + 2.0
        self.labelHeightConstraint.constant = size.height + 4.0
        self.layoutSubviews()
        self.contentLabel.text = self.message?.text
    }
}

fileprivate func contentSize(_ text: String) -> CGSize
{
    return (text as NSString).boundingRect(
        with: CGSize(width: chatLabelMaxWidth, height: 999.0),
        options: .usesLineFragmentOrigin,
        attributes: [NSAttributedString.Key.font: chatLabelFont],
        context: nil
    ).size
}
