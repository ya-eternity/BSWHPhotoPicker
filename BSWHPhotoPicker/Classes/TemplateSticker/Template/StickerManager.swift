//
//  StickerManager.swift
//  BSWHPhotoPicker_Example
//
//  Created by 笔尚文化 on 2025/10/16.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import UIKit
import Photos
import PhotosUI
import ObjectiveC
 
public protocol StickerManagerDelegate: AnyObject {
    /// 替换背景，传入本控制器和返回图片的大小，返回处理好的图片
    func replaceBackgroundWith(
            controller: EditImageViewController,
            imageRect:CGRect,
            completion: @escaping (UIImage?) -> Void
        )
    /// 添加贴纸，传入本控制器，返回选择的贴纸图片
    func addStickerImage(
            controller: EditImageViewController,
            completion: @escaping (UIImage?) -> Void
        )
    /// 裁剪贴纸，传入本控制器，返回裁剪编辑后的图片
    func cropStickerImage(
            controller: EditImageViewController,
            completion: @escaping (UIImage?) -> Void
        )
    
    func didSelectedTemplate(
            tempalte: TemplateModel,
            completion: @escaping () -> Void
        )
}

// MARK: - StickerManager
public final class StickerManager: NSObject {
    weak var controller: EditImageViewController?
    private weak var currentStickerView: ZLImageStickerView?
    var modelMap: [String: ImageStickerModel] = [:]
    var stickerArr: [EditableStickerView] = []
    public weak var delegate: StickerManagerDelegate?
    var persentType:Int = 0
    var templateOrBackground:Int = 0
    public var selectedTemplateIndex = 0
    public static let shared = StickerManager()
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(duplicateSticker(_:)),
            name: Notification.Name("duplicateSticker"),
            object: nil
        )
        NotificationCenter.default.addObserver(self, selector: #selector(addTap(_:)), name: Notification.Name(rawValue: "stickerImageAddTap"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(duplicateTextSticker(_:)), name: Notification.Name(rawValue: "duplicateTextSticker"), object: nil)
    }

    /// 使用本地Json加载模版
    func initCurrentTemplate(jsonName:String,currentVC:EditImageViewController, photos: [UIImage]? = nil){
        let items = StickerManager.shared.loadLocalJSON(fileName: jsonName, type: [ImageStickerModel].self)
        StickerManager.shared.modelMap.removeAll()
        StickerManager.shared.stickerArr.removeAll()
        controller = currentVC
        var photoIdx = 0
        for (index,state) in items!.enumerated() {
            state.zIndex = index
            let sticker = currentVC.addImageSticker01(state: state)
            sticker.stickerModel = state
            StickerManager.shared.modelMap[sticker.id] = state
            StickerManager.shared.stickerArr.append(sticker)
            if state.isBgImage == true {
                let tap = UITapGestureRecognizer(target: self, action: #selector(stickerTapped(_:)))
                sticker.addGestureRecognizer(tap)
                sticker.isUserInteractionEnabled = true
                if let photos = photos, photoIdx < photos.count, state.bgAddImageType == "addGrayImage" || state.bgAddImageType == "addWhiteImage" {
                    sticker.updateImage(photos[photoIdx], stickerModel: sticker.stickerModel!, withBaseImage: sticker.image,vc: controller!)
                    photoIdx += 1
                    continue
                }
                if let image = sticker.stickerModel?.stickerImage {
                    sticker.updateImage(image, stickerModel: sticker.stickerModel!, withBaseImage: sticker.image,vc: controller!)
                }
            }
        }
    }
    
    func getCurrentVC(currentVC:EditImageViewController) {
        controller = currentVC
    }
    // MARK: 加载本地 JSON
    func loadLocalJSON<T: Decodable>(fileName: String, type: T.Type) -> T? {
        let bundle = BSWHBundle.bundle() 
        guard let url = bundle.url(forResource: fileName, withExtension: "json") else {
            print("❌ 未找到 \(fileName).json")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("❌ 解析 \(fileName).json 失败：\(error)")
            return nil
        }
    }

// MARK: - 点击事件处理
    @objc func duplicateSticker(_ notification: Notification){
        let dict = notification.object as! [String:Any]
        let stickerOld:EditableStickerView = dict["sticker"] as! EditableStickerView
        let stateTmp:ImageStickerModel = StickerManager.shared.modelMap[stickerOld.id]!;
        let state = stateTmp.deepCopy()
        state.originFrameX = state.originFrameX + stickerOld.totalTranslationPoint.x + 35
        state.originFrameY = state.originFrameY + stickerOld.totalTranslationPoint.y + 35
        state.originAngle = stickerOld.originAngle
        state.originScale = stickerOld.originScale
        state.gesRotation = stickerOld.gesRotation
        state.imageMask = stickerOld.imageMask
        if state.imageName == "empty" {
            state.bgAddImageType = stateTmp.bgAddImageType
        }
        if state.imageName == "empty"  && stateTmp.imageData != nil{
            state.imageData = stateTmp.imageData
        }
        state.image = stickerOld.image
        let sticker = controller!.addImageSticker01(state: state)
        sticker.stickerModel = state
        StickerManager.shared.modelMap[sticker.id] = state
        if state.isBgImage == true {
            let tap = UITapGestureRecognizer(target: self, action: #selector(stickerTapped(_:)))
            sticker.addGestureRecognizer(tap)
            sticker.isUserInteractionEnabled = true
            let selectedImage: UIImage = (sticker.stickerModel?.stickerImage)!
            sticker.updateImage(selectedImage, stickerModel: sticker.stickerModel!, withBaseImage: sticker.image,vc: controller!)
        }
    }

    @objc func duplicateTextSticker(_ notification: Notification) {
        let dict = notification.object as! [String:Any]
        let stickerOld:EditableTextStickerView = dict["sticker"] as! EditableTextStickerView
        let newPoint = CGPoint(x: stickerOld.state.totalTranslationPoint.x + 35, y: stickerOld.state.totalTranslationPoint.y + 35)
        let _ = controller!.addTextStickersView01(stickerOld.text,
                                                  textColor: stickerOld.textColor,
                                                  font: stickerOld.font ?? UIFont.systemFont(ofSize: 32),
                                                  image: stickerOld.image,
                                                  style: stickerOld.style,
                                                  originFrame: stickerOld.state.originFrame,
                                                  originScale: stickerOld.state.originScale,
                                                  originAngle: stickerOld.state.originAngle,
                                                  gesScale: stickerOld.state.gesScale,
                                                  gesRotation: stickerOld.state.gesRotation,
                                                  totalTranslationPoint: newPoint)
    }
    
    @objc func addTap(_ notification: Notification) {
        let dict = notification.object as! [String:Any]
        let sticker:EditableStickerView = dict["sticker"] as! EditableStickerView
        sticker.stickerModel = StickerManager.shared.modelMap[sticker.id]
        let tap = UITapGestureRecognizer(target: self, action: #selector(stickerTapped(_:)))
        sticker.addGestureRecognizer(tap)
        sticker.isUserInteractionEnabled = true
//        let selectedImage: UIImage = sticker.stickerModel?.stickerImage ?? BSWHBundle.image(named: (sticker.stickerModel?.bgAddImageType)!)!
        var selectedImage: UIImage = UIImage(data: sticker.state.imageData)!
        if sticker.state.imageData == BSWHBundle.image(named: "addEmptyImage")?.pngData() {
            selectedImage = BSWHBundle.image(named: "Travel07-bg")!
        }
        if let model = sticker.stickerModel {
            sticker.updateImage(selectedImage, stickerModel: model, withBaseImage: sticker.image,vc: controller!)
        }
        
    }
    
    @objc func stickerTapped(_ sender: UITapGestureRecognizer) {
        guard let stickerView = sender.view as? EditableStickerView else { return }
        currentStickerView = stickerView

        let size = CGSize(width: stickerView.stickerModel!.originFrameWidth, height: stickerView.stickerModel!.originFrameHeight)
        let overlayRect = CGRect(
            x: size.width * (stickerView.stickerModel!.overlayRectX ?? 0),
            y: size.height * (stickerView.stickerModel!.overlayRectY ?? 0),
            width: size.width * (stickerView.stickerModel!.overlayRectWidth ?? 0.8),
            height: size.height * (stickerView.stickerModel!.overlayRectHeight ?? 0.8)
        )
        
        let point = sender.location(in: stickerView)
        if stickerView.stickerModel?.imageName == "empty" {
            stickerView.isEditingCustom = !stickerView.isEditingCustom
            NotificationCenter.default.post(name: Notification.Name(rawValue: "tapStickerOutOverlay"), object: ["sticker":stickerView])
            return
        }
        
        if overlayRect.contains(point) {
            print("👉 点击在 overlay 区域内")
            
            if stickerView.state.imageData != BSWHBundle.image(named: stickerView.stickerModel!.bgAddImageType!)?.pngData(){
                stickerView.isEditingCustom = !stickerView.isEditingCustom
                NotificationCenter.default.post(name: Notification.Name(rawValue: "tapStickerOutOverlay"), object: ["sticker":stickerView])
            }else{
                checkPhotoAuthorizationAndPresentPicker()
            }
        } else {
            print("👉 点击在 overlay 区域外")
            stickerView.isEditingCustom = !stickerView.isEditingCustom
            NotificationCenter.default.post(name: Notification.Name(rawValue: "tapStickerOutOverlay"), object: ["sticker":stickerView])
        }
    }
}

extension StickerManager: PHPickerViewControllerDelegate {

    func checkPhotoAuthorizationAndPresentPicker(presentTypeFrom:Int = 0) {
        persentType = presentTypeFrom
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            presentPhotoPicker()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self.presentPhotoPicker()
                    } else {
                        self.showPhotoPermissionAlert()
                    }
                }
            }
        case .denied, .restricted:
            showPhotoPermissionAlert()
        @unknown default:
            showPhotoPermissionAlert()
        }
    }

    func presentPhotoPicker() {
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        config.filter = .images
        config.selectionLimit = 1  // 选择 1 张，可改为 0 表示无限制
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        self.controller!.present(picker, animated: true)
    }

    // 相册选择回调
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let result = results.first else { return }
        let provider = result.itemProvider

        if persentType == 0 {
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                    guard let self = self,
                    let newImage:UIImage = image as? UIImage,
                    let stickerView = self.currentStickerView else { return }
                    
                    DispatchQueue.global(qos: .userInitiated).async {
                        if let imageData = newImage.pngData() {
                            DispatchQueue.main.async { [self] in
                                stickerView.setOperation(true)
                                let oldState = stickerView.state
                                if stickerView.stickerModel?.isBgImage == true {
                                    stickerView.stickerModel?.imageData = imageData
                                    
                                    stickerView.updateImage(newImage, stickerModel: stickerView.stickerModel!, withBaseImage: stickerView.image,vc: self.controller!)
                    
                                    stickerView.imageData = imageData
                                    stickerView.state.imageData = imageData
                                    let newState = stickerView.state
                                    stickerView.setOperation02(false,oldState:oldState,newState:newState)
                                }
                                self.controller?.backAndreBackStatus()
                            }
                        }
                    }
                }
            }
        }else{
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                    guard let self = self,
                    let newImage:UIImage = image as? UIImage else { return }
                    DispatchQueue.main.async { [self] in
                        self.controller!.switchOperation(type: .imageSticker)
                        let state: ImageStickerModel = ImageStickerModel(imageName: "empty",imageData:newImage.pngData(), originFrame: CGRect(x: 40, y: 100, width: 120, height: 120),gesScale: 1,gesRotation: 0,overlayRect: CGRect(x:0,y: 0,width: 1,height: 1) ,isBgImage: true)
                        let sticker = self.controller!.addImageSticker01(state: state)
                        sticker.stickerModel = state
                        StickerManager.shared.modelMap[sticker.id] = state
                        StickerManager.shared.stickerArr.append(sticker)
                        let tap = UITapGestureRecognizer(target: self, action: #selector(self.stickerTapped(_:)))
                        sticker.addGestureRecognizer(tap)
                        if let image = sticker.stickerModel?.stickerImage {
                            sticker.updateImage(image, stickerModel: sticker.stickerModel!, withBaseImage: sticker.image,vc: self.controller!)
                        }
                        self.controller?.backAndreBackStatus()
                    }
                }
            }
        }
    }
}

/// 选择照片
extension StickerManager {
    public func pickerImage(_ image: UIImage) {
        let newImage:UIImage = image
        guard let stickerView = self.currentStickerView else { return }
        DispatchQueue.main.async { [self] in
            if stickerView.stickerModel?.isBgImage == true {
                if let imageData = newImage.pngData() {
                    stickerView.stickerModel?.imageData = imageData
                }
                stickerView.updateImage(newImage, stickerModel: stickerView.stickerModel!, withBaseImage: stickerView.image,vc: self.controller!)
            }
        }
    }
}

// MARK: - 关联属性扩展
private var stickerIDKey: UInt8 = 0
private var stickerModelKey: UInt8 = 0
private var stickerImageKey: UInt8 = 0
extension ZLImageStickerView {
    var stickerID: String? {
        get { objc_getAssociatedObject(self, &stickerIDKey) as? String }
        set { objc_setAssociatedObject(self, &stickerIDKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    var stickerModel: ImageStickerModel? {
        get { objc_getAssociatedObject(self, &stickerModelKey) as? ImageStickerModel }
        set { objc_setAssociatedObject(self, &stickerModelKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    func updateImage(_ newImage: UIImage, stickerModel: ImageStickerModel, withBaseImage baseImage: UIImage? = nil,vc:EditImageViewController) {
        
        let imageTypeRaw = stickerModel.imageType?.rawValue
        var finalImage: UIImage?
        
        // MARK: - 不规则形状
        if imageTypeRaw == "IrregularShape" {
            if !stickerModel.imageName.isEmpty,
               !stickerModel.imageMask!.isEmpty,
               let base = BSWHBundle.image(named: stickerModel.imageName),
               let frame = BSWHBundle.image(named: stickerModel.imageMask!) {
                
                if stickerModel.imageMask == "addEmptyImage" {
                    vc.imageView.contentMode(.scaleAspectFill)

                    if stickerModel.imageName == "Travel-sticker-bg06" {
                        if stickerModel.imageData == nil {
                            vc.imageView.image = BSWHBundle.image(named: "Travel07-bg")
                        }else{
                            vc.imageView.image = newImage.forceRGBA()
                         }
                    }else if stickerModel.imageName == "Birthday02-sticker-bg00" {
                        if stickerModel.imageData == nil {
                            vc.imageView.image = BSWHBundle.image(named: "Travel07-bg")
                        }else{
                            vc.imageView.image = newImage.forceRGBA()
                         }
                    }
                    finalImage = overlayImageWithFrame(BSWHBundle.image(named: "Birthday02-sticker-bg00")!, baseImage: base, frameImage: frame)
                }else{
                    finalImage = overlayImageWithFrame(newImage, baseImage: base, frameImage: frame)
                }
            }
        }else if imageTypeRaw == "IrregularMask" {
            if !stickerModel.imageName.isEmpty,
               !stickerModel.imageMask!.isEmpty,
               let base = BSWHBundle.image(named: stickerModel.imageName),
               let frame = BSWHBundle.image(named: stickerModel.imageMask!) {
                var inset = 20.0
                var xset = 0.0
                var yset = 0.0
                if stickerModel.imageMask == "baby04-sticker-bg00" {
                    inset = 25
                    xset = 0.0
                    yset = -5.0
                }
                finalImage = IrregularMaskOverlayImageWithFrame(newImage, baseImage: base, frameImage: frame,inset: inset,xSet: xset,ySet: yset)
            }
        } else {
            // MARK: - 常规形状
            guard let base = baseImage else {
                finalImage = newImage
                return
            }
            
            let size = base.size
            finalImage = UIGraphicsImageRenderer(size: size).image { _ in
                // 绘制底图
                base.draw(in: CGRect(origin: .zero, size: size))
                
                // overlayRect
                let overlayRect = CGRect(
                    x: size.width * (stickerModel.overlayRectX ?? 0),
                    y: size.height * (stickerModel.overlayRectY ?? 0),
                    width: size.width * (stickerModel.overlayRectWidth ?? 0.8),
                    height: size.height * (stickerModel.overlayRectHeight ?? 0.8)
                )
                
                // 裁剪路径
                let path: UIBezierPath = {
                    switch imageTypeRaw {
                    case "circle", "ellipse":
                        return UIBezierPath(ovalIn: overlayRect)
                    case "square":
                        return UIBezierPath(rect: overlayRect)
                    case "rectangle":
//                        let cornerRadius = min(overlayRect.width, overlayRect.height) * (stickerModel.cornerRadiusScale ?? 0.1)
                        var cornerRadius = 16.0.h
                        if stickerModel.imageName == "Travel-sticker-bg03" {
                            cornerRadius = 50.h
                        }
                        return UIBezierPath(roundedRect: overlayRect, cornerRadius: cornerRadius)
                    default:
                        return UIBezierPath(rect: overlayRect)
                    }
                }()
                path.addClip()
                
                // 计算绘制区域，保持比例填充 overlayRect
                let imageSize = newImage.size
                let rectAspect = overlayRect.width / overlayRect.height
                let imageAspect = imageSize.width / imageSize.height
                
                let drawRect: CGRect
                if imageAspect > rectAspect {
                    let scale = overlayRect.height / imageSize.height
                    let drawWidth = imageSize.width * scale
                    let x = overlayRect.origin.x - (drawWidth - overlayRect.width) / 2
                    drawRect = CGRect(x: x, y: overlayRect.origin.y, width: drawWidth, height: overlayRect.height)
                } else {
                    let scale = overlayRect.width / imageSize.width
                    let drawHeight = imageSize.height * scale
                    let y = overlayRect.origin.y - (drawHeight - overlayRect.height) / 2
                    drawRect = CGRect(x: overlayRect.origin.x, y: y, width: overlayRect.width, height: drawHeight)
                }
                
                // 绘制 newImage
                newImage.draw(in: drawRect, blendMode: .normal, alpha: 1.0)
            }
        }
        
        // MARK: - 更新 UIImageView 或 self.image
        if let imageView = self.subviews.compactMap({ $0 as? UIImageView }).first {
            imageView.image = finalImage?.forceRGBA()
            imageView.setNeedsDisplay()
        } else if let finalImage = finalImage {
            self.image = finalImage
        }
        
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }

    
    func overlayImageWithFrame(_ newImage: UIImage, baseImage: UIImage, frameImage: UIImage) -> UIImage {
        let size = baseImage.size
        
        guard let baseCG = baseImage.cgImage else { return baseImage }
        
        let width = baseCG.width
        let height = baseCG.height
        let bitsPerComponent = 8
        let bytesPerRow = width
        var alphaData = [UInt8](repeating: 0, count: width * height)
        
        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let context = CGContext(data: &alphaData,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: 0) else { return baseImage }
        context.draw(baseCG, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var flippedAlpha = [UInt8](repeating: 0, count: width * height)
        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                let flippedIndex = (height - 1 - y) * width + x
                flippedAlpha[flippedIndex] = alphaData[index] > 0 ? 0 : 255
            }
        }
        
        guard let maskProvider = CGDataProvider(data: NSData(bytes: &flippedAlpha, length: flippedAlpha.count)) else { return baseImage }
        guard let mask = CGImage(maskWidth: width,
                                 height: height,
                                 bitsPerComponent: bitsPerComponent,
                                 bitsPerPixel: bitsPerComponent,
                                 bytesPerRow: bytesPerRow,
                                 provider: maskProvider,
                                 decode: nil,
                                 shouldInterpolate: false) else { return baseImage }
        
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let cgContext = ctx.cgContext
            
            baseImage.draw(in: CGRect(origin: .zero, size: size))
            
            cgContext.saveGState()
            cgContext.clip(to: CGRect(origin: .zero, size: size), mask: mask)
            
            let scaleW = size.width / newImage.size.width
            let scaleH = size.height / newImage.size.height
            let scale = max(scaleW, scaleH)
            let newWidth = newImage.size.width * scale
            let newHeight = newImage.size.height * scale
            let originX = (size.width - newWidth) / 2
            let originY = (size.height - newHeight) / 2
            let imageRect = CGRect(x: originX, y: originY, width: newWidth, height: newHeight)
            
            newImage.draw(in: imageRect)
            cgContext.restoreGState()
            
            frameImage.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    func IrregularMaskOverlayImageWithFrame(_ newImage: UIImage,
                                   baseImage: UIImage,
                                            frameImage: UIImage,inset:CGFloat = 20,xSet:CGFloat = 0,ySet:CGFloat = 0) -> UIImage {

            let size = frameImage.size
            return UIGraphicsImageRenderer(size: size).image { ctx in
                // 计算 baseImage 的绘制区域（Fit 模式）
                let drawRect = CGRect(
                    x: inset + xSet,
                    y: inset + ySet,
                    width: size.width - inset * 2,
                    height: size.height - inset * 2
                )

                let bw = baseImage.size.width
                let bh = baseImage.size.height
                let scaleFit = min(drawRect.width / bw, drawRect.height / bh)
                let baseW = bw * scaleFit
                let baseH = bh * scaleFit
                let baseRect = CGRect(
                    x: drawRect.midX - baseW / 2,
                    y: drawRect.midY - baseH / 2,
                    width: baseW,
                    height: baseH
                )

                // 1️⃣ 先绘制 baseImage
                baseImage.draw(in: baseRect)

                // 2️⃣ 使用 baseImage 的 alpha 作为裁剪区域
                if let cgBase = baseImage.cgImage {
                    ctx.cgContext.saveGState()

                    // 将 context 移动到 baseRect 的位置
                    ctx.cgContext.translateBy(x: baseRect.origin.x, y: baseRect.origin.y)
                    ctx.cgContext.scaleBy(x: baseRect.width / CGFloat(cgBase.width),
                                          y: baseRect.height / CGFloat(cgBase.height))

                    // 使用 alpha 通道裁剪：非透明部分可绘制，透明部分不可绘制
                    ctx.cgContext.clip(to: CGRect(x: 0, y: 0,
                                                  width: cgBase.width,
                                                  height: cgBase.height),
                                       mask: cgBase)

                    // 3️⃣ 绘制 newImage（Fill 模式，铺满整个 baseImage 区域）
                    let nw = newImage.size.width
                    let nh = newImage.size.height
                    let scaleFill = max(CGFloat(cgBase.width) / nw, CGFloat(cgBase.height) / nh)
                    let newW = nw * scaleFill
                    let newH = nh * scaleFill
                    let newRect = CGRect(
                        x: 0 + (CGFloat(cgBase.width) - newW) / 2,
                        y: 0 + (CGFloat(cgBase.height) - newH) / 2,
                        width: newW,
                        height: newH
                    )
                    newImage.draw(in: newRect)

                    ctx.cgContext.restoreGState()
                }

                // 4️⃣ 最后绘制 frameImage
                frameImage.draw(in: CGRect(origin: .zero, size: size))
            }
        }
}


extension StickerManager {
    func showPhotoPermissionAlert() {
        let alert = UIAlertController(
            title: BSWHPhotoPickerLocalization.shared.localized("NoPermission"),
            message: BSWHPhotoPickerLocalization.shared.localized("photoLibrarySettings"),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title:BSWHPhotoPickerLocalization.shared.localized("Cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: BSWHPhotoPickerLocalization.shared.localized("GotoSettings"), style: .default, handler: { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }))

        self.controller!.present(alert, animated: true)
    }
}

