//
//  ChatBaseCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 24/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

fileprivate let chatLabelFont: UIFont = UIFont.systemFont(ofSize: 15.0, weight: .medium)

class ChatBaseCell: UITableViewCell
{
    var message: Message?
    {
        didSet {
            self.update()
        }
    }
    
    var onCopyMessage: ((String) -> ())?
    
    var topVisibleBorderDistance: CGFloat = 999.0
    {
        didSet {
            /*
            
            guard self.topVisibleBorderDistance < 56.0 else {
                self.contentView.alpha = 1.0
                
                return
            }
            
            self.contentView.alpha = self.topVisibleBorderDistance / 56.0 * 0.55 + 0.45
 */
        }
    }
    
    @IBOutlet fileprivate weak var labelWidthConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var labelHeightConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate weak var contentLabel: UILabel!
    
    static func height(_ text: String) -> CGFloat
    {
        return contentSize(text).height + 4.0 + 13.0 + 14.0
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        self.transform = CGAffineTransform(rotationAngle: .pi)
    }
    
    @objc func copyMessage(_ recognizer: UILongPressGestureRecognizer)
    {
        guard recognizer.state == .began else { return }
        guard let text = self.message?.text else { return }
        
        self.onCopyMessage?(text)
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
    let chatLabelMaxWidth = UIScreen.main.bounds.width * 0.7
    
    return (text as NSString).boundingRect(
        with: CGSize(width: chatLabelMaxWidth, height: 999.0),
        options: .usesLineFragmentOrigin,
        attributes: [NSAttributedString.Key.font: chatLabelFont],
        context: nil
    ).size
}
