//
//  UserRealmObject.swift
//  FlowCrypt
//
//  Created by Anton Kharchevskyi on 07/04/2020.
//  Copyright © 2017-present FlowCrypt a. s. All rights reserved.
//

import RealmSwift

final class UserRealmObject: Object {
    @Persisted(primaryKey: true) var email: String
    @Persisted var isActive: Bool
    @Persisted var name: String
    @Persisted var imap: SessionRealmObject?
    @Persisted var smtp: SessionRealmObject?
}

extension UserRealmObject {
    convenience init(name: String, email: String, imap: SessionRealmObject?, smtp: SessionRealmObject?) {
        self.init()
        self.email = email
        self.isActive = true
        self.name = name
        self.imap = imap
        self.smtp = smtp
    }
}

extension UserRealmObject {
    convenience init(_ user: User) {
        self.init()
        self.email = user.email
        self.isActive = user.isActive
        self.name = user.name
        self.imap = user.imap.flatMap(SessionRealmObject.init)
        self.smtp = user.smtp.flatMap(SessionRealmObject.init)
    }
}
