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
    public var imageName:String?
    public var imageBg:String = "Christmas00-bg"
    public var jsonName:String?
    public var isNeedFit:Bool = false
    public var cornerRadius:Double = 0.0
    public var photoCount: Int = 1

    public init(imageName: String? = nil, imageBg: String, jsonName: String? = nil, isNeedFit: Bool = false, cornerRadius: Double = 0.0, photoCount:Int = 1) {
        self.imageName = imageName
        self.imageBg = imageBg
        self.jsonName = jsonName
        self.isNeedFit = isNeedFit
        self.cornerRadius = cornerRadius
        self.photoCount = photoCount
    }
}

//public struct BackgroundModel {
//    var imageBg:String = "Christmas00-bg"
//}

class ConfigDataItem {
    
    static func getBackgroundTabData() -> [String] {
        let items = [BSWHPhotoPickerLocalization.shared.localized("Color"),
                     BSWHPhotoPickerLocalization.shared.localized("Texture"),
                     BSWHPhotoPickerLocalization.shared.localized("Geometric"),
                     BSWHPhotoPickerLocalization.shared.localized("Pattern"),
                     BSWHPhotoPickerLocalization.shared.localized("Grid"),
        ]
        return items
    }
    
    static func getBackgroundListData() -> [[TemplateModel]] {
        let item00 = TemplateModel(imageBg: "BackgroundPicker")
        let item01 = TemplateModel(imageBg: "BackgroundNoColor")
        let item02 = TemplateModel(imageBg: "#99EDFF")
        let item03 = TemplateModel(imageBg: "#00C9FF")
        let item04 = TemplateModel(imageBg: "#D1E82D")
        let item05 = TemplateModel(imageBg: "#9200FF")
        let item06 = TemplateModel(imageBg: "#8F9562")
        let item07 = TemplateModel(imageBg: "#D9D9D9")
        let item08 = TemplateModel(imageBg: "#2F4D49")
        let item09 = TemplateModel(imageBg: "#FFED00")
        let item10 = TemplateModel(imageBg: "#495E26")
        let item11 = TemplateModel(imageBg: "#FAB226")
        let item12 = TemplateModel(imageBg: "#8ED830")
        let item13 = TemplateModel(imageBg: "#FF614F")
        let item14 = TemplateModel(imageBg: "#C970EB")
        let item15 = TemplateModel(imageBg: "#76939A")
        let item16 = TemplateModel(imageBg: "#4D316D")
        let item17 = TemplateModel(imageBg: "#3265E4")
        
        let item100 = TemplateModel(imageBg: "Texture00")
        let item101 = TemplateModel(imageBg: "Texture01")
        let item102 = TemplateModel(imageBg: "Texture02")
        let item103 = TemplateModel(imageBg: "Texture03")
        let item104 = TemplateModel(imageBg: "Texture04")
        let item105 = TemplateModel(imageBg: "Texture05")
        let item106 = TemplateModel(imageBg: "Texture06")
        let item107 = TemplateModel(imageBg: "Texture07")
        let item108 = TemplateModel(imageBg: "Texture08")
        let item109 = TemplateModel(imageBg: "Texture09")
        let item110 = TemplateModel(imageBg: "Texture10")
        let item112 = TemplateModel(imageBg: "Texture11")
        let item113 = TemplateModel(imageBg: "Texture12")
        let item114 = TemplateModel(imageBg: "Texture13")
        let item115 = TemplateModel(imageBg: "Texture14")
        let item116 = TemplateModel(imageBg: "Texture15")
        let item117 = TemplateModel(imageBg: "Texture16")
        let item118 = TemplateModel(imageBg: "Texture17")
        let item119 = TemplateModel(imageBg: "Texture18")
        let item120 = TemplateModel(imageBg: "Texture19")
        let item121 = TemplateModel(imageBg: "Texture20")
        let item122 = TemplateModel(imageBg: "Texture21")
        let item123 = TemplateModel(imageBg: "Texture22")
        let item124 = TemplateModel(imageBg: "Texture23")
        let item125 = TemplateModel(imageBg: "Texture24")
        let item126 = TemplateModel(imageBg: "Texture25")
        let item127 = TemplateModel(imageBg: "Texture26")
        let item128 = TemplateModel(imageBg: "Texture27")
        let item129 = TemplateModel(imageBg: "Texture28")
        let item130 = TemplateModel(imageBg: "Texture29")
        let item131 = TemplateModel(imageBg: "Texture30")
        let item132 = TemplateModel(imageBg: "Texture31")
        let item133 = TemplateModel(imageBg: "Texture32")
        let item134 = TemplateModel(imageBg: "Texture33")
        let item135 = TemplateModel(imageBg: "Texture34")
        let item136 = TemplateModel(imageBg: "Texture35")
        let item137 = TemplateModel(imageBg: "Texture36")
        let item138 = TemplateModel(imageBg: "Texture37")
        let item139 = TemplateModel(imageBg: "Texture43")
        let item140 = TemplateModel(imageBg: "Texture38")
        let item141 = TemplateModel(imageBg: "Texture39")
        let item142 = TemplateModel(imageBg: "Texture40")
        let item143 = TemplateModel(imageBg: "Texture41")
        let item144 = TemplateModel(imageBg: "Texture42")

        let item145 = TemplateModel(imageBg: "Pattern34")
        let item146 = TemplateModel(imageBg: "Pattern35")
        let item147 = TemplateModel(imageBg: "Pattern36")
        let item148 = TemplateModel(imageBg: "Pattern37")
        let item149 = TemplateModel(imageBg: "Pattern38")
        let item150 = TemplateModel(imageBg: "Pattern39")
        let item151 = TemplateModel(imageBg: "Pattern40")
        let item152 = TemplateModel(imageBg: "Pattern41")
        let item153 = TemplateModel(imageBg: "Pattern42")
        let item154 = TemplateModel(imageBg: "Pattern43")
        let item155 = TemplateModel(imageBg: "Pattern44")
        let item156 = TemplateModel(imageBg: "Pattern45")
        let item157 = TemplateModel(imageBg: "Pattern46")
        let item158 = TemplateModel(imageBg: "Pattern47")
        let item159 = TemplateModel(imageBg: "Pattern48")
        let item160 = TemplateModel(imageBg: "Pattern49")
        let item161 = TemplateModel(imageBg: "Pattern50")
        let item162 = TemplateModel(imageBg: "Pattern51")
        let item163 = TemplateModel(imageBg: "Pattern52")
        let item164 = TemplateModel(imageBg: "Pattern53")
        let item165 = TemplateModel(imageBg: "Pattern54")
        let item166 = TemplateModel(imageBg: "Pattern55")
        let item167 = TemplateModel(imageBg: "Pattern56")
        let item168 = TemplateModel(imageBg: "Pattern57")
        let item169 = TemplateModel(imageBg: "Pattern58")
        let item170 = TemplateModel(imageBg: "Pattern59")
        let item171 = TemplateModel(imageBg: "Pattern60")


        
        let item200 = TemplateModel(imageBg: "Geometric00")
        let item201 = TemplateModel(imageBg: "Geometric01")
        let item202 = TemplateModel(imageBg: "Geometric02")
        let item203 = TemplateModel(imageBg: "Geometric03")
        let item204 = TemplateModel(imageBg: "Geometric04")
        let item205 = TemplateModel(imageBg: "Geometric05")
        let item206 = TemplateModel(imageBg: "Geometric06")
        let item207 = TemplateModel(imageBg: "Geometric07")

        
        let item300 = TemplateModel(imageBg: "Pattern00")
        let item301 = TemplateModel(imageBg: "Pattern01")
        let item302 = TemplateModel(imageBg: "Pattern02")
        let item303 = TemplateModel(imageBg: "Pattern03")
        let item304 = TemplateModel(imageBg: "Pattern04")
        let item305 = TemplateModel(imageBg: "Pattern05")
        let item306 = TemplateModel(imageBg: "Pattern06")
        let item307 = TemplateModel(imageBg: "Pattern07")
        let item308 = TemplateModel(imageBg: "Pattern08")
        let item309 = TemplateModel(imageBg: "Pattern09")
        let item310 = TemplateModel(imageBg: "Pattern10")
        let item311 = TemplateModel(imageBg: "Pattern11")
        let item312 = TemplateModel(imageBg: "Pattern12")
        let item313 = TemplateModel(imageBg: "Pattern13")
        let item314 = TemplateModel(imageBg: "Pattern14")
        let item315 = TemplateModel(imageBg: "Pattern15")
        let item316 = TemplateModel(imageBg: "Pattern16")
        let item317 = TemplateModel(imageBg: "Pattern17")
        let item318 = TemplateModel(imageBg: "Pattern18")
        let item319 = TemplateModel(imageBg: "Pattern19")
        let item320 = TemplateModel(imageBg: "Pattern20")
        let item321 = TemplateModel(imageBg: "Pattern21")
        let item322 = TemplateModel(imageBg: "Pattern22")
        let item323 = TemplateModel(imageBg: "Pattern23")
        let item324 = TemplateModel(imageBg: "Pattern24")
        let item325 = TemplateModel(imageBg: "Pattern25")
        let item326 = TemplateModel(imageBg: "Pattern26")
        let item327 = TemplateModel(imageBg: "Pattern27")
        let item328 = TemplateModel(imageBg: "Pattern28")
        
        
        let item400 = TemplateModel(imageBg: "Pattern29")
        let item401 = TemplateModel(imageBg: "Pattern30")
        let item402 = TemplateModel(imageBg: "Pattern31")
        let item403 = TemplateModel(imageBg: "Pattern32")
        let item404 = TemplateModel(imageBg: "Pattern33")

        
        let items = [[item00,item01,item02,item03,item04,item05,item06,item07,item08,item09,item10,item11,item12,item13,item14,item15,item16,item17],
                     [item100,item101,item102,item103,item104,item105,item106,item107,item108,item109,item110,item112,item113,item114,item115,item116,item117,item118,item119,item120,item121,item122,item123,item124,item125,item126,item127,item128,item129,item130,item131,item132,item133,item134,item135,item136,item137,item138,item139,item140,item141,item142,item143,item144,item145,item146,item147,item148,item149,item150,item151,item152,item153,item154,item155,item156,item157,item158,item159,item160,item161,item162,item163,item164,item165,item166,item167,item168,item169,item170,item171],
                     [item200,item201,item202,item203,item204,item205,item206,item207],
                     [item300,item301,item302,item303,item304,item305,item306,item307,item308,item309,item310,item311,item312,item313,item314,item315,item316,item317,item318,item319,item320,item321,item322,item323,item324,item325,item326,item327,item328],
                     [item400,item401,item402,item403,item404]
        ]
        
        return items
    }
    
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
    
    static func getTemplateListData(forVideo: Bool = false) -> [[TemplateModel]] {
        let item00 = TemplateModel(imageName: "Christmas01",imageBg: "Christmas00-bg",jsonName: "Christmas00", photoCount: 3)
        let item01 = TemplateModel(imageName: "Christmas02",imageBg: "Christmas01-bg",jsonName: "Christmas01",isNeedFit: true, photoCount: 4)
        let item02 = TemplateModel(imageName: "Christmas03",imageBg: "Christmas02-bg",jsonName: "Christmas02", photoCount: 2)
        let item03 = TemplateModel(imageName: "Christmas04",imageBg: "Christmas03-bg",jsonName: "Christmas03", photoCount: 3)
        let item04 = TemplateModel(imageName: "Christmas05",imageBg: "Christmas04-bg",jsonName: "Christmas04", photoCount: 3)
        let item05 = TemplateModel(imageName: "Christmas06",imageBg: "Christmas05-bg",jsonName: "Christmas05", photoCount: 2)
        let item06 = TemplateModel(imageName: "Christmas07",imageBg: "Christmas06-bg",jsonName: "Christmas06", photoCount: 2)
        
        let item10 = TemplateModel(imageName: "baby01",imageBg: "baby01-bg",jsonName: "baby01", photoCount: 2)
        let item11 = TemplateModel(imageName: "baby02",imageBg: "baby02-bg",jsonName: "baby02", photoCount: 3)
        let item12 = TemplateModel(imageName: "baby03",imageBg: "baby03-bg",jsonName: "baby03", photoCount: 1)
        let item13 = TemplateModel(imageName: "baby04",imageBg: "baby04-bg",jsonName: "baby04", photoCount: 1)
        let item14 = TemplateModel(imageName: "baby05",imageBg: "baby05-bg",jsonName: "baby05", photoCount: 1)
        let item15 = TemplateModel(imageName: "baby06",imageBg: "baby06-bg",jsonName: "baby06", photoCount: 1)
        
        let item21 = TemplateModel(imageName: "Birthday01",imageBg: "Birthday01-bg",jsonName: "Birthday01", photoCount: 2)
        let item22 = TemplateModel(imageName: "Birthday02",imageBg: "Travel07-bg",jsonName: "Birthday02", photoCount: 1)
        let item23 = TemplateModel(imageName: "Birthday03",imageBg: "Birthday03-bg",jsonName: "Birthday03", photoCount: 1)
        let item24 = TemplateModel(imageName: "Birthday04",imageBg: "Birthday04-bg",jsonName: "Birthday04", photoCount: 3)
        let item25 = TemplateModel(imageName: "Birthday05",imageBg: "Birthday05-bg",jsonName: "Birthday05", photoCount: 2)

        let item31 = TemplateModel(imageName: "Wedding01",imageBg: "wedding01-bg",jsonName: "Wedding01",isNeedFit: true, photoCount: 1)
        let item32 = TemplateModel(imageName: "Wedding02",imageBg: "wedding02-bg",jsonName: "Wedding02", photoCount: 3)
        let item33 = TemplateModel(imageName: "Wedding03",imageBg: "wedding03-bg",jsonName: "Wedding03", photoCount: 1)
        let item34 = TemplateModel(imageName: "Wedding04",imageBg: "wedding04-bg",jsonName: "Wedding04", photoCount: 3)
        let item35 = TemplateModel(imageName: "Wedding05",imageBg: "wedding05-bg",jsonName: "Wedding05", photoCount: 3)

        let item41 = TemplateModel(imageName: "Travel01",imageBg: "Travel01-bg",jsonName: "Travel01",isNeedFit: true, photoCount: 3)
        let item42 = TemplateModel(imageName: "Travel02",imageBg: "Travel02-bg",jsonName: "Travel02", photoCount: 7)
        let item43 = TemplateModel(imageName: "Travel03",imageBg: "Travel03-bg",jsonName: "Travel03", photoCount: 1)
        let item44 = TemplateModel(imageName: "Travel04",imageBg: "Travel04-bg",jsonName: "Travel04", photoCount: 1)
        let item45 = TemplateModel(imageName: "Travel05",imageBg: "Travel05-bg",jsonName: "Travel05", photoCount: 1)
        let item46 = TemplateModel(imageName: "Travel06",imageBg: "Travel06-bg",jsonName: "Travel06", photoCount: 2)
        let item47 = TemplateModel(imageName: "Travel07",imageBg: "Travel07-bg",jsonName: "Travel07", photoCount: 1)

        let item51 = TemplateModel(imageName: "Scrapbook01",imageBg: "Scrapbook01-bg",jsonName: "Scrapbook01", photoCount: 3)
        let item52 = TemplateModel(imageName: "Scrapbook02",imageBg: "Scrapbook02-bg",jsonName: "Scrapbook02",isNeedFit: true, photoCount: 2)
        let item53 = TemplateModel(imageName: "Scrapbook03",imageBg: "Scrapbook03-bg",jsonName: "Scrapbook03", photoCount: 2)
        let item54 = TemplateModel(imageName: "Scrapbook04",imageBg: "Scrapbook04-bg",jsonName: "Scrapbook04", photoCount: 3)
        let item55 = TemplateModel(imageName: "Scrapbook05",imageBg: "Scrapbook05-bg",jsonName: "Scrapbook05", photoCount: 3)

        let item61 = TemplateModel(imageName: "PhotoFrame01",imageBg: "PhotoFrame01-bg",jsonName: "PhotoFrame01", photoCount: 1)
        let item62 = TemplateModel(imageName: "PhotoFrame02",imageBg: "PhotoFrame02-bg",jsonName: "PhotoFrame02",cornerRadius: 48.h, photoCount: 1)
        let item63 = TemplateModel(imageName: "PhotoFrame03",imageBg: "PhotoFrame03-bg",jsonName: "PhotoFrame03",cornerRadius: 48.h, photoCount: 1)
        let item64 = TemplateModel(imageName: "PhotoFrame04",imageBg: "PhotoFrame04-bg",jsonName: "PhotoFrame04", photoCount: 1)
        let item65 = TemplateModel(imageName: "PhotoFrame05",imageBg: "PhotoFrame05-bg",jsonName: "PhotoFrame05", photoCount: 1)
        let item66 = TemplateModel(imageName: "PhotoFrame06",imageBg: "PhotoFrame06-bg",jsonName: "PhotoFrame06", photoCount: 1)
        let item67 = TemplateModel(imageName: "PhotoFrame07",imageBg: "PhotoFrame07-bg",jsonName: "PhotoFrame07", photoCount: 1)

        
        let items = [[item00,item01,item02,item03,item04,item05,item06,item10,item11,item12,item13,item14,item15,item21,item23,item24,item25,item31,item32,item33,item34,item35,item41,item42,item43,item44,item45,item46,item47,item51,item52,item53,item54,item55,item61,item62,item63,item64,item65,item66,item67],
            [item00,item01,item02,item03,item04,item05,item06],
            [item10,item11,item12,item13,item14,item15],
            [item21,item22,item23,item24,item25],
            [item31,item32,item33,item34,item35],
            [item41,item42,item43,item44,item45,item46,item47],
            [item51,item52,item53,item54,item55],
            [item61,item62,item63,item64,item65,item66,item67]
        ]
        if forVideo {
            return items.map { $0.filter { $0.photoCount == 1 } }
        }
        return items
    }
    
    
    static func getBackgroundToolsData() -> [ToolsModel] {
        let item00 = ToolsModel(text: BSWHPhotoPickerLocalization.shared.localized("Text"),imageName: "template-text")
        let item02 = ToolsModel(text: BSWHPhotoPickerLocalization.shared.localized("Photos"),imageName: "template-photos")
        let item03 = ToolsModel(text: BSWHPhotoPickerLocalization.shared.localized("Stickers"),imageName: "template-stickers")
        let item04 = ToolsModel(text: BSWHPhotoPickerLocalization.shared.localized("Ratio"),imageName: "template-ratio")
        let items = [item00,item02,item03,item04]
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
