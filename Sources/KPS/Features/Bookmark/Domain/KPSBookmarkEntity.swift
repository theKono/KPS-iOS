//
//  KPSBookmarkEntity.swift
//  KPS
//
//  Created by Kono on 2026/10/14.
//
import Foundation

public struct KPSBookmarkEntity {
    public let id: String
    public let title: String
    public let authors: [String]
    public let imageUrl: String?
    public let addedAt: Date
    
    internal init(id: String, title: String, authors: [String], imageUrl: String?, addedAt: Date) {
        self.id = id
        self.title = title
        self.authors = authors
        self.imageUrl = imageUrl
        self.addedAt = addedAt
    }
}
