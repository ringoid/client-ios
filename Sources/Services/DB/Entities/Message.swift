//
//  Message.swift
//  ringoid
//
//  Created by Victor Sukochev on 14/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RealmSwift

class Message: DBServiceObject
{
    @objc dynamic var id: String!
    @objc dynamic var wasYouSender: Bool = false
    @objc dynamic var text: String!
    @objc dynamic var timestamp: Date!
}

extension Message
{
    func duplicate() -> Message
    {
        let message = Message()
        message.id = self.id
        message.wasYouSender = self.wasYouSender
        message.text = self.text
        message.timestamp = self.timestamp
        
        if self.realm?.isInWriteTransaction == true {
            self.realm?.add(message)
        } else {
            try? self.realm?.write { [weak self] in
                self?.realm?.add(message)
            }
        }
        
        return message
    }
}
