//
//  KPSContentMeta+AudioCollection.swift
//  KPS
//
//  Created by Kono on 2026/10/21.
//

import Foundation

extension KPSContentMeta {
    
    /// 註：此屬性僅針對 audio / audioCollection 型態有效
    public var audioLanguage: KPSAudioLanguage? {
        // 如果不是音檔相關型態無此屬性，回傳 nil
        guard contentType == .audio else {
            return nil
        }
        
        guard let langString = customData?["audioCollectionLang"] as? String,
              let language = KPSAudioLanguage(rawValue: langString) else {
            return .en
        }
        return language
    }
}
