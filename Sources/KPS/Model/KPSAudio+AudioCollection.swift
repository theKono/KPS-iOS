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
}

extension KPSAudioContent {
    
    /// 從 customData 讀取 audioCollectionLang
    public var audioLanguage: String? {
        return customData?["audioCollectionLang"] as? String
    }
    
}
