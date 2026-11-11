//
//  KPSAudio+AudioCollection.swift
//  KPS
//
//  Created by Kono on 2026/10/21.
//

import Foundation

public enum KPSAudioLanguage: String {
    case zh = "zh-TW"
    case en = "en-US"
    
    public var translationTarget: String {
        switch self {
        case .zh:
            return KPSAudioLanguage.en.rawValue
        case .en:
            return KPSAudioLanguage.zh.rawValue
        }
    }
}

extension KPSAudioContent {
    
    /// 從 customData 讀取 audioCollectionLang
    public var audioLanguage: String {
        return customData?["audioCollectionLang"] as? String ?? KPSAudioLanguage.en.rawValue
    }
    
}
