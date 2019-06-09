//
//  DBServiceObject.swift
//  ringoid
//
//  Created by Victor Sukochev on 20/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RealmSwift

class DBServiceObject: Object
{
    @objc dynamic var orderPosition: Int = 0
    @objc dynamic var isDeleted: Bool = false
    
    func write(_ writeBlock: ((DBServiceObject?) -> ())?)
    {
        guard let realm = self.realm else { return }
        
        weak var weakSelf = self
        if realm.isInWriteTransaction {
            writeBlock?(weakSelf)
        } else {
            try? realm.write {
                writeBlock?(weakSelf)
            }
        }
    }
}
