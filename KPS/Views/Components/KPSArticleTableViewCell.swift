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
    
    public var id: String
    var articleTitle: String
    var articleMagazineName: String?
    var articleIssueName: String?
    var articleDescription: String?
    var mainImageURL: String
    var isFree: Bool?
    var isPublic: Bool?
    public var orderInParent: Int?
    
    var articleDetailText: String {
        if let description = articleDescription,
           description.count > 0 {
            return description
        } else {
            guard let magazineName = articleMagazineName,
                  let issueName = articleIssueName else { return "" }
            return String(format: "%@ %@", magazineName, issueName)
        }
    }
    
    
    public init(id: String, articleTitle: String, articleMagazineName: String?, articleIssueName: String?, articleDescription: String?, mainImageURL: String, isFree: Bool?, isPublic: Bool?, orderInParent: Int?) {
        self.id = id
        self.articleTitle = articleTitle
        self.articleMagazineName = articleMagazineName
        self.articleIssueName = articleIssueName
        self.articleDescription = articleDescription
        self.mainImageURL = mainImageURL
        self.isFree = isFree
        self.isPublic = isPublic
        self.orderInParent = orderInParent
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
        
        descriptionLabel.text = viewModel.articleDetailText
        descriptionLabel.sizeToFit()
        mainImageView.kf.setImage(with: URL(string: viewModel.mainImageURL))
    }
}
