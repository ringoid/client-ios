//
//  NewFacesCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 07/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Nuke

class NewFacesCell: UITableViewCell
{
    @IBOutlet weak var photoView: UIImageView!
    
    var profile: Profile?
    {
        didSet {
            self.update()
        }
    }
    
    fileprivate func update()
    {
        guard let urlStr = profile?.photos.first?.url, let url = URL(string: urlStr) else {
            self.photoView.image = nil
            
            return
        }
        
        Nuke.loadImage(with: url, into: self.photoView)
    }
}
