//
//  ToolsCollectionView.swift
//  BSWHPhotoPicker_Example
//
//  Created by 笔尚文化 on 2025/11/10.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import UIKit
import SnapKit


@objc protocol StickerToolsCollectionViewDelegate: AnyObject {
    func stickerCellDidSelectItemAt(_ sender: StickerToolsCollectionView,indexPath:IndexPath)
}

class StickerToolsCollectionView: UIView {
    weak var delegate: StickerToolsCollectionViewDelegate?
    var items: [ToolsModel] = []
    var currentIndex: Int = 0
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .white
        cv.dataSource = self
        cv.delegate = self
        cv.showsHorizontalScrollIndicator = false
        cv.register(StickerToolCollectionViewCell.self, forCellWithReuseIdentifier: "StickerToolCollectionViewCell")
        return cv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(0.w)
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalTo(120.h)
        }
        items = ConfigDataItem.getStickerToolsData()
        reload()
    }

    func reload() {
        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource
extension StickerToolsCollectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "StickerToolCollectionViewCell",
            for: indexPath
        ) as! StickerToolCollectionViewCell
        cell.configure(with: items[indexPath.row])
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension StickerToolsCollectionView: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: kkScreenWidth / 6.0, height: 120.h)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.delegate?.stickerCellDidSelectItemAt(self, indexPath: indexPath)
    }
}


class StickerToolCollectionViewCell: UICollectionViewCell {
        
    private lazy var containerView = UIView().backgroundColor(.white).cornerRadius(10.w)
    lazy var imgView = UIImageView().enable(true)
    lazy var titleLab = UILabel().color(kkColorFromHex("7F7F8C")).hnFont(size: 12.h, weight:.mediumBase).centerAligned().adjustsFontSizeToFitWidth(true)
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        containerView.backgroundColor(.white)
        contentView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(5.h)
            make.width.height.equalTo(42.w)
        }
       
        containerView.addSubview(imgView)
        contentView.addSubview(titleLab)

        imgView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 36.w, height: 36.w))
        }

        titleLab.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(18.h)
            make.top.equalTo(containerView.snp.bottom).offset(8.h)
        }
    }

    func configure(with item: ToolsModel) {
        titleLab.text = item.text
        imgView.image(BSWHBundle.image(named: item.imageName))
    }
}
