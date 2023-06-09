//
//  KPSFolderTableViewCell.swift
//  KPS-iOS
//
//  Created by Kono on 2023/5/24.
//

import Kingfisher
import UIKit

public struct KPSFolderTableCellViewModel {
    public var id: String
    var folderName: String
    var folderDescription: String?
    var mainImageURL: String
    
    public init(id: String, folderName: String, folderDescription: String?, mainImageURL: String) {
        self.id = id
        self.folderName = folderName
        self.folderDescription = folderDescription
        self.mainImageURL = mainImageURL
    }
}

public class KPSFolderTableViewCell: UITableViewCell {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.font = UIFont.font(ofType: .Heading_2)
        label.textAlignment = .left
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.font = UIFont.font(ofType: .Body_2)
        label.textAlignment = .left
        label.textColor = .textBlack
        return label
    }()
    
    private let mainImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 2.0
        imageView.contentMode = .scaleAspectFill
        return imageView
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
        
        contentView.addSubview(mainImageView)
        mainImageView.snp.makeConstraints { make in
            make.size.equalTo(ComponentConstants.articleTableViewImageSize)
            make.top.equalToSuperview().inset(ComponentConstants.smallVerticalMargin)
            make.bottom.lessThanOrEqualToSuperview().inset(ComponentConstants.smallVerticalMargin)
            make.left.equalToSuperview().inset(horizontalMargin)
        }
        
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(mainImageView.snp.top)
            make.left.equalTo(mainImageView.snp.right).offset(ComponentConstants.smallVerticalMargin)
            make.right.equalTo(actionView.snp.left).offset(-ComponentConstants.tightComponentInterSpacing)
        }
        
        contentView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(ComponentConstants.textBlockInterSpacing)
            make.bottom.lessThanOrEqualToSuperview().inset(ComponentConstants.smallVerticalMargin)
        }
    }
    
    public func update(with viewModel: KPSFolderTableCellViewModel) {
        
        titleLabel.text = viewModel.folderName
        titleLabel.sizeToFit()
        
        descriptionLabel.text = viewModel.folderDescription
        descriptionLabel.sizeToFit()
        mainImageView.kf.setImage(with: URL(string: viewModel.mainImageURL))
        
    }
    
}
