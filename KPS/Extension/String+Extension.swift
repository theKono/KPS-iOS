//
//  String+Extension.swift
//  KPS-iOS
//
//  Created by mingshing on 2021/12/15.
//

import Foundation

extension String {
    var withoutHtmlTags: String {
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
            .replacingOccurrences(of: "&[^;]+;", with: "", options:.regularExpression, range: nil)
    }
}
