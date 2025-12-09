//
//  kkCommon.swift
//  BSWHPhotoPicker
//
//  Created by 笔尚文化 on 2025/12/2.
//

import UIKit

class kkCommon {
    static func imageFromHex(_ hex: String,
                      alpha: CGFloat = 1.0,
                      size: CGSize = CGSize(width: 400, height: 400)) -> UIImage? {

        guard let color = UIColor(hex: hex)?.withAlphaComponent(alpha) else { return nil }

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

}

extension UIImage {
    /// 由 UIColor 生成 UIImage
    /// - Parameters:
    ///   - color: 颜色
    ///   - size: 图片尺寸（默认 1x1）
    static func from(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
    
    func decodedImage() -> UIImage {
            guard let cgImage = self.cgImage else { return self }
            let size = CGSize(width: cgImage.width, height: cgImage.height)
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
            guard let ctx = CGContext(data: nil,
                                      width: Int(size.width),
                                      height: Int(size.height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: 0,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo) else {
                return self
            }
            ctx.draw(cgImage, in: CGRect(origin: .zero, size: size))
            guard let newCg = ctx.makeImage() else { return self }
            return UIImage(cgImage: newCg)
        }
}

public func kkColorFromHexWithAlpha(_ hex: Int, _ alpha: CGFloat) -> UIColor {
    return UIColor(red: CGFloat(((hex & 0xFF0000) >> 16)) / 255.0,
                   green: CGFloat(((hex & 0xFF00) >> 8)) / 255.0,
                   blue: CGFloat((hex & 0xFF)) / 255.0,
                   alpha: alpha)
}
public func kkColorFromHex(_ hex: Int) -> UIColor {
    return kkColorFromHexWithAlpha(hex, 1)
}

public func kkColorFromHex(_ hex: String) -> UIColor {
    var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    
    if hexString.hasPrefix("#") {
        hexString.remove(at: hexString.startIndex)
    }
    
    var rgbValue: UInt64 = 0
    Scanner(string: hexString).scanHexInt64(&rgbValue)
    
    // 根据十六进制字符串长度判断是否包含透明度
    switch hexString.count {
    case 8: // 包含透明度 #RRGGBBAA
        return UIColor(red: CGFloat((rgbValue & 0xFF000000) >> 24) / 255.0,
                  green: CGFloat((rgbValue & 0x00FF0000) >> 16) / 255.0,
                  blue: CGFloat((rgbValue & 0x0000FF00) >> 8) / 255.0,
                  alpha: CGFloat(rgbValue & 0x000000FF) / 255.0)
        
    case 6: // 不包含透明度 #RRGGBB
        return UIColor(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                  green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                  blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                  alpha: 1)
        
    default: // 默认返回黑色
        return UIColor(red: 0, green: 0, blue: 0, alpha: 1)
    }
}

public let kkTABBAR_HEIGHT = 49.0
public let kkNAV_HEIGHT = 44.0

public let kkScreenWidth = UIScreen.main.bounds.size.width
public let kkScreenHeight = UIScreen.main.bounds.size.height

/// top安全区域
public let kkSAFE_AREA_TOP: CGFloat = {
    guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else {
            return 0
    }
    
    if #available(iOS 11.0, *) {
        return window.safeAreaInsets.top
    }
    return 0
}()
/// bottom 安全区域
public let kkSAFE_AREA_BOTTOM: CGFloat = {
    guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else {
            return 0
    }
    
    if #available(iOS 11.0, *) {
        return window.safeAreaInsets.bottom
    }
    return 0
}()

/// 状态栏高度
public let kkSTATUS_BAR_HEIGHT: CGFloat = {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
        return 0
    }
    if #available(iOS 13.0, *) {
        return windowScene.statusBarManager?.statusBarFrame.height ?? 0
    } else {
        return UIApplication.shared.statusBarFrame.height
    }
}()

/// 导航栏总高度（状态栏+导航栏）
public let kkNAVIGATION_BAR_HEIGHT = kkNAV_HEIGHT + kkSTATUS_BAR_HEIGHT

/// Tab栏总高度（Tab栏+底部安全区域）
public let kkTAB_BAR_TOTAL_HEIGHT = kkTABBAR_HEIGHT + kkSAFE_AREA_BOTTOM

extension UIColor {
    convenience init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)

        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }

        guard hexString.count == 6 else { return nil }
        
        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)

        let r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

extension UIView {

    func exportTransparentPNG() -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false   // 🔥 关键：必须 false

        let renderer = UIGraphicsImageRenderer(size: bounds.size, format: format)

        let img = renderer.image { ctx in
            // 不要背景填充，也不要用 drawHierarchy
            layer.render(in: ctx.cgContext)
        }

        // debug
        print("Export alpha flag:", img.pngData()?[25] ?? 0)

        return img
    }
}

