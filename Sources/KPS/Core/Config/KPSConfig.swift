//
//  KPSConfig.swift
//  KPS
//
//  Created by Kono on 2026/10/15.
//

import Foundation

public final class KPSConfig {
    public static let shared = KPSConfig()
    
    /// 主專案可手動設定 SDK 的預設語系，若未設定則預設為 "zh-TW"
    public var defaultLanguage: String = "zh-TW"
    
    /// 當指定語系找不到文字時的回退語系 (Fallback)
    public var fallbackLanguage: String = "en"
    
    /// 動態取得當前最佳語系（優先取系統目前語系 -> defaultLanguage -> fallbackLanguage）
    public var currentLanguage: String {
        // 取得系統偏好語系（如 "zh-Hant-TW" -> "zh-TW"）
        if let preferred = Locale.preferredLanguages.first {
            if preferred.contains("zh-Hant") || preferred.contains("zh-TW") {
                return "zh-TW"
            } else if preferred.contains("zh-Hans") || preferred.contains("zh-CN") {
                return "zh-CN"
            }
        }
        return defaultLanguage
    }
}
