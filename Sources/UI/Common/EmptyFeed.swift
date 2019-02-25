//
//  EmptyFeed.swift
//  ringoid
//
//  Created by Victor Sukochev on 25/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class EmptyFeed: NSObject, UITableViewDataSource
{
    static let shared = EmptyFeed()
    
    func numberOfSections(in tableView: UITableView) -> Int { return 0 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return 0 }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { return UITableViewCell() }
}
