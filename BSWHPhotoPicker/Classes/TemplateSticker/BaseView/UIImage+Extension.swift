//
//  UIImage+Extension.swift
//  BSWHPhotoPicker_Example
//
//  Created by 笔尚文化 on 2025/11/13.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import UIKit

extension UIImage {

    /// 水平翻转
    func flippedHorizontally() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let context = UIGraphicsGetCurrentContext()!
        
        // 水平翻转
        context.translateBy(x: size.width, y: 0)
        context.scaleBy(x: -1.0, y: 1.0)
        
        draw(in: CGRect(origin: .zero, size: size))
        let flippedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return flippedImage
    }
    
    /// 垂直翻转
    func flippedVertically() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let context = UIGraphicsGetCurrentContext()!
        
        // 垂直翻转
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        draw(in: CGRect(origin: .zero, size: size))
        let flippedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return flippedImage
    }
    
    /// 输入任意宽高比例裁剪为居中图片，例如：
    /// - cropped(toAspectRatioWidth: 3, height: 2)
    /// - cropped(toAspectRatioWidth: 2.35, height: 1)
    /// - cropped(toAspectRatioWidth: 7, height: 9)
    func cropped(toAspectRatioWidth w: CGFloat, height h: CGFloat) -> UIImage? {
        return croppedToAspectRatio(widthRatio: w, heightRatio: h)
    }

    private func croppedToAspectRatio(widthRatio: CGFloat, heightRatio: CGFloat) -> UIImage? {
        guard widthRatio > 0, heightRatio > 0 else { return nil }
        guard let normalized = normalizedImage() else { return nil }

        let imageWidth = normalized.size.width
        let imageHeight = normalized.size.height

        let targetRatio = widthRatio / heightRatio
        let currentRatio = imageWidth / imageHeight

        var cropRect: CGRect = .zero

        if currentRatio < targetRatio {
            // 图片更瘦（宽度比例不足）→ 裁掉上下
            let newHeight = imageWidth / targetRatio
            let originY = (imageHeight - newHeight) / 2.0
            cropRect = CGRect(x: 0, y: originY, width: imageWidth, height: newHeight)
        } else if currentRatio > targetRatio {
            // 图片更宽 → 裁掉左右
            let newWidth = imageHeight * targetRatio
            let originX = (imageWidth - newWidth) / 2.0
            cropRect = CGRect(x: originX, y: 0, width: newWidth, height: imageHeight)
        } else {
            // 比例完全一致
            cropRect = CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight)
        }

        // 绘制裁剪后的图像
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = normalized.scale
        let renderer = UIGraphicsImageRenderer(size: cropRect.size, format: format)

        let result = renderer.image { _ in
            normalized.draw(at: CGPoint(x: -cropRect.origin.x, y: -cropRect.origin.y))
        }
        return result
    }

    /// 修正方向
    private func normalizedImage() -> UIImage? {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let newImg = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImg
    }
    
    func forceRGBA() -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
                format.scale = 1
                format.opaque = false
                let renderer = UIGraphicsImageRenderer(size: self.size, format: format)
                let img = renderer.image { ctx in
                    ctx.cgContext.interpolationQuality = .high
                    self.draw(in: CGRect(origin: .zero, size: self.size))
                }
                guard let cg = img.cgImage else { return self }
                return UIImage(cgImage: cg, scale: self.scale, orientation: self.imageOrientation)
    }
    
}

