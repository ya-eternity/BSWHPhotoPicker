//
//  StickerManager+Render.swift
//  BSWHPhotoPicker_Example
//
//  Created by 123 on 2025/12/3.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import UIKit


// MARK: - 预构建模板图层（单槽位）
public struct TemplatePrebuiltLayers {
    public let background: UIImage      // 背景 + 槽位下方元素
    public let overlay: UIImage?        // 槽位上方元素
    public let slotMask: (contentMask: UIImage?, borderMask: UIImage?)        // 槽位遮罩（已包含旋转/缩放）
    public let slotRect: CGRect         // 槽位在画布的原始矩形（未旋转，基于 canvas）
    public let canvasSize: CGSize
}

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
        photos: [UIImage],
        fillColor: UIColor = kkColorFromHex("#F1F1F1")
    ) -> UIImage? {
        guard let models = loadLocalJSON(fileName: template.jsonName ?? "", type: [ImageStickerModel].self),
              let bgImage = BSWHBundle.image(named: template.imageBg) else { return nil }
        
        let canvasSize = bgImage.size
        let scaleW = canvasSize.width / 375.0
        let fillColorImage = UIImage.from(color: fillColor)
        
        // 保持模板原始顺序作为 zIndex 默认值
        var photoIsBg = true
        let orderedModels = models.enumerated().map { idx, model -> ImageStickerModel in
            model.zIndex = model.zIndex ?? idx
            if (model.imageName != "empty") {
                photoIsBg = false
            }
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
            
            if photoIsBg, let photo = photos.first {
                photo.draw(in: rectForCenterCrop(image: photo, in: CGRect(origin: .zero, size: canvasSize)))
            } else if photoIsBg {
                fillColorImage.draw(in: CGRect(origin: .zero, size: canvasSize))
            } else {
                bgImage.draw(in: CGRect(origin: .zero, size: canvasSize))
            }
            
            for model in orderedModels {
                // 需要填充的照片
                var slotImage: UIImage? = nil
                if model.isBgImage {
                    if (model.imageName != "empty") {
                        if photoIdx < photos.count {
                            slotImage = photos[photoIdx]
                            photoIdx += 1
                        } else {
                            slotImage = fillColorImage
                        }
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
    
    private func rectForCenterCrop(image: UIImage, in target: CGRect) -> CGRect {
        let imageSize = image.size
        let targetSize = target.size
        
        let scale = max(targetSize.width / imageSize.width,
                        targetSize.height / imageSize.height)
        
        let scaledWidth = imageSize.width * scale
        let scaledHeight = imageSize.height * scale
        
        let x = target.midX - scaledWidth / 2
        let y = target.midY - scaledHeight / 2
        
        return CGRect(x: x, y: y, width: scaledWidth, height: scaledHeight)
    }

    
      /// 仅支持 photoCount == 1：预生成背景/上层遮罩/槽位遮罩，便于 CI/Metal 合成。
    public func prebuildTemplateLayers(template: TemplateModel) -> TemplatePrebuiltLayers? {
        guard template.photoCount == 1,
              let models = loadLocalJSON(fileName: template.jsonName ?? "", type: [ImageStickerModel].self),
              let bgImage = BSWHBundle.image(named: template.imageBg) else { return nil }

        let canvasSize = bgImage.size
        let scaleW = canvasSize.width / 375.0

        let ordered = models.enumerated().map { idx, m -> ImageStickerModel in
            m.zIndex = idx
            return m
        }.sorted { ($0.zIndex ?? 0) < ($1.zIndex ?? 0) }

        var slotModel: ImageStickerModel
        if let model = ordered.first(where: { $0.isBgImage && ($0.imageName != "empty") }) {
            slotModel = model
        } else {
            slotModel = ImageStickerModel()
            slotModel.zIndex = -1
            slotModel.originFrameX = 0
            slotModel.originFrameY = 0
            slotModel.originFrameWidth = 375.0
            slotModel.originFrameHeight = canvasSize.height/scaleW
        }

        // 背景 + 槽位下方
        let bgUnder = UIGraphicsImageRenderer(size: canvasSize).image { ctx in
            bgImage.draw(in: CGRect(origin: .zero, size: canvasSize))
            for model in ordered {
                guard (model.zIndex ?? 0) <= (slotModel.zIndex ?? 0) else { continue }
                if model === slotModel {
                    if model.imageType != .IrregularMask && model.imageType != .IrregularShape {
                        guard let stickerImage = BSWHBundle.image(named: model.imageName) else { continue }
                        drawSticker(stickerImage, model: model, canvasSize: canvasSize, scaleW: scaleW, in: ctx.cgContext)
                    }
                    continue
                }
                guard let stickerImage = model.stickerImage else { continue }
                drawSticker(stickerImage, model: model, canvasSize: canvasSize, scaleW: scaleW, in: ctx.cgContext)
            }
        }

        // 槽位上方
        let overlay = UIGraphicsImageRenderer(size: canvasSize).image { ctx in
            for model in ordered {
                guard (model.zIndex ?? 0) > (slotModel.zIndex ?? 0) else { continue }
                if model === slotModel { continue }
//                guard let stickerImage = composeStickerImage(from: model, slotImage: model.stickerImage) else { continue }
                guard let stickerImage = model.stickerImage else { continue }
                drawSticker(stickerImage, model: model, canvasSize: canvasSize, scaleW: scaleW, in: ctx.cgContext)
            }
        }

        // 槽位遮罩（含旋转/缩放）
        let maskImage = buildSlotMask(slotModel: slotModel, canvasSize: canvasSize, scaleW: scaleW)

        let slotRect = CGRect(x: CGFloat(slotModel.originFrameX) * scaleW,
                              y: CGFloat(slotModel.originFrameY) * scaleW,
                              width: CGFloat(slotModel.originFrameWidth) * scaleW,
                              height: CGFloat(slotModel.originFrameHeight) * scaleW)

        let overlayClean = overlay.pngData().flatMap { UIImage(data: $0) }

        return TemplatePrebuiltLayers(background: bgUnder,
                                      overlay: overlayClean,
                                      slotMask: maskImage,
                                      slotRect: slotRect,
                                      canvasSize: canvasSize)
    }
    
    private func drawSticker(_ image: UIImage,
                             model: ImageStickerModel,
                             canvasSize: CGSize,
                             scaleW: CGFloat,
                             in ctx: CGContext) {
        let frame = CGRect(
            x: CGFloat(model.originFrameX) * scaleW,
            y: CGFloat(model.originFrameY) * scaleW,
            width: CGFloat(model.originFrameWidth) * scaleW,
            height: CGFloat(model.originFrameHeight) * scaleW
        )
        let scale = CGFloat(model.originScale * model.gesScale)
        let angle = CGFloat(model.originAngle) * .pi / 180 + CGFloat(model.gesRotation)
        let finalSize = CGSize(width: frame.width * scale, height: frame.height * scale)
        
        ctx.saveGState()
        ctx.translateBy(x: frame.midX, y: frame.midY)
        ctx.rotate(by: angle)
        let drawRect = CGRect(
            x: -finalSize.width / 2,
            y: -finalSize.height / 2,
            width: finalSize.width,
            height: finalSize.height
        )
        image.draw(in: drawRect)
        ctx.restoreGState()
    }

    // 与现有绘制辅助放在一起
    private func buildSlotMask(slotModel: ImageStickerModel,
                               canvasSize: CGSize,
                               scaleW: CGFloat) -> (contentMask: UIImage?, borderMask: UIImage?) {
        if slotModel.zIndex == -1 {
            return (nil, nil)
        }
        let frame = CGRect(
            x: CGFloat(slotModel.originFrameX) * scaleW,
            y: CGFloat(slotModel.originFrameY) * scaleW,
            width: CGFloat(slotModel.originFrameWidth) * scaleW,
            height: CGFloat(slotModel.originFrameHeight) * scaleW
        )
        let baseSize = slotModel.image?.size ?? frame.size
        let overlayRect = CGRect(
            x: baseSize.width * CGFloat(slotModel.overlayRectX ?? 0),
            y: baseSize.height * CGFloat(slotModel.overlayRectY ?? 0),
            width: baseSize.width * CGFloat(slotModel.overlayRectWidth ?? 0.8),
            height: baseSize.height * CGFloat(slotModel.overlayRectHeight ?? 0.8)
        )
        let scaleX = frame.width / baseSize.width
        let scaleY = frame.height / baseSize.height
        let overlayScaled = CGRect(
            x: overlayRect.origin.x * scaleX,
            y: overlayRect.origin.y * scaleY,
            width: overlayRect.width * scaleX,
            height: overlayRect.height * scaleY
        )
        let finalSize = CGSize(width: frame.width * CGFloat(slotModel.originScale * slotModel.gesScale),
                               height: frame.height * CGFloat(slotModel.originScale * slotModel.gesScale))
        let imageTypeRaw = slotModel.imageType?.rawValue ?? "square"

        let contentMask = UIGraphicsImageRenderer(size: canvasSize).image { ctx in
            let cg = ctx.cgContext
            cg.saveGState()
            cg.translateBy(x: frame.midX, y: frame.midY)
            let angle = CGFloat(slotModel.originAngle + slotModel.gesRotation) * .pi / 180
            cg.rotate(by: angle)
            let drawRect = CGRect(
                x: -finalSize.width / 2 + overlayScaled.origin.x,
                y: -finalSize.height / 2 + overlayScaled.origin.y,
                width: overlayScaled.width,
                height: overlayScaled.height
            )
            
            if imageTypeRaw == "IrregularShape" || imageTypeRaw == "IrregularMask",
               let frameImg = BSWHBundle.image(named: slotModel.imageName) {
                if slotModel.maskTransparent {
                    frameImg.draw(in: drawRect, blendMode: .normal, alpha: 1.0)
                } else {
                    frameImg.draw(in: CGRect(
                        x: -finalSize.width / 2,
                        y: -finalSize.height / 2,
                        width: finalSize.width,
                        height: finalSize.height
                    ), blendMode: .normal, alpha: 1.0)
                }
            } else {
                let path: UIBezierPath = {
                    switch imageTypeRaw {
                    case "circle", "ellipse":
                        return UIBezierPath(ovalIn: drawRect)
                    case "rectangle":
                        var cornerRadius = 16.w
                        if let cornerRadiusScale = slotModel.cornerRadiusScale {
                            if cornerRadiusScale < 1 {
                                cornerRadius = min(drawRect.width, drawRect.height) * cornerRadiusScale
                            } else {
                                cornerRadius = cornerRadiusScale
                            }
                        }
                        return UIBezierPath(roundedRect: drawRect, cornerRadius: cornerRadius)
                    default:
                        return UIBezierPath(rect: drawRect)
                    }
                }()
                UIColor.white.setFill()
                path.fill()
            }
            cg.restoreGState()
        }
        var bordermask: UIImage? = nil
        if let mask = slotModel.imageMask,
            let maskImage = BSWHBundle.image(named: mask) {
            bordermask = UIGraphicsImageRenderer(size: canvasSize).image { ctx in
                let cg = ctx.cgContext
                cg.saveGState()
                
                cg.translateBy(x: frame.midX, y: frame.midY)
                let angle = CGFloat(slotModel.originAngle + slotModel.gesRotation) * .pi / 180
                cg.rotate(by: angle)
                maskImage.draw(in: CGRect(
                    x: -finalSize.width / 2,
                    y: -finalSize.height / 2,
                    width: finalSize.width,
                    height: finalSize.height
                ))
                
                cg.restoreGState()
            }
        }
        return (contentMask, bordermask)
    }

    
    // MARK: - 绘制辅助
    public func composeStickerImage(from model: ImageStickerModel, slotImage: UIImage?) -> UIImage? {
        let baseImage = model.image ?? (model.imageName.isEmpty ? nil : BSWHBundle.image(named: model.imageName))
        let _ = baseImage?.size ?? CGSize(
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
            var inset = CGRect(x: 0, y: 0, width: 1, height: 1)
            if model.maskTransparent {
                inset = CGRect(x: model.overlayRectX ?? 0, y: model.overlayRectY ?? 0, width: model.overlayRectWidth ?? 0, height: model.overlayRectHeight ?? 0)
            }
            return overlayImageWithFrame(newImage, baseImage: base, frameImage: frame, inset: inset)
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
                    var cornerRadius = 16.w
//                    if model.imageName == "Travel-sticker-bg03" {
//                        cornerRadius = 57.h
//                    }
                    if let cornerRadiusScale = model.cornerRadiusScale {
                        if cornerRadiusScale < 1 {
                            cornerRadius = min(overlayRect.width, overlayRect.height) * cornerRadiusScale
                        } else {
                            cornerRadius = cornerRadiusScale
                        }
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
            newImage.draw(in: drawRect)
        }
    }
    
    public func overlayImageWithFrame(_ newImage: UIImage, baseImage: UIImage, frameImage: UIImage, inset: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)) -> UIImage {
        let size = baseImage.size
        let contentSize = CGSize(width: ceil(size.width * inset.width), height: ceil(size.height * inset.height))
        let contentOrigin = CGPoint(x: size.width * inset.origin.x, y: size.height * inset.origin.y)

        let content = UIGraphicsImageRenderer(size: contentSize).image { _ in
            let scaleW = contentSize.width / newImage.size.width
            let scaleH = contentSize.height / newImage.size.height
            let scale = max(scaleW, scaleH)
            let newWidth = newImage.size.width * scale
            let newHeight = newImage.size.height * scale
            let originX = (contentSize.width - newWidth) / 2
            let originY = (contentSize.height - newHeight) / 2
            let imageRect = CGRect(x: originX, y: originY, width: newWidth, height: newHeight)
            newImage.draw(in: imageRect)
            baseImage.draw(in: CGRect(origin: .zero, size: contentSize), blendMode: .destinationIn, alpha: 1.0)
        }
        return UIGraphicsImageRenderer(size: size).image { _ in
            content.draw(in: CGRect(origin: contentOrigin, size: contentSize))
            frameImage.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    public func IrregularMaskOverlayImageWithFrame(_ newImage: UIImage,
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
