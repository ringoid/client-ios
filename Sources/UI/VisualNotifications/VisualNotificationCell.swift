//
//  VisualNotificationCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 27/09/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class VisualNotificaionCell: BaseTableViewCell
{
    var item: VisualNotificationInfo!
    {
        didSet {
            self.titleLabel.text = self.item.text
            
            if let image = self.item.photoImage  {
                self.photoView.image = image
                
                return
            }
            
            if let url = self.item.photoUrl, let imageData = try? Data(contentsOf: url) {
                self.photoView.image = UIImage(data: imageData)
                
                return
            }
        }
    }
    
    @IBOutlet fileprivate weak var photoView: UIImageView!
    @IBOutlet fileprivate weak var titleLabel: UILabel!
}
