//
//  KPSBookInfoView.swift
//  KPS
//
//  Created by mingshing on 2022/5/30.
//

import Foundation
import UIKit
import DeviceKit

public struct KPSBookInfoViewModel {
    
    var bookName: String
    var bookDescription: String?
    var mainImageURL: String
    
    public init(bookName: String, bookDescription: String?, mainImageURL: String) {
        self.bookName = bookName
        self.bookDescription = bookDescription
        self.mainImageURL = mainImageURL
    }
    
}


public protocol KPSBookInfoViewDelegate: AnyObject {
    
    func didTapActionButton (_ infoView: KPSBookInfoView)
    func didTapMoreButton(_ infoView: KPSBookInfoView)
}


public class KPSBookInfoView: UIView {
    
    //MARK: Views
    private var mainImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.masksToBounds = true
        imageView.layer.borderColor = UIColor.borderGray.cgColor
        imageView.layer.borderWidth = 1.0
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .red
        return imageView
    }()
    
    private let bookNameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.font(ofType: .Body_1)
        return label
    }()
    
    private lazy var actionButton: UIButton = {
        let button = UIButton()
        button.setTitle(NSLocalizedString("start_reading", bundle: Bundle.resourceBundle, comment: ""), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.font(ofType: .Heading_2)
        button.backgroundColor = themeColor
        button.layer.cornerRadius = ComponentConstants.actionButtonRadius
        return button
    }()
    
    private let bookDescriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 7
        label.textAlignment = .left
        label.textColor = .textBlack
        label.font = UIFont.font(ofType: .Body_2)
        return label
    }()

    private lazy var moreButton: UIButton = {
        let button = UIButton()
        
        button.setTitle(NSLocalizedString("more_description", bundle: Bundle.resourceBundle, comment: ""), for: .normal)
        button.titleLabel?.font = UIFont.font(ofType: .Heading_3)
        button.setTitleColor(themeColor, for: .normal)
        
        let image = UIImage(named: "iconRightArrow")?.imageWithColor(tintColor: themeColor)
        button.setImage(image, for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        button.backgroundColor = .clear
        button.semanticContentAttribute = .forceRightToLeft
        
        return button
    }()
    
    private let separator = KPSSperator()
    
    //MARK: Properties
    weak var delegate: KPSBookInfoViewDelegate?
    var themeColor: UIColor
    
    public init(themeColor: UIColor, delegate: KPSBookInfoViewDelegate?) {
        self.themeColor = themeColor
        self.delegate = delegate
        super.init(frame: .zero)
        clipsToBounds = true
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private func setupView() {
        
        addSubview(mainImageView)
        let imageViewMargin = KPSUtiltiy.deviceIsPhone ? ComponentConstants.bookInfoImagePhoneMargin : ComponentConstants.normalHorizontalMargin
        
        if KPSUtiltiy.deviceIsPhone {
            mainImageView.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.left.right.equalToSuperview().inset(imageViewMargin)
                make.centerX.equalToSuperview()
            }
        } else {
            mainImageView.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.left.right.equalToSuperview().inset(imageViewMargin)
                make.centerX.equalToSuperview()
            }
        }
        
        addSubview(bookNameLabel)
        bookNameLabel.snp.makeConstraints { make in
            make.top.equalTo(mainImageView.snp.bottom).offset(ComponentConstants.tightComponentInterSpacing)
            make.left.right.equalTo(mainImageView)
        }
        
        addSubview(actionButton)
        
        actionButton.addTarget(self, action: #selector(didTapActionBtn), for: .touchUpInside)
        
        if KPSUtiltiy.deviceIsPhone {
            
            actionButton.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(ComponentConstants.normalHorizontalMargin)
                make.top.equalTo(bookNameLabel.snp.bottom).offset(ComponentConstants.largeComponentInterSpacing)
                make.height.equalTo(ComponentConstants.actionButtonHeight)
            }
            
            
            addSubview(bookDescriptionLabel)
            bookDescriptionLabel.snp.makeConstraints { make in
                make.top.equalTo(actionButton.snp.bottom).offset(ComponentConstants.normalComponentInterSpacing)
                make.left.right.equalTo(actionButton)
                make.height.lessThanOrEqualTo(ComponentConstants.bookInfoDescriptionHeight)
            }
            
            addSubview(moreButton)
            moreButton.snp.makeConstraints { make in
                make.left.equalTo(bookDescriptionLabel.snp.left)
                make.top.equalTo(bookDescriptionLabel.snp.bottom).offset(ComponentConstants.normalComponentInterSpacing)
                make.height.equalTo(ComponentConstants.bookInfoMoreButtonHeight)
            }
            moreButton.addTarget(self, action: #selector(didTapMoreBtn), for: .touchUpInside)
            
            addSubview(separator)
            separator.snp.makeConstraints { make in
                make.height.equalTo(1)
                make.top.equalTo(moreButton.snp.bottom).offset(ComponentConstants.largeComponentInterSpacing)
                make.bottom.equalToSuperview()
                make.left.right.equalTo(actionButton)
            }   
        } else {
            
            actionButton.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(ComponentConstants.normalHorizontalMargin)
                make.top.equalTo(bookNameLabel.snp.bottom).offset(ComponentConstants.largeComponentInterSpacing)
                make.height.equalTo(ComponentConstants.actionButtonHeight)
                make.bottom.equalToSuperview()
            }
            
        }
    }
    
    @objc func didTapActionBtn() {
        
        delegate?.didTapActionButton(self)
    }
    
    @objc func didTapMoreBtn() {
        delegate?.didTapMoreButton(self)
    }
    
    public func update(with viewModel: KPSBookInfoViewModel) {
        
        bookNameLabel.text = viewModel.bookName
        bookDescriptionLabel.text = viewModel.bookDescription
        mainImageView.kf.setImage(with: URL(string: viewModel.mainImageURL)) { [weak self] result in
            
            guard let weakSelf = self else { return }
            switch result {
            case .success(let fetchImageResult):
                let imageAspectRatio: CGFloat = fetchImageResult.image.size.height / fetchImageResult.image.size.width
                let imageViewMargin = KPSUtiltiy.deviceIsPhone ? ComponentConstants.bookInfoImagePhoneMargin : ComponentConstants.normalHorizontalMargin
                
                weakSelf.mainImageView.snp.remakeConstraints { make in
                    make.top.equalToSuperview()
                    make.height.equalTo(weakSelf.mainImageView.snp.width).multipliedBy(imageAspectRatio).priority(.high)
                    make.left.right.equalToSuperview().inset(imageViewMargin)
                    make.centerX.equalToSuperview()
                }
                weakSelf.mainImageView.layoutIfNeeded()
            default:
                break
            }
        }
    }
}
