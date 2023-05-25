//
//  KPSArticleTableViewCell.swift
//  KPS
//
//  Created by mingshing on 2022/5/29.
//

import Foundation
import Kingfisher
import UIKit

enum KSSArticleTagType: Int{

    case KSSPlanTypeVIP = 0
    case KSSPlanTypeFree = 1
    case KSSPlanTypePublic = 2
    
    case KSSReadModePDF = 11
    case KSSReadModeFitReading = 12
    case KSSReadModeMultiMedia = 13
    
    case KSSHighlightArticle = 21

    var tagString: String {
        switch self {
        case .KSSPlanTypeVIP:
            return "VIP"
        case .KSSPlanTypeFree:
            return NSLocalizedString("content_tag_free", bundle: Bundle.resourceBundle, comment: "")
        case .KSSPlanTypePublic:
            return NSLocalizedString("content_tag_public", bundle: Bundle.resourceBundle, comment: "")
        default:
            return ""
        }
    }
}

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
    
    var highlightTitle: NSAttributedString?
    var highlightDetail: NSAttributedString?
    
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
    
    var titleAttributedString: NSAttributedString {
        if let highlightTitle = highlightTitle {
            return highlightTitle
        } else {
            return NSAttributedString(string: articleTitle)
        }
    }
    
    var detailAttributedString: NSAttributedString {
        if let highlightDetail = highlightDetail {
            return highlightDetail
        } else {
            return NSAttributedString(string: articleDetailText)
        }
    }
    
    public init(id: String, articleTitle: String, articleMagazineName: String?, articleIssueName: String?, articleDescription: String?, mainImageURL: String, isFree: Bool?, isPublic: Bool?, orderInParent: Int?, highlightTitle: NSAttributedString? = nil, highlightDetail: NSAttributedString? = nil) {
        self.id = id
        self.articleTitle = articleTitle
        self.articleMagazineName = articleMagazineName
        self.articleIssueName = articleIssueName
        self.articleDescription = articleDescription
        self.mainImageURL = mainImageURL
        self.isFree = isFree
        self.isPublic = isPublic
        self.orderInParent = orderInParent
        self.highlightTitle = highlightTitle
        self.highlightDetail = highlightDetail
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
    
    private let articleTagsView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 5
        stackView.distribution = .equalSpacing
        stackView.alignment = .leading
        return stackView
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
        
        contentView.addSubview(mainImageView)
        mainImageView.snp.makeConstraints { make in
            make.size.equalTo(ComponentConstants.articleTableViewImageSize)
            make.top.equalToSuperview().inset(ComponentConstants.smallVerticalMargin)
            make.bottom.lessThanOrEqualToSuperview().inset(ComponentConstants.smallVerticalMargin)
            make.right.equalToSuperview().inset(horizontalMargin)
        }
        
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(mainImageView.snp.top)
            make.left.equalToSuperview().inset(horizontalMargin)
            make.right.equalTo(mainImageView.snp.left).offset(-ComponentConstants.smallVerticalMargin)
        }
        
        
        contentView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(ComponentConstants.textBlockInterSpacing)
        }
        
        contentView.addSubview(articleTagsView)
        articleTagsView.snp.makeConstraints { make in
            make.left.equalTo(titleLabel)
            make.right.lessThanOrEqualTo(titleLabel)
            make.top.equalTo(mainImageView.snp.bottom).offset(ComponentConstants.tightComponentInterSpacing)
            make.bottom.equalToSuperview().inset(ComponentConstants.smallVerticalMargin)
        }
        
    }
    
    public func update(with viewModel: KPSArticleTableCellViewModel) {
        
        titleLabel.attributedText = viewModel.titleAttributedString
        titleLabel.sizeToFit()
        
        descriptionLabel.attributedText = viewModel.detailAttributedString
        descriptionLabel.sizeToFit()
        mainImageView.kf.setImage(with: URL(string: viewModel.mainImageURL))
        
        var tagTypes: [KSSArticleTagType] = []
        
        if viewModel.isPublic ?? false {
            tagTypes.append(.KSSPlanTypePublic)
        } else if viewModel.isFree ?? false {
            tagTypes.append(.KSSPlanTypeFree)
        }
        
        setupTagsView(tagTypes: tagTypes)
    }
    
    func setupTagsView(tagTypes types: [KSSArticleTagType]) {
        for subView in articleTagsView.subviews {
            subView.removeFromSuperview()
        }
        
        for type in types {
            let tag = createTag(title: type.tagString)
            articleTagsView.addArrangedSubview(tag)
        }
    }
    
    func createTag(title: String?) -> UIButton {
        
        let tagView = UIButton(frame: CGRect.zero)
        
        let tagViewHeight: CGFloat = 24;
        let tagViewVericalMargin: CGFloat = 2;
        let tagViewHorizontalMargin: CGFloat = 8;
        
        tagView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(tagViewHeight)
        }
        
        tagView.backgroundColor = UIColor.lightGray
        tagView.titleLabel?.numberOfLines = 1
        tagView.titleLabel?.font = UIFont.font(ofType: .Body_3)
        tagView.isEnabled = false;
        
        tagView.setTitle(title, for: .normal)
        tagView.setTitleColor(UIColor.textBlack, for: .normal)
        tagView.contentEdgeInsets = UIEdgeInsets(
            top: tagViewVericalMargin,
            left: tagViewHorizontalMargin,
            bottom: tagViewVericalMargin,
            right: tagViewHorizontalMargin)
        
        return tagView
        
    }
}
