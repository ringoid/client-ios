//
//  VisualNotificationsTableView.swift
//  ringoid
//
//  Created by Victor Sukochev on 27/09/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class VisualNotificationsTableView: UITableView
{
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView?
    {
        let hittedView = super.hitTest(point, with: event)
        
        guard let numberOfRows = self.dataSource?.tableView(self, numberOfRowsInSection: 0) else { return nil }
        
        return nil
    }
}
