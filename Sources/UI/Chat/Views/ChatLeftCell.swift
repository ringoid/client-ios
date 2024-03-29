//
//  ChatLeftCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 24/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class ChatLeftCell: ChatBaseCell
{
    @IBOutlet fileprivate weak var bubbleImageView: UIImageView!
    
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
        let backgroundImage = UIImage(named: "chat_bubble_left")?.resizableImage(withCapInsets: capInsets)
        self.bubbleImageView.image = backgroundImage
    }
}
