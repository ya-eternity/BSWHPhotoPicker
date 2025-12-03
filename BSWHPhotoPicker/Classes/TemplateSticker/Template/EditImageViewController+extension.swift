//
//  EditImageViewController+Exstention.swift
//  BSWHPhotoPicker_Example
//
//  Created by 笔尚文化 on 2025/11/14.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import UIKit
import Photos

// MARK: - 顶部工具栏 TemplateTopView-TemplateTopViewDelegate
extension EditImageViewController:TemplateTopViewDelegate {
    func closeTemplate(_ sender: TemplateTopView) {
        dismiss(animated: true)
    }
    func backTemplate(_ sender: TemplateTopView){
        currentSticker = nil
//        hideBottomPanel()
        if canRedo {
            redoAction()
        }
        backAndreBackStatus()
    }
    func reBackTemplate(_ sender: TemplateTopView) {
        currentSticker = nil
//        hideBottomPanel()
        if canUndo {
            undoAction()
        }
        backAndreBackStatus()
    }
    func saveTemplate(_ sender: TemplateTopView) {
        guard let finalImage = renderImage(from: containerView) else { return }
        saveImageToAlbum(finalImage)
    }
    
    
    func renderImage(from view: UIView) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: view.bounds.size, format: format)

        return renderer.image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
    }


    
    func saveImageToAlbum(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized || status == .limited {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            } else {
                DispatchQueue.main.async {
                    self.showAlbumPermissionAlert()
                }
            }
        }
    }

    func showAlbumPermissionAlert() {
        let alert = UIAlertController(
            title: BSWHPhotoPickerLocalization.shared.localized("NoPermission"),
            message: BSWHPhotoPickerLocalization.shared.localized("photoLibrarySettings"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: BSWHPhotoPickerLocalization.shared.localized("Cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: BSWHPhotoPickerLocalization.shared.localized("GotoSettings"), style: .default, handler: { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }))
        present(alert, animated: true)
    }
}

// MARK: - 整体工具栏 ToolsCollectionView-ToolsCollectionViewDelegate
extension EditImageViewController:ToolsCollectionViewDelegate {
    func cellDidSelectItemAt(_ sender: ToolsCollectionView, indexPath: IndexPath) {

        if StickerManager.shared.templateOrBackground == 1 {
            if indexPath.row == 0 {
                addTextView()
            }else if indexPath.row == 1 {
                addPhoto()
            }else if indexPath.row == 2 {
                StickerManager.shared.checkPhotoAuthorizationAndPresentPicker(presentTypeFrom: 1)
            }else if indexPath.row == 3 {
                addStickerView()
            }else if indexPath.row == 4 {
                changeRatio()
            }
        }else if StickerManager.shared.templateOrBackground == 2 {
            if indexPath.row == 0 {
                addTextView()
            }else if indexPath.row == 1 {
                StickerManager.shared.checkPhotoAuthorizationAndPresentPicker(presentTypeFrom: 1)
            }else if indexPath.row == 2 {
                addStickerView()
            }else if indexPath.row == 3 {
                changeRatio()
            }else if indexPath.row == 4 {
            }
        }
    }
    
    func addTextView(){
        self.switchOperation(type: .textSticker)
        self.addTextSticker01(font: UIFont.systemFont(ofSize: 25)) { result in
            if let result = result {
                let sticker = result.sticker
                sticker.frame = result.frame
                let image = sticker.toImage(targetSize: result.frame.size)
                let frame = result.frame
                DispatchQueue.main.async { [self] in
                    self.switchOperation(type: .imageSticker)
                    let state: ImageStickerModel = ImageStickerModel(imageName: "empty",imageData:image.pngData(), originFrame: CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: frame.size.height),gesScale: 1,gesRotation: 0,overlayRect: CGRect(x:0,y: 0,width: 1,height: 1) ,isBgImage: true)
                    state.imageData = image.pngData()
                    let sticker = self.addImageSticker01(state: state)
                    sticker.stickerModel = state
                    StickerManager.shared.modelMap[sticker.id] = state
                    StickerManager.shared.stickerArr.append(sticker)
                    let tap = UITapGestureRecognizer(target: StickerManager.shared, action: #selector(StickerManager.shared.stickerTapped(_:)))
                    sticker.addGestureRecognizer(tap)
                    if let image = sticker.stickerModel?.stickerImage {
                        sticker.updateImage(image, stickerModel: sticker.stickerModel!, withBaseImage: sticker.image,vc: self)
                    }
                    backAndreBackStatus()
                }
            }
        }
    }
    
    func changeRatio(){
        showRatioBottomPanel()
        if let sticker = self.currentSticker {
            if sticker.imageMask == "addEmptyImage" {
                self.imageView.image = UIImage(data: self.currentSticker!.imageData!)?.forceRGBA()
            }
        }
        backAndreBackStatus()
    }
    
    func addPhoto(){
        StickerManager.shared.delegate?.replaceBackgroundWith(controller: self,imageRect: imageView.frame) { [weak self] image in
            guard let self = self else { return }
            if let img = image {
                print("🎉 收到代理返回的图片：\(img)")
                replaceBgImage(image: img)
                resetContainerViewFrame()
//                    convertStickerFrames(stickers: StickerManager.shared.stickerArr, oldSize: BSWHBundle.image(named: item!.imageBg)!.size, newSize: containerView.frame.size, mode: .fit)
            } else {
                print("⚠️ 没有返回图片")
            }
            backAndreBackStatus()
        }
    }
    
    func addStickerView(){
        StickerManager.shared.delegate?.addStickerImage(controller: self) { [weak self] image in
            print("添加贴纸")
            if let img = image {
                DispatchQueue.main.async { [self] in
                    self!.switchOperation(type: .imageSticker)
                    let state: ImageStickerModel = ImageStickerModel(imageName: "empty",imageData:img.pngData(), originFrame: CGRect(x: 240, y: 100, width: 120, height: 120),gesScale: 1,gesRotation: 0,overlayRect: CGRect(x:0,y: 0,width: 1,height: 1) ,isBgImage: true)
                    let sticker = self!.addImageSticker01(state: state)
                    sticker.stickerModel = state
                    StickerManager.shared.modelMap[sticker.id] = state
                    StickerManager.shared.stickerArr.append(sticker)
                    let tap = UITapGestureRecognizer(target: StickerManager.shared, action: #selector(StickerManager.shared.stickerTapped(_:)))
                    sticker.addGestureRecognizer(tap)
                    if let image = sticker.stickerModel?.stickerImage {
                        sticker.updateImage(image, stickerModel: sticker.stickerModel!, withBaseImage: sticker.image,vc: self!)
                    }
                    self!.backAndreBackStatus()
                }
            } else {
                
            }
        }
    }
    
    
}


// MARK: - 贴纸工具栏 StickerToolsView-StickerToolsViewDelegate
extension EditImageViewController:StickerToolsViewDelegate {
    func stickerToolDidSelectItemAt(_ sender: StickerToolsView, indexPath: IndexPath) {
        if indexPath.row == 0 {
            StickerManager.shared.checkPhotoAuthorizationAndPresentPicker()
        }else if indexPath.row == 1 {
            NotificationCenter.default.post(name: Notification.Name("duplicateSticker"), object: ["sticker": currentSticker])
        }else if indexPath.row == 2 {
            if let sticker = currentSticker {
                print("裁剪后的照片")
                StickerManager.shared.delegate?.cropStickerImage(controller: self) { image in
                    if let img = image {
                        if let imageData = img.pngData() {
                            sticker.stickerModel?.imageData = imageData
                        }
                        sticker.updateImage(img, stickerModel: sticker.stickerModel!, withBaseImage: sticker.image,vc: self)
                    } else {
                    }
                }
            }
            
        }else if indexPath.row == 3 {
            if let sticker = currentSticker {
                if let image = sticker.stickerModel?.stickerImage,let newImage = image.flippedHorizontally() {
                    if let imageData = newImage.pngData() {
                        sticker.stickerModel?.imageData = imageData
                    }
                    sticker.updateImage(newImage, stickerModel: sticker.stickerModel!, withBaseImage: sticker.image,vc: self)
                }
            }
        }else if indexPath.row == 4 {
            if let sticker = currentSticker {
                if let image = sticker.stickerModel?.stickerImage,let newImage = image.flippedVertically() {
                    if let imageData = newImage.pngData() {
                        sticker.stickerModel?.imageData = imageData
                    }
                    sticker.updateImage(newImage, stickerModel: sticker.stickerModel!, withBaseImage: sticker.image,vc: self)
                }
            }
        }else if indexPath.row == 5 {
            if let sticker = currentSticker {
//                UIView.animate(withDuration: 0.2) {
//                    sticker.alpha = 0
//                    sticker.leftTopButton.alpha = 0
//                    sticker.resizeButton.alpha = 0
//                    sticker.rightTopButton.alpha = 0
//                } completion: { _ in
//                    sticker.removeFromSuperview()
//                }
//                hideBottomPanel()
                sticker.setOperation(true)
                sticker.gesTranslationPoint = CGPoint(x: 10000, y: 10000)
                sticker.updateTransform01()
                sticker.setOperation(false)
            }
        }
    }
}

// MARK: - 比例工具栏 RatioToolView-RatioToolViewDelegate
extension EditImageViewController:RatioToolViewDelegate {
    func RatioToolViewDidSelectItemAt(_ sender: RatioToolView, indexPath: IndexPath,ratioItem:RatioToolsModel) {
        
        var image:UIImage? = nil
        if item!.imageBg.hasPrefix("#") {
            if let img = kkCommon.imageFromHex(item!.imageBg) {
                image = img
            }
        }else if item!.imageBg == "BackgroundNoColor" {
            if let img = kkCommon.imageFromHex("#FFFFFF",alpha: 0) {
                image = img
            }
        }else if item!.imageBg == "BackgroundPicker" {
            if let color = pickerColor {
                image = UIImage.from(color: color, size: CGSize(width: 400, height: 400))
            }
        }else{
            image = BSWHBundle.image(named: item!.imageBg)
        }
        
        if let squareImage = image!.cropped(toAspectRatioWidth: ratioItem.width, height: ratioItem.height) {
            
            for sticker in StickerManager.shared.stickerArr {
                sticker.removeFromSuperview()
            }
            
            if let name = item?.jsonName, name.count > 0 {
                StickerManager.shared.initCurrentTemplate(jsonName:item!.jsonName!, currentVC: self)
            }else{
                StickerManager.shared.getCurrentVC(currentVC: self)
            }
            
            convertStickerFrames(
                stickers: StickerManager.shared.stickerArr,
                oldSize: image!.size,
                newSize: squareImage.size,mode: .fit
            )
            replaceBgImage(image: squareImage)
            resetContainerViewFrame()
        }
    }
    
    

}

func convertStickerFrames(
    stickers: [EditableStickerView],
    oldSize: CGSize,
    newSize: CGSize,
    mode: CanvasResizeMode
) {
    guard oldSize.width > 0, oldSize.height > 0 else { return }

    // 计算 scale
    let scaleByWidth = newSize.width / oldSize.width
    let scaleByHeight = newSize.height / oldSize.height

    let scale: CGFloat
    switch mode {
    case .byWidth:
        scale = scaleByWidth
    case .byHeight:
        scale = scaleByHeight
    case .fit:
        scale = min(scaleByWidth, scaleByHeight) * (newSize.width / kkScreenWidth)
    }

    let scaledCanvasW = oldSize.width * scale
    let scaledCanvasH = oldSize.height * scale
    let offsetX = (newSize.width - scaledCanvasW) / 2.0
    let offsetY = (newSize.height - scaledCanvasH) / 2.0

    for sticker in stickers {
        let oldCenter = sticker.center
        let newCenter = CGPoint(x: oldCenter.x * scale + offsetX * scale,
                                y: oldCenter.y * scale + offsetY)

        sticker.totalTranslationPoint.x *= scale
        sticker.totalTranslationPoint.y *= scale

        sticker.originScale *= scale

        sticker.gesScale = 1
        // sticker.gesRotation = 0

        sticker.updateTransform()

        sticker.center = newCenter

        sticker.setNeedsLayout()
        sticker.layoutIfNeeded()
        sticker.refreshResizeButtonPosition()

        sticker.originFrame = sticker.frame
        sticker.originTransform = sticker.transform
    }
}

enum CanvasResizeMode {
    case byHeight
    case byWidth
    case fit
}

