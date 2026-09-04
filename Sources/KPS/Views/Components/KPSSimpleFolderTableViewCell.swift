//
//  KPSSimpleFolderTableViewCell.swift
//  KPS-iOS
//
//  Created by Kono on 2023/8/22.
//

import Kingfisher
import UIKit
import SwiftRichString

public class KPSSimpleFolderTableViewCell: UITableViewCell {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.font = UIFont.font(ofType: .Heading_2)
        label.textAlignment = .left
        label.sizeToFit()
        return label
    }()
    
    private let actionView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "iconArrowForward")
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        
        let horizontalMargin: CGFloat = KPSUtiltiy.deviceIsPhone ? ComponentConstants.normalHorizontalMargin : 40
                
        contentView.addSubview(actionView)
        actionView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
            make.right.equalToSuperview().inset(horizontalMargin)
        }
        
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(ComponentConstants.smallVerticalMargin)
            make.left.equalToSuperview().inset(horizontalMargin)
            make.right.equalTo(actionView.snp.left).offset(-ComponentConstants.tightComponentInterSpacing)
            make.bottom.lessThanOrEqualToSuperview().inset(ComponentConstants.smallVerticalMargin)
        }
    }
    
    public func update(with viewModel: KPSFolderTableCellViewModel) {
        
        titleLabel.text = viewModel.folderName
        titleLabel.sizeToFit()

    }
    
}
