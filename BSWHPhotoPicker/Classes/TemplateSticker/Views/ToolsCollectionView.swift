//
//  ToolsCollectionView.swift
//  BSWHPhotoPicker_Example
//
//  Created by 笔尚文化 on 2025/11/10.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import UIKit
import SnapKit


@objc protocol ToolsCollectionViewDelegate: AnyObject {
    func cellDidSelectItemAt(_ sender: ToolsCollectionView,indexPath:IndexPath)
}

class ToolsCollectionView: UIView {
    weak var delegate: ToolsCollectionViewDelegate?
//    var scannedImages: [String] = ["替换背景","弹框测试","修改比例1:1","修改比例4:5","修改比例9:16","裁剪"]
    var items: [ToolsModel] = []
    var currentIndex: Int = 0
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = kkColorFromHex("F5F5F5")
        cv.dataSource = self
        cv.delegate = self
        cv.showsHorizontalScrollIndicator = false
        cv.register(ToolCollectionViewCell.self, forCellWithReuseIdentifier: "ToolCollectionViewCell")
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
//        if StickerManager.shared.templateOrBackground == 1 {
            items = ConfigDataItem.getTemplateToolsData()
//        }else{
//            items = ConfigDataItem.getBackgroundToolsData()
//        }
        reload()
    }

    func reload() {
        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource
extension ToolsCollectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "ToolCollectionViewCell",
            for: indexPath
        ) as! ToolCollectionViewCell
        cell.configure(with: items[indexPath.row])
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension ToolsCollectionView: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: kkScreenWidth / 5.0, height: 120.h)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.delegate?.cellDidSelectItemAt(self, indexPath: indexPath)
    }
}


class ToolCollectionViewCell: UICollectionViewCell {
        
    private lazy var containerView = UIView().backgroundColor(kkColorFromHex("EBEBEB")).cornerRadius(10.w)
    lazy var imgView = UIImageView()
    lazy var titleLab = UILabel().color(kkColorFromHex("65656D")).hnFont(size: 12.h, weight:.mediumBase).centerAligned().adjustsFontSizeToFitWidth(true)
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        containerView.backgroundColor(kkColorFromHex("EBEBEB"))
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
            make.size.equalTo(CGSize(width: 26.w, height: 26.w))
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
