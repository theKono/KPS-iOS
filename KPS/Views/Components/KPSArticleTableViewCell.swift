//
//  KPSArticleTableViewCell.swift
//  KPS
//
//  Created by mingshing on 2022/5/29.
//

import Foundation
import Kingfisher
import UIKit

public struct KPSArticleTableCellViewModel {
    
    var articleTitle: String
    var articleDescriptioin: String?
    var mainImageURL: String
    
    public init(articleTitle: String, articleDescriptioin: String?, mainImageURL: String) {
        self.articleTitle = articleTitle
        self.articleDescriptioin = articleDescriptioin
        self.mainImageURL = mainImageURL
    }
    
}


public class KPSArticleTableViewCell: UITableViewCell {
    
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
        imageView.backgroundColor = .red
        return imageView
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
        
        
        contentView.addSubview(mainImageView)
        mainImageView.snp.makeConstraints { make in
            make.size.equalTo(ComponentConstants.articleTableViewImageSize)
            make.top.bottom.equalToSuperview().inset(ComponentConstants.smallVerticalMargin)
            make.right.equalToSuperview().inset(ComponentConstants.normalHorizontalMargin)
        }
        
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(mainImageView.snp.top)
            make.left.equalToSuperview().inset(ComponentConstants.normalHorizontalMargin)
            make.right.equalTo(mainImageView.snp.left).offset(-ComponentConstants.smallVerticalMargin)
        }
        
        
        contentView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(ComponentConstants.textBlockInterSpacing)
        }
        
    }
    
    public func update(with viewModel: KPSArticleTableCellViewModel) {
        
        titleLabel.text = viewModel.articleTitle
        titleLabel.sizeToFit()
        
        descriptionLabel.text = viewModel.articleDescriptioin
        descriptionLabel.sizeToFit()
        mainImageView.kf.setImage(with: URL(string: viewModel.mainImageURL))
    }
}
