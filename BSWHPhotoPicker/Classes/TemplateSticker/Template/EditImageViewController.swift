//
//  EditImageViewController.swift
//  BSWHPhotoPicker_Example
//
//  Created by bswh on 2025/9/12.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import UIKit
import PhotosUI
import SnapKit

let kstickerToolsViewHeight = 166.h
let kRatioToolsViewHeight = 193.h

public class EditImageViewController: ZLEditImageViewController {
    var item:TemplateModel? = nil
    var pickerColor:UIColor? = nil
    var currentSticker:EditableStickerView? = nil
    var photos: [UIImage]? = nil
    private var stickerToolsViewBottomConstraint: Constraint?
    private var ratioToolViewBottomConstraint: Constraint?
    private lazy var stickerToolsView = StickerToolsView().cornerRadius(20.w, corners: [.topLeft,.topRight]).backgroundColor(.white)
    private lazy var ratioToolView = RatioToolView().cornerRadius(20.w, corners: [.topLeft,.topRight]).backgroundColor(.white)
    private lazy var statusView = UIView().backgroundColor(kkColorFromHex("F5F5F5"))
    private lazy var topView = TemplateTopView().backgroundColor(kkColorFromHex("F5F5F5"))
    private lazy var contentView = UIView().backgroundColor(.white)
    let toolCollectionView:ToolsCollectionView = {
       let view = ToolsCollectionView()
        view.backgroundColor = kkColorFromHex("F5F5F5")
        return view
    }()

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = kkColorFromHex("F5F5F5")
        NotificationCenter.default.addObserver(self, selector: #selector(tapStickerOutOverlay(_:)), name: Notification.Name(rawValue: "tapStickerOutOverlay"), object: nil)
        view.addSubview(statusView)
        view.addSubview(topView)
        view.addSubview(contentView)
        view.addSubview(toolCollectionView)
        view.addSubview(stickerToolsView)
        view.addSubview(ratioToolView)
        
        stickerToolsView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(kstickerToolsViewHeight)
            self.stickerToolsViewBottomConstraint = make.bottom.equalToSuperview().offset(kstickerToolsViewHeight).constraint
        }
        stickerToolsView.delegate = self
        
        ratioToolView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(kRatioToolsViewHeight)
            self.ratioToolViewBottomConstraint = make.bottom.equalToSuperview().offset(kRatioToolsViewHeight).constraint
        }
        ratioToolView.delegate = self
        
        statusView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.height.equalTo(kkSAFE_AREA_TOP)
            make.left.right.equalToSuperview()
        }
        
        topView.snp.makeConstraints { make in
            make.top.equalTo(statusView.snp.bottom)
            make.height.equalTo(44.h)
            make.left.right.equalToSuperview()
        }
        topView.delegate = self
        
        toolCollectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(120.h)
        }
        toolCollectionView.delegate = self
        if let name = item?.jsonName, name.count > 0 {
            StickerManager.shared.initCurrentTemplate(jsonName: item!.jsonName!, currentVC: self, photos: photos)
        }else{
            StickerManager.shared.getCurrentVC(currentVC: self)
        }
        backAndreBackStatus()
        
        stickerToolsView.onClose = {
            self.hideBottomPanel()
            if let sticker = self.currentSticker {
                if sticker.imageMask == "addEmptyImage" {
                    self.imageView.image = UIImage(data: self.currentSticker!.imageData!)?.forceRGBA()
                }
            }
        }
        ratioToolView.onClose = {
            self.hideRatioBottomPanel()
            if let sticker = self.currentSticker {
                if sticker.imageMask == "addEmptyImage" {
                    self.imageView.image = UIImage(data: self.currentSticker!.imageData!)?.forceRGBA()
                }
            }
        }
        
        contentView.snp.makeConstraints { make in
            make.width.equalTo(kkScreenWidth)
            make.left.equalToSuperview().offset(0)
            make.height.equalTo(kkScreenHeight - kstickerToolsViewHeight - kkSAFE_AREA_TOP)
            make.top.equalTo(topView.snp.bottom).offset(0)
        }
        contentView.addSubview(mainScrollView)
        mainScrollView.snp.makeConstraints { make in
            make.width.equalTo(kkScreenWidth)
            make.left.equalToSuperview().offset(0)
            make.height.equalToSuperview()
            make.top.equalTo(topView.snp.bottom).offset(0)
        }
        contentView.layoutIfNeeded()
        resetContainerViewFrame()
        mainScrollView.backgroundColor = kkColorFromHex("F5F5F5")
        mainScrollView.showsVerticalScrollIndicator = false
        mainScrollView.showsHorizontalScrollIndicator = false
        //根据调整后的containerView布局里面的贴纸
        if item?.isNeedFit == true {
            convertStickerFrames(stickers: StickerManager.shared.stickerArr, oldSize: BSWHBundle.image(named: item!.imageBg)!.size, newSize: containerView.frame.size, mode: .fit)
        }
        
        if item?.cornerRadius != 0.0 {
            containerView.cornerRadius(item!.cornerRadius)
        }
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        contentView.snp.makeConstraints { make in
            make.width.equalTo(kkScreenWidth)
            make.left.equalToSuperview().offset(0)
            make.height.equalTo(kkScreenHeight - kstickerToolsViewHeight - kkSAFE_AREA_TOP)
            make.top.equalTo(topView.snp.bottom).offset(0)
        }
        contentView.addSubview(mainScrollView)
        mainScrollView.snp.makeConstraints { make in
            make.width.equalTo(kkScreenWidth)
            make.left.equalToSuperview().offset(0)
            make.height.equalToSuperview()
            make.top.equalTo(topView.snp.bottom).offset(0)
        }
        contentView.layoutIfNeeded()
        resetContainerViewFrame()
    }
    
    
    @objc private func onClickMenu(_ sender: UIButton) {
        /// 绘制
        let drawAction = UIAlertAction(title: "Draw", style: .default) { [weak self] _ in
            guard let `self` = self else { return }
//            self.switchOperation(type: .draw)
            let vc = DrawViewController()
            vc.bgImageFrame  = imageView.frame
            vc.modalPresentationStyle = .overFullScreen
            vc.onDrawingExported = { [weak self] exportedImage,rect in
                guard let self = self else { return }
                self.switchOperation(type: .imageSticker)
                let state: ImageStickerModel = ImageStickerModel(image: exportedImage,originFrame: CGRect(x: rect.origin.x / (kkScreenWidth / 375.0), y: rect.origin.y / (kkScreenHeight / 812.0), width: rect.size.width / (kkScreenWidth / 375.0), height: rect.size.height / (kkScreenHeight / 812.0)),gesScale: 1,gesRotation: 0,isBgImage: false)
                let sticker = self.addImageSticker01(state: state)
                sticker.stickerModel = state
                StickerManager.shared.modelMap[sticker.id] = state
            }
            present(vc, animated: false)
        }
    }

    // MARK: - Action
    @objc func tapStickerOutOverlay(_ notification: Notification){
        let dict = notification.object as! [String:Any]
        let sticker:EditableStickerView = dict["sticker"] as! EditableStickerView
    
        if let _ = dict["leftTopTap"] as? Int {
            hideRatioBottomPanel()
            hideBottomPanel()
            return
        }
        hideRatioBottomPanel()
        guard let _ = sticker.stickerModel else {
            hideBottomPanel()
            return
        }
        
        currentSticker = sticker
        if sticker.isEditingCustom {
            showBottomPanel()
            sticker.layoutSubviews()
        } else {
            hideBottomPanel()
        }

        if sticker.stickerModel?.imageName == "Travel-sticker-bg06" {
            if sticker.imageData != BSWHBundle.image(named: "addEmptyImage")?.pngData() {
                imageView.image = UIImage(data: (sticker.stickerModel?.imageData)!)?.forceRGBA()
            }else{
                imageView.image = BSWHBundle.image(named: "Travel07-bg")?.forceRGBA()
            }
        }else if sticker.stickerModel?.imageName == "Birthday02-sticker-bg00" {
            if sticker.imageData != BSWHBundle.image(named: "addEmptyImage")?.pngData() {
                imageView.image = UIImage(data: (sticker.stickerModel?.imageData)!)?.forceRGBA()
            }else{
                imageView.image = BSWHBundle.image(named: "Birthday02-bg")?.forceRGBA()
            }
        }
    }
    
    // MARK: - ratioToolView 隐藏显示处理
    @objc func showRatioBottomPanel() {
        topView.hidden(true)
        topView.snp.remakeConstraints { make in
            make.top.equalTo(statusView.snp.bottom)
            make.height.equalTo(0.h)
            make.left.right.equalToSuperview()
        }
        contentView.snp.remakeConstraints { make in
            make.width.equalTo(kkScreenWidth)
            make.left.equalToSuperview().offset(0)
            make.height.equalTo(kkScreenHeight - kRatioToolsViewHeight - kkSAFE_AREA_TOP)
            make.top.equalTo(topView.snp.bottom).offset(0)
        }
        contentView.addSubview(mainScrollView)
        mainScrollView.snp.remakeConstraints { make in
            make.width.equalTo(kkScreenWidth)
            make.left.equalToSuperview().offset(0)
            make.height.equalToSuperview()
            make.top.equalTo(topView.snp.bottom).offset(0)
        }
        contentView.layoutIfNeeded()
        resetContainerViewFrame()
        
        self.ratioToolViewBottomConstraint?.update(offset: 0)
        UIView.animate(withDuration: 0.25) { [self] in
            self.view.layoutIfNeeded()
        }
    }

    /// 隐藏
    func hideRatioBottomPanel() {
        topView.hidden(false)
        topView.snp.remakeConstraints { make in
            make.top.equalTo(statusView.snp.bottom)
            make.height.equalTo(44.h)
            make.left.right.equalToSuperview()
        }
        contentView.snp.remakeConstraints { make in
            make.width.equalTo(kkScreenWidth)
            make.left.equalToSuperview().offset(0)
            make.height.equalTo(kkScreenHeight - kRatioToolsViewHeight - kkSAFE_AREA_TOP)
            make.top.equalTo(topView.snp.bottom).offset(0)
        }
        contentView.addSubview(mainScrollView)
        mainScrollView.snp.remakeConstraints { make in
            make.width.equalTo(kkScreenWidth)
            make.left.equalToSuperview().offset(0)
            make.height.equalToSuperview()
            make.top.equalTo(topView.snp.bottom).offset(0)
        }
        contentView.layoutIfNeeded()
        resetContainerViewFrame()
        
        self.ratioToolViewBottomConstraint?.update(offset: kRatioToolsViewHeight)
        UIView.animate(withDuration: 0.25) { [self] in
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - stickerToolsView 隐藏显示处理
    @objc func showBottomPanel() {
        topView.hidden(true)
        topView.snp.updateConstraints { make in
            make.top.equalTo(statusView.snp.bottom)
            make.height.equalTo(0.h)
            make.left.right.equalToSuperview()
        }
        contentView.snp.updateConstraints { make in
            make.width.equalTo(kkScreenWidth)
            make.left.equalToSuperview().offset(0)
            make.height.equalTo(kkScreenHeight - kstickerToolsViewHeight - kkSAFE_AREA_TOP)
            make.top.equalTo(topView.snp.bottom).offset(0)
        }
        contentView.addSubview(mainScrollView)
        mainScrollView.snp.updateConstraints { make in
            make.width.equalTo(kkScreenWidth)
            make.left.equalToSuperview().offset(0)
            make.height.equalToSuperview()
            make.top.equalTo(topView.snp.bottom).offset(0)
        }
        contentView.layoutIfNeeded()
        resetContainerViewFrame()
        
        self.stickerToolsViewBottomConstraint?.update(offset: 0)
        UIView.animate(withDuration: 0.25) { [self] in
            self.view.layoutIfNeeded()
            if let sticker = currentSticker {
                sticker.setOperation01(true)
                sticker.isEditingCustom = true
                sticker.syncResizeButtonToOverlay()
                sticker.setOperation01(false)
            }
        }
    }

    /// 隐藏
    func hideBottomPanel() {
        topView.hidden(false)
        topView.snp.remakeConstraints { make in
            make.top.equalTo(statusView.snp.bottom)
            make.height.equalTo(44.h)
            make.left.right.equalToSuperview()
        }
        contentView.snp.remakeConstraints { make in
            make.width.equalTo(kkScreenWidth)
            make.left.equalToSuperview().offset(0)
            make.height.equalTo(kkScreenHeight - kstickerToolsViewHeight - kkSAFE_AREA_TOP)
            make.top.equalTo(topView.snp.bottom).offset(0)
        }
        contentView.addSubview(mainScrollView)
        mainScrollView.snp.remakeConstraints { make in
            make.width.equalTo(kkScreenWidth)
            make.left.equalToSuperview().offset(0)
            make.height.equalToSuperview()
            make.top.equalTo(topView.snp.bottom).offset(0)
        }
        contentView.layoutIfNeeded()
        resetContainerViewFrame()
        
        if let sticker = currentSticker {
            sticker.isEditingCustom = false
        }
        self.stickerToolsViewBottomConstraint?.update(offset: kstickerToolsViewHeight)
        UIView.animate(withDuration: 0.25) { [self] in
            self.view.layoutIfNeeded()
            if let sticker = currentSticker {
                sticker.setOperation01(true)
                sticker.isEditingCustom = false
                sticker.syncResizeButtonToOverlay()
                sticker.setOperation01(false)
            }
        }
    }
    
    public func backAndreBackStatus(){
        if canRedo {
            topView.backImg.image(BSWHBundle.image(named: "template-back"))
        }else{
            topView.backImg.image(BSWHBundle.image(named: "template-back-lignt"))
        }
        
        if canUndo {
            topView.rebackImg.image(BSWHBundle.image(named: "template-reBack"))
        }else{
            topView.rebackImg.image(BSWHBundle.image(named: "template-reBack-light"))
        }
    }

}


