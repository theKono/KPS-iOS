//
//  KPSBookmarkManager.swift
//  KPS
//
//  Created by Kono on 2026/10/14.
//

import Foundation
import RealmSwift

public final class KPSBookmarkManager {
    
    public static let shared = KPSBookmarkManager()
    
    /// 由主專案（Host App）註冊的動態 User ID 獲取 closure
    public var currentUserIdProvider: (() -> String?)?
    
    /// 提供給主專案監聽的 Notification 名稱
    public static let bookShelfChangedNotification = Notification.Name("KPSBookShelfChangedNotification")
    
    private var currentUserId: String? {
        guard let uid = currentUserIdProvider?(), !uid.isEmpty else {
            return nil
        }
        return uid
    }
    
    private let realmConfiguration: Realm.Configuration
    
    private var realm: Realm {
        return try! Realm(configuration: realmConfiguration)
    }
    
    public init(realmConfiguration: Realm.Configuration = Realm.Configuration.defaultConfiguration, currentUserIdProvider: (() -> String?)? = nil) {
        self.realmConfiguration = realmConfiguration
        self.currentUserIdProvider = currentUserIdProvider
    }
    
    // MARK: - Public API
    
    /// 新增收藏
    public func add(_ item: KPSBookmarkable) {
        guard let uid = currentUserId else { return }
        
        let model = KPSBookmarkRealmModel(item: item, userId: uid)
        try? realm.write {
            realm.add(model, update: .modified)
        }
        
        notifyShelfChanged()
    }
    
    /// 移除收藏
    public func remove(_ id: String) {
        guard let key = primaryKey(id) else { return }
        
        if let object = realm.object(ofType: KPSBookmarkRealmModel.self, forPrimaryKey: key) {
            try? realm.write {
                realm.delete(object)
            }
        }
        
        notifyShelfChanged()
    }
    
    /// 是否已收藏
    public func isBookmarked(_ id: String) -> Bool {
        guard let key = primaryKey(id) else { return false }
        return realm.object(ofType: KPSBookmarkRealmModel.self, forPrimaryKey: key) != nil
    }
    
    /// 獲取當前用戶的所有收藏
    public func fetchBooks() -> [KPSBookmarkEntity] {
        guard let uid = currentUserId else { return [] }
        
        let results = realm.objects(KPSBookmarkRealmModel.self)
            .where { $0.userId == uid }
            .sorted(byKeyPath: "addedAt", ascending: false)
            
        return results.map { model in
            return KPSBookmarkEntity(
                id: model.contentId,
                title: model.contentName,
                authors: Array(model.authorList),
                imageUrl: model.coverURL.isEmpty ? nil : model.coverURL,
                addedAt: model.addedAt
            )
        }
    }
    
    // MARK: - Helpers
    
    public var isUserLoggedIn: Bool {
        return currentUserId != nil
    }
    
    private func primaryKey(_ id: String) -> String? {
        guard let uid = currentUserId else { return nil }
        return "\(uid)_\(id)"
    }
    
    private func notifyShelfChanged() {
        NotificationCenter.default.post(name: KPSBookmarkManager.bookShelfChangedNotification, object: nil)
    }
}
