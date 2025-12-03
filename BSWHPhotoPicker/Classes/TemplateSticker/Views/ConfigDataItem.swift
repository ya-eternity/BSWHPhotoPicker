//
//  ConfigDataItem.swift
//  BSWHPhotoPicker
//
//  Created by 笔尚文化 on 2025/11/18.
//

import UIKit

class ImageHeightCache {
    static let shared = ImageHeightCache()
    private init() {}
    private var cache: [String: [CGFloat: CGFloat]] = [:]
    func get(imageName: String, width: CGFloat) -> CGFloat? {
        return cache[imageName]?[width]
    }
    func set(imageName: String, width: CGFloat, height: CGFloat) {
        if cache[imageName] == nil {
            cache[imageName] = [:]
        }
        cache[imageName]?[width] = height
    }
}


struct RatioToolsModel {
    var text:String = "Text"
    var imageName:String = "template-text"
    var width:Double = 1.0
    var height:Double = 1.0
}

struct ToolsModel {
    var text:String = "Text"
    var imageName:String = "template-text"
}

public struct TemplateModel {
    public var imageName: String
    public var imageBg: String
    public var jsonName: String
    public var isNeedFit: Bool
    public var cornerRadius: Double

    public init(
        imageName: String = "1",
        imageBg: String = "Christmas00-bg",
        jsonName: String = "Christmas00",
        isNeedFit: Bool = false,
        cornerRadius: Double = 0.0
    ) {
        self.imageName = imageName
        self.imageBg = imageBg
        self.jsonName = jsonName
        self.isNeedFit = isNeedFit
        self.cornerRadius = cornerRadius
    }
}

class ConfigDataItem {
    
    static func getTemplateTabData() -> [String] {
        let items = [BSWHPhotoPickerLocalization.shared.localized("ALL"),
                     BSWHPhotoPickerLocalization.shared.localized("Christmas"),
                     BSWHPhotoPickerLocalization.shared.localized("Baby"),
                     BSWHPhotoPickerLocalization.shared.localized("Birthday"),
                     BSWHPhotoPickerLocalization.shared.localized("WeddingParty"),
                     BSWHPhotoPickerLocalization.shared.localized("Travel"),
                     BSWHPhotoPickerLocalization.shared.localized("Scrapbook"),
                     BSWHPhotoPickerLocalization.shared.localized("photoframe")]
        return items
    }
    
    static func getTemplateListData() -> [[TemplateModel]] {
        let item00 = TemplateModel(imageName: "Christmas01",imageBg: "Christmas00-bg",jsonName: "Christmas00")
        let item01 = TemplateModel(imageName: "Christmas02",imageBg: "Christmas01-bg",jsonName: "Christmas01",isNeedFit: true)
        let item02 = TemplateModel(imageName: "Christmas03",imageBg: "Christmas02-bg",jsonName: "Christmas02")
        let item03 = TemplateModel(imageName: "Christmas04",imageBg: "Christmas03-bg",jsonName: "Christmas03")
        let item04 = TemplateModel(imageName: "Christmas05",imageBg: "Christmas04-bg",jsonName: "Christmas04")
        let item05 = TemplateModel(imageName: "Christmas06",imageBg: "Christmas05-bg",jsonName: "Christmas05")
        let item06 = TemplateModel(imageName: "Christmas07",imageBg: "Christmas06-bg",jsonName: "Christmas06")
        
        let item10 = TemplateModel(imageName: "baby01",imageBg: "baby01-bg",jsonName: "baby01")
        let item11 = TemplateModel(imageName: "baby02",imageBg: "baby02-bg",jsonName: "baby02")
        let item12 = TemplateModel(imageName: "baby03",imageBg: "baby03-bg",jsonName: "baby03")
        let item13 = TemplateModel(imageName: "baby04",imageBg: "baby04-bg",jsonName: "baby04")
        let item14 = TemplateModel(imageName: "baby05",imageBg: "baby05-bg",jsonName: "baby05")
        let item15 = TemplateModel(imageName: "baby06",imageBg: "baby06-bg",jsonName: "baby06")
        
        let item21 = TemplateModel(imageName: "Birthday01",imageBg: "Birthday01-bg",jsonName: "Birthday01")
        let item22 = TemplateModel(imageName: "Birthday02",imageBg: "Birthday02",jsonName: "Birthday02")
        let item23 = TemplateModel(imageName: "Birthday03",imageBg: "Birthday03-bg",jsonName: "Birthday03")
        let item24 = TemplateModel(imageName: "Birthday04",imageBg: "Birthday04-bg",jsonName: "Birthday04")
        let item25 = TemplateModel(imageName: "Birthday05",imageBg: "Birthday05-bg",jsonName: "Birthday05")

        let item31 = TemplateModel(imageName: "Wedding01",imageBg: "wedding01-bg",jsonName: "Wedding01",isNeedFit: true)
        let item32 = TemplateModel(imageName: "Wedding02",imageBg: "wedding02-bg",jsonName: "Wedding02")
        let item33 = TemplateModel(imageName: "Wedding03",imageBg: "wedding03-bg",jsonName: "Wedding03")
        let item34 = TemplateModel(imageName: "Wedding04",imageBg: "wedding04-bg",jsonName: "Wedding04")
        let item35 = TemplateModel(imageName: "Wedding05",imageBg: "wedding05-bg",jsonName: "Wedding05")

        let item41 = TemplateModel(imageName: "Travel01",imageBg: "Travel01-bg",jsonName: "Travel01",isNeedFit: true)
        let item42 = TemplateModel(imageName: "Travel02",imageBg: "Travel02-bg",jsonName: "Travel02")
        let item43 = TemplateModel(imageName: "Travel03",imageBg: "Travel03-bg",jsonName: "Travel03")
        let item44 = TemplateModel(imageName: "Travel04",imageBg: "Travel04-bg",jsonName: "Travel04")
        let item45 = TemplateModel(imageName: "Travel05",imageBg: "Travel05-bg",jsonName: "Travel05")
        let item46 = TemplateModel(imageName: "Travel06",imageBg: "Travel06-bg",jsonName: "Travel06")
        let item47 = TemplateModel(imageName: "Travel07",imageBg: "Travel07-bg",jsonName: "Travel07")

        let item51 = TemplateModel(imageName: "Scrapbook01",imageBg: "Scrapbook01-bg",jsonName: "Scrapbook01")
        let item52 = TemplateModel(imageName: "Scrapbook02",imageBg: "Scrapbook02-bg",jsonName: "Scrapbook02",isNeedFit: true)
        let item53 = TemplateModel(imageName: "Scrapbook03",imageBg: "Scrapbook03-bg",jsonName: "Scrapbook03")
        let item54 = TemplateModel(imageName: "Scrapbook04",imageBg: "Scrapbook04-bg",jsonName: "Scrapbook04")
        let item55 = TemplateModel(imageName: "Scrapbook05",imageBg: "Scrapbook05-bg",jsonName: "Scrapbook05")

        let item61 = TemplateModel(imageName: "PhotoFrame01",imageBg: "PhotoFrame01-bg",jsonName: "PhotoFrame01")
        let item62 = TemplateModel(imageName: "PhotoFrame02",imageBg: "PhotoFrame02-bg",jsonName: "PhotoFrame02",cornerRadius: 48.h)
        let item63 = TemplateModel(imageName: "PhotoFrame03",imageBg: "PhotoFrame03-bg",jsonName: "PhotoFrame03",cornerRadius: 48.h)
        let item64 = TemplateModel(imageName: "PhotoFrame04",imageBg: "PhotoFrame04-bg",jsonName: "PhotoFrame04")
        let item65 = TemplateModel(imageName: "PhotoFrame05",imageBg: "PhotoFrame05-bg",jsonName: "PhotoFrame05")
        let item66 = TemplateModel(imageName: "PhotoFrame06",imageBg: "PhotoFrame06-bg",jsonName: "PhotoFrame06")
        let item67 = TemplateModel(imageName: "PhotoFrame07",imageBg: "PhotoFrame07-bg",jsonName: "PhotoFrame07")

        
        let items = [[item00,item01,item02,item03,item04,item05,item06,item10,item11,item12,item13,item14,item15,item21,item23,item24,item25,item31,item32,item33,item34,item35,item41,item42,item43,item44,item45,item46,item47,item51,item52,item53,item54,item55,item61,item62,item63,item64,item65,item66,item67],
            [item00,item01,item02,item03,item04,item05,item06],
            [item10,item11,item12,item13,item14,item15],
            [item21,item22,item23,item24,item25],
            [item31,item32,item33,item34,item35],
            [item41,item42,item43,item44,item45,item46,item47],
            [item51,item52,item53,item54,item55],
            [item61,item62,item63,item64,item65,item66,item67]
        ]
        
        return items
    }
    
    
    static func getTemplateToolsData() -> [ToolsModel] {
        let item00 = ToolsModel(text: BSWHPhotoPickerLocalization.shared.localized("Text"),imageName: "template-text")
        let item01 = ToolsModel(text: BSWHPhotoPickerLocalization.shared.localized("Background"),imageName: "template-Background")
        let item02 = ToolsModel(text: BSWHPhotoPickerLocalization.shared.localized("Photos"),imageName: "template-photos")
        let item03 = ToolsModel(text: BSWHPhotoPickerLocalization.shared.localized("Stickers"),imageName: "template-stickers")
        let item04 = ToolsModel(text: BSWHPhotoPickerLocalization.shared.localized("Ratio"),imageName: "template-ratio")
        let items = [item00,item01,item02,item03,item04]
        return items
    }
    
    static func getStickerToolsData() -> [ToolsModel] {
        let item00 = ToolsModel(text: BSWHPhotoPickerLocalization.shared.localized("Replace"),imageName: "template-replace")
        let item01 = ToolsModel(text: BSWHPhotoPickerLocalization.shared.localized("Duplicate"),imageName: "template-duplicate")
        let item02 = ToolsModel(text: BSWHPhotoPickerLocalization.shared.localized("Crop"),imageName: "template-crop")
        let item03 = ToolsModel(text: BSWHPhotoPickerLocalization.shared.localized("FlipH"),imageName: "template-FlipH")
        let item04 = ToolsModel(text: BSWHPhotoPickerLocalization.shared.localized("FlipV"),imageName: "template-FlipV")
        let item05 = ToolsModel(text: BSWHPhotoPickerLocalization.shared.localized("Remove"),imageName: "template-remove")
        let items = [item00,item01,item02,item03,item04,item05]
        return items
    }
    
    static func getRatioToolsData() -> [[RatioToolsModel]] {
        let item00 = RatioToolsModel(text: "1:1",imageName: "ratio1-1",width: 1.0,height: 1.0)
        let item01 = RatioToolsModel(text: "16:9",imageName: "ratio16-9",width: 16.0,height: 9.0)
        let item02 = RatioToolsModel(text: "5:4",imageName: "ratio5-4",width: 5.0,height: 4.0)
        let item03 = RatioToolsModel(text: "7:5",imageName: "ratio7-5",width: 7.0,height: 5.0)
        let item04 = RatioToolsModel(text: "4:3",imageName: "ratio4-3",width: 4.0,height: 3.0)
        let item05 = RatioToolsModel(text: "9:16",imageName: "ratio9-16",width: 9.0,height: 16.0)
        let item06 = RatioToolsModel(text: "5:3",imageName: "ratio5-3",width: 5.0,height: 3.0)
        let item07 = RatioToolsModel(text: "3:2",imageName: "ratio3-2",width: 3.0,height: 2.0)
        let item08 = RatioToolsModel(text: "3:4",imageName: "ratio3-4",width: 3.0,height: 4.0)
        
        let item10 = RatioToolsModel(text: "Postcard",imageName: "print-00-postcard",width: 3.0,height: 2.0)
        let item11 = RatioToolsModel(text: "Poster",imageName: "print-01-poster",width: 4.0,height: 5.0)
        let item12 = RatioToolsModel(text: "Poster",imageName: "print-02-poster",width: 5.0,height: 4.0)
        let item13 = RatioToolsModel(text: "A4",imageName: "print-03-A4",width: 1.0,height: 1.414)
        let item14 = RatioToolsModel(text: "A4",imageName: "print-04-A4",width: 1.414,height: 1.0)
        let item15 = RatioToolsModel(text: "Letter",imageName: "print-05-Letter",width: 1.0,height: 1.294)
        let item16 = RatioToolsModel(text: "Letter",imageName: "print-06-Letter",width: 1.294,height: 1.0)
        let item17 = RatioToolsModel(text: "Half letter",imageName: "print-07-HLetter",width: 1.0,height: 1.545)
        let item18 = RatioToolsModel(text: "Half letter",imageName: "print-08-HLetter",width: 1.545,height: 1.0)
        let item19 = RatioToolsModel(text: "Postcard",imageName: "print-09-postcard",width: 2.0,height: 3.0)

        let item20 = RatioToolsModel(text: "Square",imageName: "social-00-square",width: 1.0,height: 1.0)
        let item21 = RatioToolsModel(text: "Portrait",imageName: "social-01-portrait",width: 4.0,height: 5.0)
        let item22 = RatioToolsModel(text: "Story",imageName: "social-02-Story",width: 9.0,height: 16.0)
        let item23 = RatioToolsModel(text: "Post",imageName: "social-03-post",width: 1.91,height: 1.0)
        let item24 = RatioToolsModel(text: "Cover",imageName: "social-04-cover",width: 16.0,height: 9.0)
        let item25 = RatioToolsModel(text: "Post",imageName: "social-05-post",width: 2.0,height: 3.0)
        let item26 = RatioToolsModel(text: "Post",imageName: "social-06-postX",width: 16.0,height: 9.0)
        let item27 = RatioToolsModel(text: "Header",imageName: "social-07-header",width: 3.0,height: 1.0)
        let item28 = RatioToolsModel(text: "YouTube",imageName: "social-08-YouTube",width: 16.0,height: 9.0)
        let item29 = RatioToolsModel(text: "Shopify",imageName: "social-09-Shopify",width: 1.0,height: 1.0)
        let item30 = RatioToolsModel(text: "Shopify",imageName: "social-10-Shopify",width: 1.0,height: 1.1)
        let item31 = RatioToolsModel(text: "Shopify",imageName: "social-11-Shopify",width: 4.0,height: 5.0)
        let item32 = RatioToolsModel(text: "Amazon",imageName: "social-12-Amazon",width: 1.0,height: 1.0)
        let item33 = RatioToolsModel(text: "Shopee",imageName: "social-13-Shopee",width: 1.0,height: 1.0)
        let item34 = RatioToolsModel(text: "Facebook",imageName: "social-14-Facebook",width: 1.0,height: 1.0)
        let item35 = RatioToolsModel(text: "Linkedin",imageName: "social-15-linkedin",width: 1.91,height: 1.0)
        let item36 = RatioToolsModel(text: "Linkedin",imageName: "social-16-linkedin",width: 1.0,height: 1.0)
        let item37 = RatioToolsModel(text: "Tiktok",imageName: "social-17-tiktok",width: 9.0,height: 16.0)
        let item38 = RatioToolsModel(text: "Tiktok",imageName: "social-18-tiktok",width: 1.0,height: 1.0)
        let item39 = RatioToolsModel(text: "Ebay",imageName: "social-19-ebay",width: 1.0,height: 1.0)
        let item40 = RatioToolsModel(text: "Poshmark",imageName: "social-20-Poshmark",width: 1.0,height: 1.0)
        let item41 = RatioToolsModel(text: "Etsy",imageName: "social-21-etsy",width: 5.0,height: 4.0)
        let item42 = RatioToolsModel(text: "Depop",imageName: "social-22-depop",width: 1.0,height: 1.0)

        let items = [[item00,item01,item02,item03,item04,item05,item06,item07,item08],[item20,item21,item22,item23,item24,item25,item26,item27,item28,item29,item30,item31,item32,item33,item34,item35,item36,item37,item38,item39,item40,item41,item42],[item10,item11,item12,item13,item14,item15,item16,item17,item18,item19]]
        return items
    }
}
