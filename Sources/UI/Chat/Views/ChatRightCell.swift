//
//  ChatRightCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 24/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

enum ChatMessageState {
    case sending;
    case sent;
    case read;
}

class ChatRightCell: ChatBaseCell
{
    var state: ChatMessageState = .sending
    {
        didSet {
            var iconName: String = ""
            
            switch self.state {
            case .sending: iconName = ""
            case .sent: iconName = "chat_checkmark"
            case .read: iconName = "chat_checkmarks"
            }
            
            self.checkmarckImageView.image = UIImage(named: iconName)
        }
    }
    
    @IBOutlet fileprivate weak var bubbleImageView: UIImageView!
    @IBOutlet fileprivate weak var checkmarckImageView: UIImageView!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(copyMessage(_:)))
        self.bubbleImageView.addGestureRecognizer(recognizer)
        
        self.setupContent()
    }
    
    // MARK: -
    
    fileprivate func setupContent()
    {
        let capInsets = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
        let backgroundImage = UIImage(named: "chat_bubble_right")?.resizableImage(withCapInsets: capInsets)
        self.bubbleImageView.image = backgroundImage
    }
}
