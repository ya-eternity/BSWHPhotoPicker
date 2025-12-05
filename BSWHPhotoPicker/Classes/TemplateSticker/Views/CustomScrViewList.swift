//
//  TemplateList.swift
//  BSWHPhotoPicker_Example
//
//  Created by 笔尚文化 on 2025/11/12.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import UIKit

protocol CustomScrViewListDelegate: AnyObject {
    func scrViewDidSelect(index: Int)
}

class CustomScrViewList: UIView {

    var titles: [String] = [] {
        didSet { reloadData() }
    }
    
    var btnFont: UIFont = .systemFont(ofSize: 14.h, weight: .medium)
    var btnSelectedFont: UIFont = .systemFont(ofSize: 14.h, weight: .regular)
    
    var btnColor: UIColor = .darkGray
    var btnSelectedTextColor: UIColor = .white
    
    var btnBackgroundColor: UIColor = .clear
    var btnCornerRadius: CGFloat = 12
    
    // 未选中时边框
    var btnBorderColor: UIColor = kkColorFromHex("E4E4E4")
    var btnBorderWidth: CGFloat = 1
    
    weak var delegate: CustomScrViewListDelegate?

    private let scrollView = UIScrollView()
    private var buttonArray: [UIButton] = []
    private var selectedIndex: Int = 0
    
    private var isLinking = false // 避免重复触发

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        addSubview(scrollView)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func reloadData() {
        buttonArray.forEach { $0.removeFromSuperview() }
        buttonArray.removeAll()
        
        var lastButton: UIButton?
        for (i, title) in titles.enumerated() {
            let btn = UIButton(type: .custom)
            btn.setTitle(title, for: .normal)
            btn.setTitleColor(btnColor, for: .normal)
            btn.setTitleColor(btnSelectedTextColor, for: .selected)
            btn.titleLabel?.font = btnFont
            btn.backgroundColor = btnBackgroundColor
            btn.layer.cornerRadius = btnCornerRadius
            btn.layer.borderWidth = btnBorderWidth
            btn.layer.borderColor = btnBorderColor.cgColor
            btn.clipsToBounds = true
            btn.tag = i
            btn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 15, bottom: 6, right: 15)
            btn.addTarget(self, action: #selector(btnTapped(_:)), for: .touchUpInside)
            scrollView.addSubview(btn)
            buttonArray.append(btn)
            
            btn.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                if let last = lastButton {
                    make.left.equalTo(last.snp.right).offset(10)
                } else {
                    make.left.equalToSuperview().offset(0)
                }
            }
            
            lastButton = btn
        }
        
        layoutIfNeeded()
        if let last = lastButton {
            scrollView.contentSize = CGSize(width: last.frame.maxX + 10, height: scrollView.frame.height)
        }
        
        updateSelection(index: 0, animated: false)
    }

    @objc private func btnTapped(_ sender: UIButton) {
        let index = sender.tag
        selectIndex(index: index, animated: true)
        delegate?.scrViewDidSelect(index: index)
    }
    
    func selectIndex(index: Int, animated: Bool) {
        guard index >= 0, index < buttonArray.count else { return }
        isLinking = true
        updateSelection(index: index, animated: animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isLinking = false
        }
    }

    private func updateSelection(index: Int, animated: Bool) {
        selectedIndex = index
        
        for (i, btn) in buttonArray.enumerated() {
            // 移除旧的渐变
            btn.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
            
            if i == index {
                btn.isSelected = true
                btn.titleLabel?.font = btnSelectedFont
                btn.layer.borderWidth = 0
                
                let gradient = CAGradientLayer()
                gradient.frame = btn.bounds
                gradient.colors = [kkColorFromHex("D500FF").cgColor, kkColorFromHex("FD57AF").cgColor]
                gradient.startPoint = CGPoint(x: 0, y: 0.5)
                gradient.endPoint = CGPoint(x: 1, y: 0.5)
                gradient.cornerRadius = btnCornerRadius
                btn.layer.insertSublayer(gradient, at: 0)
            } else {
                btn.isSelected = false
                btn.titleLabel?.font = btnFont
                btn.backgroundColor = btnBackgroundColor
                btn.layer.borderWidth = btnBorderWidth
                btn.layer.borderColor = btnBorderColor.cgColor
            }
        }
        
        // 滚动居中 —— 修改逻辑
        let selectedBtn = buttonArray[index]
        DispatchQueue.main.async {
            // 如果 scrollView 内容宽度 <= scrollView 宽度，不滚动
            guard self.scrollView.contentSize.width > self.scrollView.frame.width else { return }

            // 居中逻辑
            let offsetX = max(0, selectedBtn.center.x - self.scrollView.frame.width / 2)
            self.scrollView.setContentOffset(
                CGPoint(x: min(offsetX, self.scrollView.contentSize.width - self.scrollView.frame.width), y: 0),
                animated: animated
            )
        }
    }

}
