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
    func write(_ writeBlock: (()->())?)
    {
        try? self.realm?.write {
            writeBlock?()
        }
    }
}
