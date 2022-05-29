//
//  UIFont+Extensions.swift
//  KPS
//
//  Created by mingshing on 2022/5/29.
//

import Foundation
import UIKit

enum FontType {
    case Title_1
    case Title_2
    case Title_3
    case Title_4
    case Heading_1
    case Heading_2
    case Heading_3
    case Body_1
    case Body_2
    case Body_3
}

extension UIFont {
    
    class func font(ofType type: FontType) -> UIFont {
        
        switch type {
        case .Title_1:
            return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: 28, weight: .bold))
        case .Title_2:
            return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: 24, weight: .bold))
        case .Title_3:
            return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: 14, weight: .bold))
        case .Title_4:
            return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: 12, weight: .bold))
        case .Heading_1:
            return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: 18, weight: .bold))
        case .Heading_2:
            return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: 16, weight: .bold))
        case .Heading_3:
            return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: 14, weight: .bold))
        case .Body_1:
            return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: 16, weight: .regular))
        case .Body_2:
            return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: 14, weight: .regular))
        case .Body_3:
            return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: 12, weight: .regular))
        }
        
    }
    
}
