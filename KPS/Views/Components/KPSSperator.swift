//
//  KPSSperator.swift
//  KPS
//
//  Created by mingshing on 2022/5/31.
//

import UIKit

class KPSSperator: UIView {
    
    init(color: UIColor = .lightGray) {
        super.init(frame: .zero)
        clipsToBounds = true
        backgroundColor = color
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private func setupView() {
        
    }
}
