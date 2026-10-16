//
//  KPSBookmarkRealmModel.swift
//  KPS
//
//  Created by Kono on 2026/10/14.
//

import Foundation
import RealmSwift

@objc(BookmarkRealmModel)
internal final class KPSBookmarkRealmModel: Object {
    @Persisted(primaryKey: true) var id: String = ""
    @Persisted var contentId: String = ""
    @Persisted var userId: String = ""
    @Persisted var contentName: String = ""
    @Persisted var authorList: List<String> = List<String>()
    @Persisted var coverURL: String = ""
    @Persisted var addedAt: Date = Date()
    
    convenience init(item: KPSBookmarkable, userId: String) {
        self.init()
        self.id = "\(userId)_\(item.bookmarkId)"
        self.contentId = item.bookmarkId
        self.userId = userId
        self.contentName = item.bookmarkTitle
        self.authorList.append(objectsIn: item.bookmarkAuthors)
        self.coverURL = item.bookmarkImageUrl ?? ""
        self.addedAt = Date()
    }
}
