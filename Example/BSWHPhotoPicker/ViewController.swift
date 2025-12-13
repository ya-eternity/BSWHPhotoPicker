//
//  ViewController.swift
//  BSWHPhotoPicker
//
//  Created by caoguangming on 09/11/2025.
//  Copyright (c) 2025 caoguangming. All rights reserved.
//

import Localize_Swift

func Localize_Swift_bridge(forKey:String,table:String,fallbackValue:String)->String {
    return forKey.localized(using: table);
}

import UIKit
import BSWHPhotoPicker

class ViewController: UIViewController {
    let backButton01: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("背景列表", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        button.backgroundColor = .blue
        return button
    }()
    
    let backButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("模版列表", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        button.backgroundColor = .blue
        return button
    }()
    
    let lang00Button: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("英文", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        button.backgroundColor = .blue
        return button
    }()
    
    let lang01Button: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("中文", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        button.backgroundColor = .blue
        return button
    }()
    
    let renderBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("渲染", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        button.backgroundColor = .blue
        return button
    }()
    let renderBtn2: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("视频渲染", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        button.backgroundColor = .blue
        return button
    }()
    let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.backgroundColor = .lightGray
        return view
    }()
    
    var count = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(backButton01)
        view.addSubview(backButton)
        view.addSubview(lang00Button)
        view.addSubview(lang01Button)
        view.addSubview(imageView)
        view.addSubview(renderBtn)
        view.addSubview(renderBtn2)

        backButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-200)
            make.width.equalTo(120)
            make.height.equalTo(50)
        }
        
        backButton01.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(backButton.snp.top).offset(-80)
            make.width.equalTo(120)
            make.height.equalTo(50)
        }
        
        lang00Button.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalTo(backButton.snp.bottom).offset(40)
            make.width.equalTo(120)
            make.height.equalTo(50)
        }
        
        lang01Button.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.top.equalTo(backButton.snp.bottom).offset(40)
            make.width.equalTo(120)
            make.height.equalTo(50)
        }
        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(80)
            make.centerX.equalToSuperview()
            make.width.equalTo(300)
            make.height.equalTo(400)
        }
        renderBtn.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalTo(lang01Button.snp.bottom).offset(40)
            make.width.equalTo(120)
            make.height.equalTo(50)
        }
        renderBtn2.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.top.equalTo(lang01Button.snp.bottom).offset(40)
            make.width.equalTo(120)
            make.height.equalTo(50)
        }
        backButton.addTarget(self, action: #selector(onClickBack(_:)), for: .touchUpInside)
        backButton01.addTarget(self, action: #selector(onClickBack01(_:)), for: .touchUpInside)
        lang00Button.addTarget(self, action: #selector(onClickLang00(_:)), for: .touchUpInside)
        lang01Button.addTarget(self, action: #selector(onClickLang01(_:)), for: .touchUpInside)
        renderBtn.addTarget(self, action: #selector(onClickRender(_:)), for: .touchUpInside)
        renderBtn2.addTarget(self, action: #selector(onClickRender2(_:)), for: .touchUpInside)


    }
    @objc private func onClickBack01(_ sender: UIButton) {
        BSWHPhotoPickerLocalization.shared.currentLanguage = "es-MX"
        StickerManager.shared.selectedTemplateIndex = 3
        presentBgVC()
    }
    @objc private func onClickBack(_ sender: UIButton) {

        BSWHPhotoPickerLocalization.shared.currentLanguage = "id"
        StickerManager.shared.selectedTemplateIndex = 3
        presentVC()
    }
    @objc private func onClickLang00(_ sender: UIButton) {
        BSWHPhotoPickerLocalization.shared.currentLanguage = "ar"
        let model:TemplateHomeModel = StickerManager.shared.templateHomeData[1]
        print(model.templateType)
        print(model.image!)
        StickerManager.shared.selectedTemplateIndex = 1
        presentVC()
    }
    @objc private func onClickLang01(_ sender: UIButton) {
        BSWHPhotoPickerLocalization.shared.currentLanguage = "he"
        let model:TemplateHomeModel = StickerManager.shared.backgroundHomeData[1]
        print(model.templateType)
        print(model.image!)
        StickerManager.shared.selectedTemplateIndex = 2
        presentBgVC()
    }
    @objc private func onClickRender(_ sender: UIButton) {
        
        let vc = UINavigationController(rootViewController: TemplateViewController(isSelected: true))
        StickerManager.shared.delegate = self
        vc.modalPresentationStyle = .overFullScreen
        self.present(vc, animated: true)
    }
    @objc private func onClickRender2(_ sender: UIButton) {
        let vc = UINavigationController(rootViewController: TemplateViewController(isSelected: true, forVideo: true))
        StickerManager.shared.delegate = self
        vc.modalPresentationStyle = .overFullScreen
        self.present(vc, animated: true)
    }
    func presentVC(){
        let vc = UINavigationController(rootViewController: TemplateViewController())
        StickerManager.shared.delegate = self
        vc.modalPresentationStyle = .overFullScreen
        self.present(vc, animated: true)
    }
    
    func presentBgVC(){
        let vc = UINavigationController(rootViewController: BackGroundViewController())
        StickerManager.shared.delegate = self
        vc.modalPresentationStyle = .overFullScreen
        self.present(vc, animated: true)
    }
}

extension ViewController: StickerManagerDelegate {
    
    func replaceBackgroundWith(controller: BSWHPhotoPicker.EditImageViewController, imageRect: CGRect, completion: @escaping (UIImage?) -> Void) {
        var img:UIImage? = nil
        if count == 0 {
            img = UIImage(named: "Pattern55")
        }else if count == 1{
            img = UIImage(named: "Texture00")
        }else{
            img = UIImage(named: "Christmas02-bg")
        }
        count += 1
        print("image")
        completion(img!)
    }
    
    func addStickerImage(controller: BSWHPhotoPicker.EditImageViewController, completion: @escaping (UIImage?) -> Void) {
        let img = UIImage(named: "imageSticker000")
        print("image")
        completion(img)
    }
    
    func cropStickerImage(controller: BSWHPhotoPicker.EditImageViewController, completion: @escaping (UIImage?) -> Void) {
        let img = UIImage(named: "imageSticker000")
        print("image")
        completion(img)
    }
    
    func didSelectedTemplate(tempalte: TemplateModel, completion: @escaping () -> Void) {
        imageView.image = StickerManager.shared.renderTemplateImageCoreGraphics(template: tempalte, photos: [UIImage(named: "1")!, UIImage(named: "12")!, UIImage(named: "123")!, UIImage(named: "12")!])
        if let img = imageView.image {
            UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
        }
    }
}

