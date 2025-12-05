//
//  ToolsCollectionView.swift
//  BSWHPhotoPicker_Example
//
//  Created by 笔尚文化 on 2025/11/10.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import UIKit

protocol RatioCollectionViewDelegate: AnyObject {
    func ratioCellDidSelectItemAt(_ sender: RatioCollectionView,indexPath:IndexPath,item:RatioToolsModel)
}

class RatioCollectionView: UIView {
    weak var delegate: RatioCollectionViewDelegate?
    var items: [RatioToolsModel] = []
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
        cv.register(RatioCollectionViewCell.self, forCellWithReuseIdentifier: "RatioCollectionViewCell")
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
        reload()
    }

    func reload() {
        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource
extension RatioCollectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "RatioCollectionViewCell",
            for: indexPath
        ) as! RatioCollectionViewCell
        cell.configure(with: items[indexPath.row])
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension RatioCollectionView: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        if currentIndex == 2 {
            return CGSize(width: 68.w, height: 120.h)
        }else{
            return CGSize(width: 58.w, height: 120.h)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.delegate?.ratioCellDidSelectItemAt(self, indexPath: indexPath,item: items[indexPath.row])
    }
}


class RatioCollectionViewCell: UICollectionViewCell {
        
    lazy var imgView = UIImageView()
    lazy var titleLab = UILabel().color(kkColorFromHex("65656D")).hnFont(size: 12.h, weight:.mediumBase).centerAligned()
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        contentView.addSubview(imgView)
        contentView.addSubview(titleLab)

        imgView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(10.h)
            make.size.equalTo(CGSize(width: 36.w, height: 36.w))
        }

        titleLab.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(18.h)
            make.top.equalTo(imgView.snp.bottom).offset(10.h)
        }
    }

    func configure(with item: RatioToolsModel) {
        titleLab.text = item.text
        imgView.image(BSWHBundle.image(named: item.imageName))
    }
}
