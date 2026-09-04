//
//  Bundle+Extension.swift
//  KPS
//
//  Created by Kono on 2026/9/4.
//

import Foundation

public extension Bundle {
    /// 提供外部模組（如 KPSTests ）存取 KPS 的資源 Bundle
    static var kpsModule: Bundle {
        return Bundle.module
    }
}
