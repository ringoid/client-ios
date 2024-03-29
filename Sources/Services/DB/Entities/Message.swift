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
    @objc dynamic var msgId: String!
    @objc dynamic var wasYouSender: Bool = false
    @objc dynamic var text: String!
    @objc dynamic var timestamp: Date!
    @objc dynamic var isRead: Bool = false
}

extension Message
{
    func duplicate() -> Message
    {
        let message = Message()
        message.id = self.id
        message.msgId = self.msgId
        message.wasYouSender = self.wasYouSender
        message.text = self.text
        message.timestamp = self.timestamp
        message.isRead = self.isRead
        
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
