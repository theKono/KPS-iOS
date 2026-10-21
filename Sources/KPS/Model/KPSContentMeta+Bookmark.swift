//
//  KPSContentMeta+Bookmark.swift
//  KPS
//
//  Created by Kono on 2026/10/15.
//

extension KPSContentMeta: KPSBookmarkable {
    
    public var bookmarkId: String {
        return self.id
    }
    
    public var bookmarkTitle: String {
        return self.name?.localizedString() ?? ""
    }
    
    public var bookmarkAuthors: [String] {
        return self.authors?.localizedArray() ?? []
    }
    
    public var bookmarkImageUrl: String? {
        return self.images.first?.thumbnailImageURL(of: 200)
    }
}

