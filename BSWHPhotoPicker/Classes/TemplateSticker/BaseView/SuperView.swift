//
//  SuperView.swift
//  MobileProgect
//
//  Created by csqiuzhi on 2019/5/24.
//  Copyright © 2019 于晓杰. All rights reserved.
//

import UIKit

open class SuperView: UIView {
    // ✅ 指定初始化方法
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    // ✅ 从 Storyboard / XIB 初始化
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    // ✅ 抽取公共初始化逻辑
    private func commonInit() {
        setUpUI()
        getData()
    }
}

//MARK: ----------UI-----------
extension SuperView {
    @objc open func setUpUI() {
        backgroundColor(.clear)
    }
    
    @objc open func getData() {
        
    }
}

//MARK: ----------切换语言-----------
extension SuperView {
    @objc open func updateLanguageUI() {
        // 子类重写此方法实现具体更新逻辑
    }
}

