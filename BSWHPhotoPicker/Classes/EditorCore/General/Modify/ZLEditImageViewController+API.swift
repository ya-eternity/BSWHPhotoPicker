//
//  ZLEditImageViewController+API.swift
//  BSWHPhotoPicker
//
//  Created by bswh on 2025/9/12.
//

import Foundation

// MARK: - 操作步骤API
extension ZLEditImageViewController {
    /// 当前进行的操作
    public var currentOperation: ZLImageEditorConfiguration.EditTool? {
        return selectedTool
    }
    
    /// 能否Redo
    public var canRedo: Bool {
        return editorManager.actions.count != editorManager.redoActions.count
    }
    
    /// 能否Undo
    public var canUndo: Bool {
        return !editorManager.actions.isEmpty
    }
    /// undo
    public func undoAction() {
        editorManager.undoAction()

    }
    
    /// redo
    public func redoAction() {
        editorManager.redoAction()
    }
    
    /// 切换操作
    public func switchOperation(type: ZLImageEditorConfiguration.EditTool?) {
        switch type {
        case .draw:// 绘制（包含绘制和擦除）
            selectedTool = ((selectedTool == .draw) ? nil : ZLImageEditorConfiguration.EditTool.draw)
        case .mosaic:// 马赛克
            selectedTool = ((selectedTool == .mosaic) ? nil : ZLImageEditorConfiguration.EditTool.mosaic)
            generateNewMosaicImageLayer()
        case .filter:// 滤镜
            selectedTool = ((selectedTool == .filter) ? nil : ZLImageEditorConfiguration.EditTool.filter)
        case .adjust:// 参数调整
            selectedTool = ((selectedTool == .adjust) ? nil : ZLImageEditorConfiguration.EditTool.adjust)
            generateAdjustImageRef()
        default:
            selectedTool = nil
        }
    }
    
    /// 设置擦除
    public func switchEraser() {
        isEraser = !isEraser
    }
    
    /// 完成编辑
    public func doneEdit() {
        var stickerStates: [ZLBaseStickertState] = []
        for view in stickersContainer.subviews {
            guard let view = view as? ZLBaseStickerView else { continue }
            stickerStates.append(view.state)
        }
        
        var hasEdit = true
        if drawPaths.isEmpty,
           currentClipStatus.editRect.size == imageSize,
           currentClipStatus.angle == 0,
           mosaicPaths.isEmpty,
           stickerStates.isEmpty,
           currentFilter.applier == nil,
           currentAdjustStatus.allValueIsZero {
            hasEdit = false
        }
        
        var resImage = originalImage
        var editModel: ZLEditImageModel?
        
        func callback() {
            dismiss(animated: animateDismiss) {
                self.editFinishBlock?(resImage, editModel)
            }
        }
        
        guard hasEdit else {
            callback()
            return
        }
        
        autoreleasepool {
            let hud = ZLProgressHUD(style: ZLImageEditorUIConfiguration.default().hudStyle)
            hud.show(in: view)
            
            DispatchQueue.main.async { [self] in
                resImage = buildImage()
                resImage = resImage.zl
                    .clipImage(
                        angle: currentClipStatus.angle,
                        editRect: currentClipStatus.editRect,
                        isCircle: currentClipStatus.ratio?.isCircle ?? false
                    ) ?? resImage
                if let oriDataSize = originalImage.pngData()?.count {
                    resImage = resImage.zl.compress(to: oriDataSize)
                }
                
                editModel = ZLEditImageModel(
                    drawPaths: drawPaths,
                    mosaicPaths: mosaicPaths,
                    clipStatus: currentClipStatus,
                    adjustStatus: currentAdjustStatus,
                    selectFilter: currentFilter,
                    stickers: stickerStates,
                    actions: editorManager.actions
                )
                
                hud.hide()
                callback()
            }
        }
    }
}


// MARK: - 绘制
extension ZLEditImageViewController {
    /// 选择绘制颜色
    public func chooseDraw(color: UIColor) {
        currentDrawColor = color
        isEraser = false
    }
}

// MARK: - 滤镜
extension ZLEditImageViewController {
    /// 所有滤镜
    public var allFilters: [ZLFilter] {
        return ZLImageEditorConfiguration.default().filters
    }
    
    /// 设置滤镜
    public func setFilter(filter: ZLFilter) {
        editorManager.storeAction(.filter(oldFilter: currentFilter, newFilter: filter))
        changeFilter(filter)
    }
}

// MARK: - 贴纸相关（包含图片贴纸和文字贴纸）
extension ZLEditImageViewController {
    /// 添加图片贴纸(固定为ZLImageSticker类型，如果ZLImageStickerView不适用，可以自定义，使用addCustomSticker方法)
    public func addImageSticker(image: UIImage) {
        let scale = mainScrollView.zoomScale
        let size = ZLImageStickerView.calculateSize(image: image, width: view.frame.width)
        let originFrame = getStickerOriginFrame(size)
        
        let imageSticker = ZLImageStickerView(image: image, originScale: 1 / scale, originAngle: -currentClipStatus.angle, originFrame: originFrame)
        addSticker(imageSticker)
        view.layoutIfNeeded()
        
        editorManager.storeAction(.sticker(oldState: nil, newState: imageSticker.state))
    }

    public func addImageSticker01(state: ImageStickerModel) -> EditableStickerView {
        var clearImage:UIImage? = nil
        if state.imageName == "empty" {
            clearImage = createTransparentImage(size: CGSize(width: state.originFrameWidth, height: state.originFrameHeight))
        }else{
            clearImage = state.image ?? BSWHBundle.image(named: state.imageName)!
        }
        let imageSticker = EditableStickerView(image:clearImage!, originScale: state.originScale, originAngle: state.originAngle, originFrame: CGRect(x: state.originFrameX.w, y: state.originFrameY.h, width: state.originFrameWidth.w, height: state.originFrameHeight.h),gesRotation: state.gesRotation,isBgImage: state.isBgImage,bgAddImageType: state.bgAddImageType!,imageMask: state.imageMask ?? "",imageData: state.imageData ?? BSWHBundle.image(named: state.bgAddImageType!)?.pngData(),zIndex: state.zIndex)
        addSticker(imageSticker)
        view.layoutIfNeeded()
        editorManager.storeAction(.sticker(oldState: nil, newState: imageSticker.state))
        return imageSticker
    }
    
    func createTransparentImage(size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            UIColor.clear.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
        }
    }

    
    /// 添加文字贴纸(固定为ZLTextSticker类型，如果ZLTextStickerView不适用，可以自定义，使用addCustomSticker方法)
    public func addTextSticker(font: UIFont) {
        showInputTextVC(font: font) { [weak self] text, textColor, font, image, style in
            self?.addTextStickersView(text, textColor: textColor, font: font, image: image, style: style)
        }
    }
    
    public func addTextSticker01(
        font: UIFont,
        completion: @escaping ((sticker: EditableTextStickerView, frame: CGRect)?) -> Void
    ) {
        showInputTextVC(font: font) { [weak self] text, textColor, font, image, style in
            guard let self = self else {
                completion(nil)
                return
            }
            if let result = self.addTextStickersView02(
                        text,
                        textColor: textColor,
                        font: font,
                        image: image,
                        style: style
                    ) {
                        completion((sticker: result.sticker, frame: result.originFrame))
                    } else {
                        completion(nil)
                    }
        }
    }
    
    /// 添加贴纸(需要继承ZLBaseStickerView)
    public func addCustomSticker(sticker: ZLBaseStickerView) {
        addSticker(sticker)
        editorManager.storeAction(.sticker(oldState: nil, newState: sticker.state))
    }
    
    /// 删除贴纸
    public func removeSticker(sticker: ZLBaseStickerView) {
        let endState: ZLBaseStickertState? = sticker.state
        sticker.moveToAshbin()
        editorManager.storeAction(.sticker(oldState: endState, newState: nil))
        
        stickersContainer.subviews.forEach { view in
            (view as? ZLStickerViewAdditional)?.gesIsEnabled = true
        }
    }
}

// MARK: - 马赛克
extension ZLEditImageViewController {
    
}

// MARK: - 参数调整
extension ZLEditImageViewController {
    
}


extension ZLEditImageViewController {
    private func setDrawOperation() {
        
    }
}

public enum ImageAddType:String,Codable {
    /// 方形
    case square = "square"
    /// 圆形
    case circle = "circle"
    /// 圆角方形
    case rectangle = "rectangle"
    /// 椭圆
    case ellipse = "ellipse"
    /// 异形
    case IrregularShape = "IrregularShape"
    /// 异形带蒙版
    case IrregularMask = "IrregularMask"
}

// MARK: - 模型定义
public class ImageStickerModel: Codable {
    /// 贴图的图片
    private var _image: UIImage?
    public var image: UIImage? {
        get {
            return _image ?? BSWHBundle.image(named: imageName)
        }
        set {
            _image = newValue
        }
    }
    public var imageName: String = ""
    /// 初始缩放和旋转
    public var originScale:Double = 0.0
    public var originAngle:Double = 0.0
    /// 位置大小
    public var originFrameX:Double = 0.0
    public var originFrameY:Double = 0.0
    public var originFrameWidth:Double = 0.0
    public var originFrameHeight:Double = 0.0
    /// 缩放和旋转
    public var gesScale:Double = 0.0
    public var gesRotation:Double = 0.0
    /// 贴图上添加照片的照片位置大小
    public var overlayRectX:Double? = nil
    public var overlayRectY:Double? = nil
    public var overlayRectWidth:Double? = nil
    public var overlayRectHeight:Double? = nil
    /// 添加的照片显示类型
    public var imageType:ImageAddType? = .square
    public var cornerRadiusScale:Double? = 0.1
    /// 异形显示的遮罩图片
    public var imageMask:String? = ""
    /// 是否是可以添加照片的贴图
    public var isBgImage:Bool = false
    /// 贴图上添加照片的照片
    public var imageData: Data? = nil // 用 Data 保存图片
    /// 可添加照片贴图中间加号图片类型
    public var bgAddImageType: String? = "addGrayImage"
    public var stickerImage: UIImage? {
        UIImage(data: (imageData ?? BSWHBundle.image(named: bgAddImageType!)!.pngData())!)
    }
    public var zIndex:Int? = 0
    
    enum CodingKeys: String, CodingKey {
        case imageName
        case imageData
        case originScale
        case originAngle
        case originFrameX
        case originFrameY
        case originFrameWidth
        case originFrameHeight
        case gesScale
        case gesRotation
        case overlayRectX
        case overlayRectY
        case overlayRectWidth
        case overlayRectHeight
        case imageType
        case cornerRadiusScale
        case imageMask
        case isBgImage
        case bgAddImageType
        case zIndex
    }

    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        imageName = try container.decode(String.self, forKey: .imageName)
        
        if let data = try container.decodeIfPresent(Data.self, forKey: .imageData) {
            _image = UIImage(data: data)
        } else {
            _image = nil
        }

        originScale = try container.decodeIfPresent(Double.self, forKey: .originScale) ?? 1.0
        originAngle = try container.decodeIfPresent(Double.self, forKey: .originAngle) ?? 0.0
        originFrameX = try container.decodeIfPresent(Double.self, forKey: .originFrameX) ?? 0.0
        originFrameY = try container.decodeIfPresent(Double.self, forKey: .originFrameY) ?? 0.0
        originFrameWidth = try container.decodeIfPresent(Double.self, forKey: .originFrameWidth) ?? 0.0
        originFrameHeight = try container.decodeIfPresent(Double.self, forKey: .originFrameHeight) ?? 0.0
        gesScale = try container.decodeIfPresent(Double.self, forKey: .gesScale) ?? 1.0
        gesRotation = try container.decodeIfPresent(Double.self, forKey: .gesRotation) ?? 0.0
        overlayRectX = try container.decodeIfPresent(Double.self, forKey: .overlayRectX)
        overlayRectY = try container.decodeIfPresent(Double.self, forKey: .overlayRectY)
        overlayRectWidth = try container.decodeIfPresent(Double.self, forKey: .overlayRectWidth)
        overlayRectHeight = try container.decodeIfPresent(Double.self, forKey: .overlayRectHeight)
        imageType = try container.decodeIfPresent(ImageAddType.self, forKey: .imageType)
        cornerRadiusScale = try container.decodeIfPresent(Double.self, forKey: .cornerRadiusScale) ?? 0.1
        imageMask = try container.decodeIfPresent(String.self, forKey: .imageMask)
        isBgImage = try container.decodeIfPresent(Bool.self, forKey: .isBgImage) ?? false
        bgAddImageType = try container.decodeIfPresent(String.self, forKey: .bgAddImageType) ?? "addGrayImage"
        zIndex = try container.decodeIfPresent(Int.self, forKey: .zIndex) ?? 0
    }

    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(imageName, forKey: .imageName)
        
        if let img = _image, let data = img.pngData() {
            try container.encode(data, forKey: .imageData)
        }
        
        try container.encode(originScale, forKey: .originScale)
        try container.encode(originAngle, forKey: .originAngle)
        try container.encode(originFrameX, forKey: .originFrameX)
        try container.encode(originFrameY, forKey: .originFrameY)
        try container.encode(originFrameWidth, forKey: .originFrameWidth)
        try container.encode(originFrameHeight, forKey: .originFrameHeight)
        try container.encode(gesScale, forKey: .gesScale)
        try container.encode(gesRotation, forKey: .gesRotation)
        try container.encodeIfPresent(overlayRectX, forKey: .overlayRectX)
        try container.encodeIfPresent(overlayRectY, forKey: .overlayRectY)
        try container.encodeIfPresent(overlayRectWidth, forKey: .overlayRectWidth)
        try container.encodeIfPresent(overlayRectHeight, forKey: .overlayRectHeight)
        try container.encodeIfPresent(imageType, forKey: .imageType)
        try container.encodeIfPresent(cornerRadiusScale, forKey: .cornerRadiusScale)
        try container.encodeIfPresent(imageMask, forKey: .imageMask)
        try container.encode(isBgImage, forKey: .isBgImage)
        try container.encode(bgAddImageType, forKey: .bgAddImageType)
        try container.encode(zIndex, forKey: .zIndex)
    }

    
    
    // MARK: - 初始化方法
    public init(
        image: UIImage? = nil,
        imageName: String = "",
        imageData: Data? = nil,
        originScale: Double = 1.0,
        originAngle: Double = 0.0,
        originFrame: CGRect = .zero,
        gesScale: Double = 1.0,
        gesRotation: Double = 0.0,
        overlayRect: CGRect? = nil,
        imageType: ImageAddType? = nil,
        cornerRadiusScale:Double = 0.1,
        isBgImage: Bool = false,
        bgAddImageType:String = "addGrayImage",
        zIndex:Int = 0
    ) {
        self._image = image
        self.imageName = imageName
        self.imageData = imageData
        self.originScale = originScale
        self.originAngle = originAngle
        self.originFrameX = originFrame.origin.x
        self.originFrameY = originFrame.origin.y
        self.originFrameWidth = originFrame.size.width
        self.originFrameHeight = originFrame.size.height
        self.gesScale = gesScale
        self.gesRotation = gesRotation
        self.imageType = imageType
        self.cornerRadiusScale = cornerRadiusScale
        self.isBgImage = isBgImage
        self.bgAddImageType = bgAddImageType
        self.zIndex = zIndex
        if let rect = overlayRect {
            self.overlayRectX = rect.origin.x
            self.overlayRectY = rect.origin.y
            self.overlayRectWidth = rect.size.width
            self.overlayRectHeight = rect.size.height
        }
    }
}

public extension ImageStickerModel {
    func deepCopy() -> ImageStickerModel {
        let copy = ImageStickerModel(
            imageName: self.imageName,
            imageData: self.imageData != nil ? Data(self.imageData!) : nil,
            originScale: self.originScale,
            originAngle: self.originAngle,
            originFrame: CGRect(
                x: self.originFrameX,
                y: self.originFrameY,
                width: self.originFrameWidth,
                height: self.originFrameHeight
            ),
            gesScale: self.gesScale,
            gesRotation: self.gesRotation,
            overlayRect: {
                if
                    let x = self.overlayRectX,
                    let y = self.overlayRectY,
                    let w = self.overlayRectWidth,
                    let h = self.overlayRectHeight {
                    return CGRect(x: x, y: y, width: w, height: h)
                }
                return nil
            }(),
            imageType: self.imageType,
            cornerRadiusScale:self.cornerRadiusScale ?? 0.1,
            isBgImage: self.isBgImage,
            zIndex: self.zIndex ?? 0
        )
        return copy
    }
}


public class EditableStickerView: ZLImageStickerView {

    // MARK: - 状态恢复
    public convenience init(state: ZLImageStickerState) {
        self.init(
            id: state.id,
            image: state.image,
            originScale: state.originScale,
            originAngle: state.originAngle,
            originFrame: state.originFrame,
            gesScale: state.gesScale,
            gesRotation: state.gesRotation,
            totalTranslationPoint: state.totalTranslationPoint,
            isBgImage: state.isBgImage,
            imageMask: state.imageMask,
            imageData: state.imageData,
            cornerRadiusScale:state.cornerRadiusScale,
            showBorder: false,
            zIndex: state.zIndex
        )
        self.refreshResizeButtonPosition()
    }

    // MARK: - 初始化
    public override init(
        id: String = UUID().uuidString,
        image: UIImage,
        originScale: CGFloat,
        originAngle: CGFloat,
        originFrame: CGRect,
        gesScale: CGFloat = 1,
        gesRotation: CGFloat = 0,
        totalTranslationPoint: CGPoint = .zero,
        isBgImage: Bool = false,
        bgAddImageType:String = "addGrayImage",
        imageMask:String = "",
        imageData:Data? = nil,
        cornerRadiusScale:Double? = 0.1,
        showBorder: Bool = false,
        zIndex:Int = 0
    ) {
        super.init(
            id: id,
            image: image,
            originScale: originScale,
            originAngle: originAngle,
            originFrame: originFrame,
            gesScale: gesScale,
            gesRotation: gesRotation,
            totalTranslationPoint: totalTranslationPoint,
            isBgImage: isBgImage,
            bgAddImageType: bgAddImageType,
            imageMask: imageMask,
            imageData: imageData,
            cornerRadiusScale:cornerRadiusScale ?? 0.1,
            showBorder: showBorder,
            zIndex: zIndex
        )
        borderView.layer.borderWidth = borderWidth
        borderView.layer.borderColor = UIColor.clear.cgColor
//        if showBorder { startTimer() }

        addButton()
        enableTapSelection()
    }

    init(image: UIImage, originScale: CGFloat, originAngle: CGFloat, originFrame: CGRect,gesRotation:CGFloat, isBgImage: Bool,bgAddImageType:String,imageMask:String,imageData:Data?,zIndex:Int?) {
        super.init(image: image, originScale: originScale, originAngle: originAngle, originFrame: originFrame,gesRotation: gesRotation, isBgImage: isBgImage,bgAddImageType:bgAddImageType,imageMask: imageMask,imageData: imageData!,zIndex: zIndex ?? 0)
        addButton()
        enableTapSelection()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - UI
    public var resizeButton: UIButton!
    public var leftTopButton: UIButton!
    public var rightTopButton: UIButton!
    
    // MARK: - Gesture / 状态
    private var initialTouchPoint: CGPoint = .zero
    private var panStartTransform: CGAffineTransform = .identity
    private var panStartTouchPoint: CGPoint = .zero

    private var gestureScale: CGFloat = 1
    private var gestureRotation: CGFloat = 0
    private var isPanGes: Bool = true
    private var isMultiTouchActive = false

    private var overlaySuperview: UIView? {
        var view = superview
        while let parent = view?.superview { view = parent }
        return view
    }

    // MARK: - 编辑状态
    public var isEditingCustom: Bool = false {
        didSet {
            resizeButton.isHidden = !isEditingCustom
            leftTopButton.isHidden = !isEditingCustom
            rightTopButton.isHidden = !isEditingCustom
            borderView.layer.borderColor = isEditingCustom == true ?  UIColor.white.cgColor : UIColor.clear.cgColor
            if isEditingCustom {
                overlaySuperview?.bringSubviewToFront(resizeButton)
                overlaySuperview?.bringSubviewToFront(leftTopButton)
                overlaySuperview?.bringSubviewToFront(rightTopButton)
            }
        }
    }

    private func addButton() {
        setupResizeButtonLocal()
        setupLeftTopButtonLocal()
        setupRightTopButtonLocal()
    }
    public func hiddenButton() {
        resizeButton.isHidden = false
        leftTopButton.isHidden = false
        rightTopButton.isHidden = false
    }
    private func showButton() {
        resizeButton.isHidden = true
        leftTopButton.isHidden = true
        rightTopButton.isHidden = true
    }
    // MARK: - Setup UI
    private func setupResizeButtonLocal() {
        let size: CGFloat = 36
        resizeButton = UIButton(type: .custom)
        resizeButton.frame = CGRect(x: 0, y: 0, width: size, height: size)
        resizeButton.layer.cornerRadius = size / 2
        resizeButton.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        resizeButton.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right.circle.fill"), for: .normal)
        resizeButton.tintColor = .white
        resizeButton.isHidden = true

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleResizePan(_:)))
        pan.delegate = self
        resizeButton.addGestureRecognizer(pan)
    }

    private func setupLeftTopButtonLocal() {
        let size: CGFloat = 36
        leftTopButton = UIButton(type: .custom)
        leftTopButton.frame = CGRect(x: 0, y: 0, width: size, height: size)
        leftTopButton.layer.cornerRadius = size / 2
        leftTopButton.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        leftTopButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        leftTopButton.tintColor = .white
        leftTopButton.isHidden = true

        leftTopButton.addTarget(self, action: #selector(handleLeftTopButtonTap), for: .touchUpInside)
    }

    private func setupRightTopButtonLocal() {
        let size: CGFloat = 36
        rightTopButton = UIButton(type: .custom)
        rightTopButton.frame = CGRect(x: 0, y: 0, width: size, height: size)
        rightTopButton.layer.cornerRadius = size / 2
        rightTopButton.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        rightTopButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        rightTopButton.tintColor = .white
        rightTopButton.isHidden = true
        rightTopButton.addTarget(self, action: #selector(handleRightTopButtonTap), for: .touchUpInside)
    }

    @objc private func handleRightTopButtonTap() {
        hideBorder()
        NotificationCenter.default.post(name: Notification.Name(rawValue: "duplicateSticker"), object: ["sticker":self])
    }
    
    @objc private func handleLeftTopButtonTap() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "tapStickerOutOverlay"), object: ["sticker":self,"leftTopTap":1])
//        UIView.animate(withDuration: 0.2, animations: {
//            self.alpha = 0
//            self.leftTopButton.alpha = 0
//            self.resizeButton.alpha = 0
//            self.rightTopButton.alpha = 0
//        }) { _ in
//            self.removeFromSuperview()
//        }
        setOperation(true)
        gesTranslationPoint = CGPoint(x: 10000, y: 10000)
        updateTransform01()
        setOperation(false)
    }

    private func enableTapSelection() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
        addGestureRecognizersForEditing()
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        isEditingCustom.toggle()
        NotificationCenter.default.post(name: Notification.Name(rawValue: "tapStickerOutOverlay"), object: ["sticker":self])
//        setOperation01(true)
//        isEditingCustom.toggle()
//        syncResizeButtonToOverlay()
//        setOperation01(false)
    }

    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        syncResizeButtonToOverlay()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        updateResizeButtonPosition()
    }

    public func syncResizeButtonToOverlay() {
        guard let overlay = overlaySuperview else { return }
        if resizeButton.superview != overlay {
            resizeButton.removeFromSuperview()
            overlay.addSubview(resizeButton)
        }
        if leftTopButton.superview != overlay {
            leftTopButton.removeFromSuperview()
            overlay.addSubview(leftTopButton)
        }
        if rightTopButton.superview != overlay {
            rightTopButton.removeFromSuperview()
            overlay.addSubview(rightTopButton)
        }
        updateResizeButtonPosition()
        overlay.bringSubviewToFront(resizeButton)
        overlay.bringSubviewToFront(leftTopButton)
        overlay.bringSubviewToFront(rightTopButton)
    }

    private func updateResizeButtonPosition() {
        guard let overlay = overlaySuperview else { return }
        let bottomRightInOverlay = self.convert(CGPoint(x: bounds.width, y: bounds.height), to: overlay)
        resizeButton.center = bottomRightInOverlay
        
        let topLeftInOverlay = self.convert(CGPoint(x: 0, y: 0), to: overlay)
        leftTopButton.center = topLeftInOverlay
        
        let topRightInOverlay = self.convert(CGPoint(x: bounds.width, y: 0), to: overlay)
        rightTopButton.center = topRightInOverlay
    }

    // MARK: - 平移
    @objc override func panAction(_ ges: UIPanGestureRecognizer) {
        guard gesIsEnabled else { return }
        guard !isMultiTouchActive else { return }
        let currentPoint = ges.location(in: superview)
        let dx = currentPoint.x - panStartTouchPoint.x
        let dy = currentPoint.y - panStartTouchPoint.y

        switch ges.state {
        case .began:
            panStartTouchPoint = currentPoint
            setOperation(true)
            hiddenButton()
        case .changed:
            gesTranslationPoint = CGPoint(x: dx, y: dy)
            if isPanGes {
                updateTransform01()
            }
        case .ended, .cancelled:
            totalTranslationPoint.x += dx
            totalTranslationPoint.y += dy
            gesTranslationPoint = .zero
            setOperation(false)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "tapStickerOutOverlay"), object: ["sticker":self])
        default: break
        }
    }

    // MARK: - 右下按钮旋转+缩放
    @objc private func handleResizePan(_ gesture: UIPanGestureRecognizer) {
        guard let overlay = overlaySuperview else { return }
        guard !isMultiTouchActive else { return }
        
        let centerInOverlay = self.convert(CGPoint(x: bounds.midX, y: bounds.midY), to: overlay)
        let touchPoint = gesture.location(in: overlay)

        switch gesture.state {
        case .began:
            initialTouchPoint = touchPoint
            setOperation(true)
            hiddenButton()
        case .changed:
            let dx = touchPoint.x - centerInOverlay.x
            let dy = touchPoint.y - centerInOverlay.y
            let distance = hypot(dx, dy)
            let angle = atan2(dy, dx)

            let startDx = initialTouchPoint.x - centerInOverlay.x
            let startDy = initialTouchPoint.y - centerInOverlay.y
            let startDistance = hypot(startDx, startDy)
            let startAngle = atan2(startDy, startDx)

            let rawScale = startDistance > 0 ? distance / startDistance : 1
            var finalScale = originScale * rawScale
            finalScale = min(max(finalScale, 0.3), 2)
            gesScale = finalScale / originScale

            let rotation = angle - startAngle
            gesRotation = rotation
            updateTransform()
        case .ended, .cancelled:
            originScale *= gesScale
            originAngle += gesRotation
            gesScale = 1
            gesRotation = originAngle
            updateTransform01()
            setOperation(false)
        default: break
        }
    }

    
    // MARK: - 更新 Transform (统一处理平移 + 旋转 + 缩放)
    public override func updateTransform() {
        var t = CGAffineTransform.identity
        // 平移
        t = t.translatedBy(x: totalTranslationPoint.x + gesTranslationPoint.x,
                           y: totalTranslationPoint.y + gesTranslationPoint.y)
        // 缩放
        t = t.scaledBy(x: originScale * gesScale, y: originScale * gesScale)
        // 旋转
        t = t.rotated(by: gesRotation + originAngle)
        transform = t
        updateResizeButtonPosition()
    }
    public func updateTransform01() {
        var t = CGAffineTransform.identity
        // 平移
        t = t.translatedBy(x: totalTranslationPoint.x + gesTranslationPoint.x,
                           y: totalTranslationPoint.y + gesTranslationPoint.y)
        // 旋转
        t = t.rotated(by: gesRotation)
        // 缩放
        t = t.scaledBy(x: originScale * gesScale, y: originScale * gesScale)
        transform = t
        updateResizeButtonPosition()
        gesRotation = originAngle
    }
    public func updateTransform02() {
        var t = CGAffineTransform.identity
        // 平移
        t = t.translatedBy(x: totalTranslationPoint.x,
                           y: totalTranslationPoint.y)
        // 旋转
        t = t.rotated(by: gesRotation)
        // 缩放
        t = t.scaledBy(x: originScale * gesScale, y: originScale * gesScale)
        transform = t
        updateResizeButtonPosition()
    }
    // MARK: - 双指旋转 + 缩放
    private func addGestureRecognizersForEditing() {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinch.delegate = self
        addGestureRecognizer(pinch)

        let rotation = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        rotation.delegate = self
        addGestureRecognizer(rotation)
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            isMultiTouchActive = true
            gestureScale = 1
            setOperation(true)
            hiddenButton()
            isPanGes = false
        case .changed:
            let rawScale = gesture.scale
            var finalScale = originScale * rawScale
            finalScale = min(max(finalScale, 0.3), 2)
            let scale = finalScale / originScale
            
            gestureScale = scale
            gesScale = gestureScale
            updateTransform02()
        case .ended, .cancelled:
            isMultiTouchActive = false
            originScale *= gesScale
            gesScale = 1
            setOperation(false)
            isPanGes = true
        default: break
        }
    }

    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        switch gesture.state {
        case .began:
            isMultiTouchActive = true
            gestureRotation = 0
            setOperation(true)
            hiddenButton()
            isPanGes = false
        case .changed:
            gestureRotation = gesture.rotation
            gesRotation = gestureRotation
            updateTransform()
        case .ended, .cancelled:
            isMultiTouchActive = false
            originAngle += gesRotation
            gesRotation = originAngle
            setOperation(false)
            isPanGes = true
        default: break
        }
    }

    // MARK: - 控制边框和按钮
    @objc public override func hideBorder() {
        super.hideBorder()
        showButton()
    }

//    public override func startTimer() {
//        cleanTimer()
//        borderView.layer.borderColor = UIColor.white.cgColor
//        hiddenButton()
//        timer = Timer.scheduledTimer(timeInterval: 2,
//                                     target: ZLWeakProxy(target: self),
//                                     selector: #selector(hideBorder),
//                                     userInfo: nil,
//                                     repeats: false)
//        RunLoop.current.add(timer!, forMode: .common)
//    }

    public func refreshResizeButtonPosition() {
        syncResizeButtonToOverlay()
        updateResizeButtonPosition()
    }

    public override func removeFromSuperview() {
        resizeButton.removeFromSuperview()
        leftTopButton.removeFromSuperview()
        rightTopButton.removeFromSuperview()
        super.removeFromSuperview()
    }

    deinit {
        resizeButton.removeFromSuperview()
        leftTopButton.removeFromSuperview()
        rightTopButton.removeFromSuperview()
    }

    // MARK: - UIGestureRecognizerDelegate
    public override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.view == resizeButton || otherGestureRecognizer.view == resizeButton {
            return false
        }
        return true
    }
}


public class EditableTextStickerView: ZLTextStickerView {
    
    // MARK: - UI
    public var resizeButton: UIButton!
    public var leftTopButton: UIButton!
    public var rightTopButton: UIButton!
    
    // MARK: - 状态
    private var initialTouchPoint: CGPoint = .zero
    private var panStartTransform: CGAffineTransform = .identity
    private var panStartTouchPoint: CGPoint = .zero

    private var gestureScale: CGFloat = 1
    private var gestureRotation: CGFloat = 0
    private var isMultiTouchActive = false
    private var isPanGes: Bool = true
    
    private var overlaySuperview: UIView? {
        var view = superview
        while let parent = view?.superview { view = parent }
        return view
    }
    
    // MARK: - 编辑模式
    public var isEditingCustom: Bool = false {
        didSet {
            resizeButton.isHidden = !isEditingCustom
            leftTopButton.isHidden = !isEditingCustom
            rightTopButton.isHidden = !isEditingCustom
            borderView.layer.borderColor = isEditingCustom ? UIColor.white.cgColor : UIColor.clear.cgColor
            if isEditingCustom {
                overlaySuperview?.bringSubviewToFront(resizeButton)
                overlaySuperview?.bringSubviewToFront(leftTopButton)
                overlaySuperview?.bringSubviewToFront(rightTopButton)
            }
        }
    }
    
    // MARK: - 状态恢复
    public convenience init(state: ZLTextStickerState) {
        self.init(
            id: state.id,
            text: state.text,
            textColor: state.textColor,
            font: state.font,
            style: state.style,
            image: state.image,
            originScale: state.originScale,
            originAngle: state.originAngle,
            originFrame: state.originFrame,
            gesScale: state.gesScale,
            gesRotation: state.gesRotation,
            totalTranslationPoint: state.totalTranslationPoint,
            imageData: state.imageData,
            showBorder: false
        )
        self.refreshResizeButtonPosition()
    }
    
    // MARK: - 初始化
    public override init(
        id: String = UUID().uuidString,
        text: String,
        textColor: UIColor,
        font: UIFont? = nil,
        style: ZLInputTextStyle,
        image: UIImage,
        originScale: CGFloat,
        originAngle: CGFloat,
        originFrame: CGRect,
        gesScale: CGFloat = 1,
        gesRotation: CGFloat = 0,
        totalTranslationPoint: CGPoint = .zero,
        imageData:Data? = nil,
        showBorder: Bool = false
    ) {
        super.init(
            id: id,
            text: text,
            textColor: textColor,
            font: font,
            style: style,
            image: image,
            originScale: originScale,
            originAngle: originAngle,
            originFrame: originFrame,
            gesScale: gesScale,
            gesRotation: gesRotation,
            totalTranslationPoint: totalTranslationPoint,
            imageData: imageData,
            showBorder: showBorder
        )
        
        borderView.layer.borderWidth = 1
        borderView.layer.borderColor = UIColor.clear.cgColor
        
        addButton()
        enableTapSelection()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - 按钮与UI
    private func addButton() {
        setupResizeButton()
        setupLeftTopButton()
        setupRightTopButton()
    }
    
    private func setupResizeButton() {
        let size: CGFloat = 36
        resizeButton = UIButton(type: .custom)
        resizeButton.frame = CGRect(x: 0, y: 0, width: size, height: size)
        resizeButton.layer.cornerRadius = size / 2
        resizeButton.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        resizeButton.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right.circle.fill"), for: .normal)
        resizeButton.tintColor = .white
        resizeButton.isHidden = true
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleResizePan(_:)))
        pan.delegate = self
        resizeButton.addGestureRecognizer(pan)
    }
    
    private func setupLeftTopButton() {
        let size: CGFloat = 36
        leftTopButton = UIButton(type: .custom)
        leftTopButton.frame = CGRect(x: 0, y: 0, width: size, height: size)
        leftTopButton.layer.cornerRadius = size / 2
        leftTopButton.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        leftTopButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        leftTopButton.tintColor = .white
        leftTopButton.isHidden = true
        leftTopButton.addTarget(self, action: #selector(handleLeftTopButtonTap), for: .touchUpInside)
    }
    
    private func setupRightTopButton() {
        let size: CGFloat = 36
        rightTopButton = UIButton(type: .custom)
        rightTopButton.frame = CGRect(x: 0, y: 0, width: size, height: size)
        rightTopButton.layer.cornerRadius = size / 2
        rightTopButton.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        rightTopButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        rightTopButton.tintColor = .white
        rightTopButton.isHidden = true
        rightTopButton.addTarget(self, action: #selector(handleRightTopButtonTap), for: .touchUpInside)
    }
    
    @objc private func handleLeftTopButtonTap() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "tapStickerOutOverlay"), object: ["sticker":self])
        UIView.animate(withDuration: 0.2) {
            self.alpha = 0
            self.leftTopButton.alpha = 0
            self.resizeButton.alpha = 0
            self.rightTopButton.alpha = 0
        } completion: { _ in
            self.removeFromSuperview()
        }
    }
    
    @objc private func handleRightTopButtonTap() {
        hideBorder()
        NotificationCenter.default.post(name: Notification.Name("duplicateTextSticker"), object: ["sticker": self])
    }
    
    // MARK: - 编辑启用
    public func enableTapSelection() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
        addGestureRecognizersForEditing()
    }
    
    @objc public func handleTap(_ gesture: UITapGestureRecognizer) {
        setOperation(true)
        isEditingCustom.toggle()
        syncButtonsToOverlay()
        setOperation(false)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "tapStickerOutOverlay"), object: ["sticker":self])
    }
    
    // MARK: - Overlay 同步
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        syncButtonsToOverlay()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateButtonPositions()
    }
    
    private func syncButtonsToOverlay() {
        guard let overlay = overlaySuperview else { return }
        for button in [resizeButton, leftTopButton, rightTopButton] {
            if button?.superview != overlay {
                button?.removeFromSuperview()
                overlay.addSubview(button!)
            }
        }
        updateButtonPositions()
        overlay.bringSubviewToFront(resizeButton)
        overlay.bringSubviewToFront(leftTopButton)
        overlay.bringSubviewToFront(rightTopButton)
    }
    
    private func updateButtonPositions() {
        guard let overlay = overlaySuperview else { return }
        resizeButton.center = convert(CGPoint(x: bounds.width, y: bounds.height), to: overlay)
        leftTopButton.center = convert(CGPoint(x: 0, y: 0), to: overlay)
        rightTopButton.center = convert(CGPoint(x: bounds.width, y: 0), to: overlay)
    }
    
    public func refreshResizeButtonPosition() {
        syncButtonsToOverlay()
        updateButtonPositions()
    }
    
    // MARK: - 平移
    @objc override func panAction(_ ges: UIPanGestureRecognizer) {
        guard gesIsEnabled else { return }
        guard !isMultiTouchActive else { return }
        let currentPoint = ges.location(in: superview)
        let dx = currentPoint.x - panStartTouchPoint.x
        let dy = currentPoint.y - panStartTouchPoint.y

        switch ges.state {
        case .began:
            panStartTouchPoint = currentPoint
            setOperation(true)
            showButtons()
        case .changed:
            gesTranslationPoint = CGPoint(x: dx, y: dy)
            if isPanGes {
                updateTransform01()
            }
        case .ended, .cancelled:
            totalTranslationPoint.x += dx
            totalTranslationPoint.y += dy
            gesTranslationPoint = .zero
            setOperation(false)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "tapStickerOutOverlay"), object: ["sticker":self])
        default: break
        }
    }
    
    // MARK: - 缩放 & 旋转按钮逻辑
    @objc private func handleResizePan(_ gesture: UIPanGestureRecognizer) {
        guard let overlay = overlaySuperview else { return }
        guard !isMultiTouchActive else { return }
        
        let center = convert(CGPoint(x: bounds.midX, y: bounds.midY), to: overlay)
        let point = gesture.location(in: overlay)
        
        switch gesture.state {
        case .began:
            initialTouchPoint = point
            setOperation(true)
            hiddenButtons()
        case .changed:
            let dx = point.x - center.x
            let dy = point.y - center.y
            let distance = hypot(dx, dy)
            let angle = atan2(dy, dx)
            
            let sdx = initialTouchPoint.x - center.x
            let sdy = initialTouchPoint.y - center.y
            let startDistance = hypot(sdx, sdy)
            let startAngle = atan2(sdy, sdx)
            
            let scale = startDistance > 0 ? distance / startDistance : 1
            let rotation = angle - startAngle
            
            gesScale = scale
            gesRotation = rotation
            updateTransform()
        case .ended, .cancelled:
            originScale *= gesScale
            originAngle += gesRotation
            gesScale = 1
            gesRotation = originAngle
            updateTransform01()
            setOperation(false)
        default:
            break
        }
    }
    
    // MARK: - 手势支持（双指旋转、缩放）
    private func addGestureRecognizersForEditing() {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinch.delegate = self
        addGestureRecognizer(pinch)
        
        let rotation = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        rotation.delegate = self
        addGestureRecognizer(rotation)
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            isMultiTouchActive = true
            gestureScale = 1
            setOperation(true)
            hiddenButtons()
            isPanGes = false
        case .changed:
            gestureScale = gesture.scale
            gesScale = gestureScale
            updateTransform02()
        case .ended, .cancelled:
            isMultiTouchActive = false
            originScale *= gesScale
            gesScale = 1
            setOperation(false)
            isPanGes = true
        default:
            break
        }
    }
    
    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        switch gesture.state {
        case .began:
            isMultiTouchActive = true
            gestureRotation = 0
            setOperation(true)
            hiddenButtons()
            isPanGes = false
        case .changed:
            gestureRotation = gesture.rotation
            gesRotation = gestureRotation
            updateTransform()
        case .ended, .cancelled:
            isMultiTouchActive = false
            originAngle += gesRotation
            gesRotation = originAngle
            setOperation(false)
            isPanGes = true
        default:
            break
        }
    }
    
    // MARK: - Transform 更新
    public override func updateTransform() {
        var t = CGAffineTransform.identity
        t = t.translatedBy(x: totalTranslationPoint.x + gesTranslationPoint.x,
                           y: totalTranslationPoint.y + gesTranslationPoint.y)
        t = t.scaledBy(x: originScale * gesScale, y: originScale * gesScale)
        t = t.rotated(by: gesRotation + originAngle)
        transform = t
        updateButtonPositions()
    }
    
    public func updateTransform01() {
        var t = CGAffineTransform.identity
        t = t.translatedBy(x: totalTranslationPoint.x + gesTranslationPoint.x,
                           y: totalTranslationPoint.y + gesTranslationPoint.y)
        t = t.rotated(by: gesRotation)
        t = t.scaledBy(x: originScale * gesScale, y: originScale * gesScale)
        transform = t
        updateButtonPositions()
        gesRotation = originAngle
    }
    
    public func updateTransform02() {
        var t = CGAffineTransform.identity
        t = t.translatedBy(x: totalTranslationPoint.x, y: totalTranslationPoint.y)
        t = t.rotated(by: gesRotation)
        t = t.scaledBy(x: originScale * gesScale, y: originScale * gesScale)
        transform = t
        updateButtonPositions()
    }
    
    // MARK: - 控制按钮显示
    private func hiddenButtons() {
        resizeButton.isHidden = true
        leftTopButton.isHidden = true
        rightTopButton.isHidden = true
    }
    
    public func showButtons() {
        resizeButton.isHidden = false
        leftTopButton.isHidden = false
        rightTopButton.isHidden = false
    }
    
    public override func hideBorder() {
        super.hideBorder()
        hiddenButtons()
    }
    
//    public override func startTimer() {
//        cleanTimer()
//        borderView.layer.borderColor = UIColor.white.cgColor
//        showButtons()
//        timer = Timer.scheduledTimer(timeInterval: 2,
//                                     target: ZLWeakProxy(target: self),
//                                     selector: #selector(hideBorder),
//                                     userInfo: nil,
//                                     repeats: false)
//        RunLoop.current.add(timer!, forMode: .common)
//    }
    
    public override func removeFromSuperview() {
        resizeButton.removeFromSuperview()
        leftTopButton.removeFromSuperview()
        rightTopButton.removeFromSuperview()
        super.removeFromSuperview()
    }
    
    deinit {
        resizeButton.removeFromSuperview()
        leftTopButton.removeFromSuperview()
        rightTopButton.removeFromSuperview()
    }
    
    // MARK: - GestureDelegate
    public override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.view == resizeButton || otherGestureRecognizer.view == resizeButton {
            return false
        }
        return true
    }
}
