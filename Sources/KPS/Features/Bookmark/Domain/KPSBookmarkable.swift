//
//  KPSBookmarkable.swift
//  KPS
//
//  Created by Kono on 2026/10/14.
//

public protocol KPSBookmarkable {
    var bookmarkId: String { get }
    var bookmarkTitle: String { get }
    var bookmarkAuthors: [String] { get }
    var bookmarkImageUrl: String? { get }
}
