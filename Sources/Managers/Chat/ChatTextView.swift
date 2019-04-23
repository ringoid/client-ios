//
//  ChatTextView.swift
//  ringoid
//
//  Created by Victor Sukochev on 23/04/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class ChatTextView: UITextView
{
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool
    {
        if action == #selector(paste(_:)) ||
            action == #selector(cut(_:)) ||
            action == #selector(copy(_:)) {
            return false
        }
        
        return true
    }
}
