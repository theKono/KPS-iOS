//
//  KPSIssueCollectionViewCell.swift
//  KPS
//
//  Created by mingshing on 2022/6/1.
//

import UIKit

public struct KPSIssueCollectionViewCellViewModel {
    
    public var id: String
    var issueTitle: String
    var mainImageURL: String
    
    public init(id: String, issueTitle: String, mainImageURL: String) {
        self.id = id
        self.issueTitle = issueTitle
        self.mainImageURL = mainImageURL
    }
    
}


public class KPSIssueCollectionViewCell: UICollectionViewCell {
    
    //MARK: Views
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UIFont.font(ofType: .Body_2)
        label.textAlignment = .left
        return label
    }()
    
    private let mainImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 2.0
        imageView.layer.masksToBounds = true
        imageView.layer.borderColor = UIColor.borderGray.cgColor
        imageView.layer.borderWidth = 1.0
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    //MARK: Properties
    public let extraHeight: CGFloat = 30.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        
        contentView.addSubview(mainImageView)
        mainImageView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalToSuperview().inset(extraHeight)
        }
        
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(mainImageView.snp.bottom).offset(8)
            make.left.right.equalTo(mainImageView)
            //make.bottom.equalToSuperview()
        }
    }
    
    public func update(with viewModel: KPSIssueCollectionViewCellViewModel) {
        
        titleLabel.text = viewModel.issueTitle
        titleLabel.sizeToFit()
        
        mainImageView.kf.setImage(with: URL(string: viewModel.mainImageURL))
    }
}
