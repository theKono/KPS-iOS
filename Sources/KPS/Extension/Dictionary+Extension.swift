//
//  Dictionary+Extension.swift
//  KPS
//
//  Created by Kono on 2026/10/15.
//

extension Dictionary where Key == String, Value == String {
    /// 根據語系優先順序尋找對應文字：指定語系 -> 預設語系 -> 回退語系 -> 任意第一個可用的文字
    func localizedString(
        preferred: String = KPSConfig.shared.currentLanguage,
        defaultLang: String = KPSConfig.shared.defaultLanguage,
        fallbackLang: String = KPSConfig.shared.fallbackLanguage
    ) -> String {
        return self[preferred]
            ?? self[defaultLang]
            ?? self[fallbackLang]
            ?? self.values.first
            ?? ""
    }
}

// 針對 [String: [String]] (作者列表)
extension Dictionary where Key == String, Value == [String] {
    func localizedArray(
        preferred: String = KPSConfig.shared.currentLanguage,
        defaultLang: String = KPSConfig.shared.defaultLanguage,
        fallbackLang: String = KPSConfig.shared.fallbackLanguage
    ) -> [String] {
        return self[preferred]
            ?? self[defaultLang]
            ?? self[fallbackLang]
            ?? self.values.first
            ?? []
    }
}
