//
//  KPSToast.swift
//  KPS
//
//  Created by mingshing on 2022/5/6.
//

import Foundation
import Toast_Swift
import SnapKit

public enum KPSToastType {
    
    case Warning
    case Success
    case Copy
    case Delete
    
}


public class KPSToast {
    
    
    public static func show(_ view: UIView, message: String, type: KPSToastType, completion: (()->())? = nil) {
        let messageView = generateCustomizeToastView(message: message, type: type)
        view.showToast(messageView) { didTap in 
            completion?()
        }
    }
    
    private static func generateCustomizeToastView(message: String, type: KPSToastType) -> UIView {
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 355, height: 50))
        
        view.backgroundColor = UIColor(red: 0.133, green: 0.133, blue: 0.133, alpha: 1)
        view.layer.cornerRadius = 4
        
        let iconImage: UIImage?
        switch type {
        case .Warning:
            iconImage = UIImage(named: "iconWarning", in: Bundle.resourceBundle, compatibleWith: nil)
        case .Success:
            iconImage = UIImage(named: "iconSuccess", in: Bundle.resourceBundle, compatibleWith: nil)
        case .Copy:
            iconImage = UIImage(named: "iconLink", in: Bundle.resourceBundle, compatibleWith: nil)
        case .Delete:
            iconImage = UIImage(named: "iconTrash", in: Bundle.resourceBundle, compatibleWith: nil)
        }
        
        let iconImageView: UIImageView = UIImageView(image: iconImage)
        let messageLabel: UILabel = UILabel()
        messageLabel.text = message
        messageLabel.textColor = .white
        messageLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.systemFont(ofSize: 14, weight: .regular))
        
        view.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(16)
            make.top.left.equalToSuperview().inset(17)
        }
        
        view.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(14)
            make.bottom.equalToSuperview().inset(16)
            make.left.equalTo(iconImageView.snp.right).offset(13)
        }
        return view
    }
    
}
