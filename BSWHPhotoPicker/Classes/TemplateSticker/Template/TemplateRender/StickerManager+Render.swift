//
//  StickerManager+Render.swift
//  BSWHPhotoPicker_Example
//
//  Created by 123 on 2025/12/3.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import UIKit

extension StickerManager {
        
    /// 传入背景 + 多张照片，按模板渲染输出成品图
    /// - TemplateModel: 模板
    /// - photos: 按槽位顺序填充
    public func renderTemplateImage(template: TemplateModel,
                                    photos: [UIImage]) -> UIImage? {
        guard let _ = loadLocalJSON(fileName: template.jsonName ?? "", type: [ImageStickerModel].self),
              let image = BSWHBundle.image(named: template.imageBg) else { return nil }
        let controller = EditImageViewController(image: image)
        controller.item = template
        controller.photos = photos
        controller.view.frame = UIScreen.main.bounds
        controller.viewDidLoad()
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: controller.containerView.bounds.size, format: format)
        return renderer.image { ctx in
            controller.containerView.layer.render(in: ctx.cgContext)
        }
    }
        
    /// 按模板输出成品图，完全用 CoreGraphics 计算，不依赖 EditImageViewController/视图渲染
    public func renderTemplateImageCoreGraphics(
        template: TemplateModel,
        photos: [UIImage]
    ) -> UIImage? {
        guard let models = loadLocalJSON(fileName: template.jsonName ?? "", type: [ImageStickerModel].self),
              let bgImage = BSWHBundle.image(named: template.imageBg) else { return nil }
        
        let canvasSize = bgImage.size
        let scaleW = canvasSize.width / 375.0
//        let scaleH = canvasSize.height / 812.0
        
        // 保持模板原始顺序作为 zIndex 默认值
        let orderedModels = models.enumerated().map { idx, model -> ImageStickerModel in
            model.zIndex = model.zIndex ?? idx
            return model
        }.sorted { ($0.zIndex ?? 0) < ($1.zIndex ?? 0) }
        
        var photoIdx = 0
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3
        format.opaque = false
        
        return UIGraphicsImageRenderer(size: canvasSize, format: format).image { ctx in
            if template.cornerRadius != 0 {
                UIBezierPath(
                    roundedRect: CGRect(origin: .zero, size: canvasSize),
                    cornerRadius: CGFloat(template.cornerRadius)
                ).addClip()
            }
            
            bgImage.draw(in: CGRect(origin: .zero, size: canvasSize))
            
            for model in orderedModels {
                // 需要填充的照片
                var slotImage: UIImage? = nil
                if model.isBgImage {
                    if photoIdx < photos.count && (model.bgAddImageType == "addGrayImage" || model.bgAddImageType == "addWhiteImage") {
                        slotImage = photos[photoIdx]
                        photoIdx += 1
                    } else if let data = model.stickerImage {
                        slotImage = data
                    }
                }
                
                let stickerImage = composeStickerImage(from: model, slotImage: slotImage)
                guard let finalSticker = stickerImage else { continue }
                
                let frame = CGRect(
                    x: CGFloat(model.originFrameX) * scaleW,
                    y: CGFloat(model.originFrameY) * scaleW,
                    width: CGFloat(model.originFrameWidth) * scaleW,
                    height: CGFloat(model.originFrameHeight) * scaleW
                )
                
                let scale = CGFloat(model.originScale * model.gesScale)
                let angle = CGFloat(model.originAngle) * .pi / 180 + CGFloat(model.gesRotation)
                let finalSize = CGSize(width: frame.width * scale, height: frame.height * scale)
                
                ctx.cgContext.saveGState()
                ctx.cgContext.translateBy(x: frame.midX, y: frame.midY)
                ctx.cgContext.rotate(by: angle)
                let drawRect = CGRect(
                    x: -finalSize.width / 2,
                    y: -finalSize.height / 2,
                    width: finalSize.width,
                    height: finalSize.height
                )
                finalSticker.draw(in: drawRect)
                ctx.cgContext.restoreGState()
            }
        }
    }
    
    // MARK: - 绘制辅助
    private func composeStickerImage(from model: ImageStickerModel, slotImage: UIImage?) -> UIImage? {
        let baseImage = model.image ?? (model.imageName.isEmpty ? nil : BSWHBundle.image(named: model.imageName))
        let canvasSize = baseImage?.size ?? CGSize(
            width: CGFloat(model.originFrameWidth),
            height: CGFloat(model.originFrameHeight)
        )
        
        // 需要叠加的内容：优先传入照片，其次模型自带 Data，最后使用基图
        let newImage = slotImage
            ?? (model.imageData.flatMap { UIImage(data: $0) })
            ?? baseImage
        
        guard let newImage else { return baseImage }
        
        let imageTypeRaw = model.imageType?.rawValue ?? "square"
        
        if imageTypeRaw == "IrregularShape" {
            guard
                !model.imageName.isEmpty,
                let maskName = model.imageMask,
                let base = baseImage,
                let frame = BSWHBundle.image(named: maskName)
            else { return baseImage }
            return overlayImageWithFrame(newImage, baseImage: base, frameImage: frame)
        } else if imageTypeRaw == "IrregularMask" {
            guard
                !model.imageName.isEmpty,
                let maskName = model.imageMask,
                let base = baseImage,
                let frame = BSWHBundle.image(named: maskName)
            else { return baseImage }
            
            var inset = 20.0
            var xset = 0.0
            var yset = 0.0
            if maskName == "baby04-sticker-bg00" {
                inset = 25
                xset = 0.0
                yset = -5.0
            }
            return IrregularMaskOverlayImageWithFrame(newImage, baseImage: base, frameImage: frame, inset: inset, xSet: xset, ySet: yset)
        }
        
        guard let base = baseImage else { return newImage }
        let size = base.size
        let overlayRect = CGRect(
            x: size.width * CGFloat(model.overlayRectX ?? 0),
            y: size.height * CGFloat(model.overlayRectY ?? 0),
            width: size.width * CGFloat(model.overlayRectWidth ?? 0.8),
            height: size.height * CGFloat(model.overlayRectHeight ?? 0.8)
        )
        
        return UIGraphicsImageRenderer(size: size).image { _ in
            base.draw(in: CGRect(origin: .zero, size: size))
            
            let path: UIBezierPath = {
                switch imageTypeRaw {
                case "circle", "ellipse":
                    return UIBezierPath(ovalIn: overlayRect)
                case "square":
                    return UIBezierPath(rect: overlayRect)
                case "rectangle":
                    var cornerRadius = 16.0.h
                    if model.imageName == "Travel-sticker-bg03" {
                        cornerRadius = 57.h
                    }
                    return UIBezierPath(roundedRect: overlayRect, cornerRadius: cornerRadius)
                default:
                    return UIBezierPath(rect: overlayRect)
                }
            }()
            path.addClip()
            
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
            
            newImage.draw(in: drawRect, blendMode: .normal, alpha: 1.0)
        }
    }
    
    private func overlayImageWithFrame(_ newImage: UIImage, baseImage: UIImage, frameImage: UIImage) -> UIImage {
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
    
    private func IrregularMaskOverlayImageWithFrame(_ newImage: UIImage,
                                                    baseImage: UIImage,
                                                    frameImage: UIImage,
                                                    inset: CGFloat = 20,
                                                    xSet: CGFloat = 0,
                                                    ySet: CGFloat = 0) -> UIImage {

            let size = frameImage.size
            return UIGraphicsImageRenderer(size: size).image { ctx in
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

                baseImage.draw(in: baseRect)

                if let cgBase = baseImage.cgImage {
                    ctx.cgContext.saveGState()

                    ctx.cgContext.translateBy(x: baseRect.origin.x, y: baseRect.origin.y)
                    ctx.cgContext.scaleBy(x: baseRect.width / CGFloat(cgBase.width),
                                          y: baseRect.height / CGFloat(cgBase.height))

                    ctx.cgContext.clip(to: CGRect(x: 0, y: 0,
                                                  width: cgBase.width,
                                                  height: cgBase.height),
                                       mask: cgBase)

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

                frameImage.draw(in: CGRect(origin: .zero, size: size))
            }
        }
}
