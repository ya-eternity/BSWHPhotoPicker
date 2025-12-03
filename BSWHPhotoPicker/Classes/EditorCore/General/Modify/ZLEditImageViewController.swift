//
//  ZLEditImageViewController.swift
//  ZLImageEditor
//
//  Created by long on 2020/8/26.
//
//  Copyright (c) 2020 Long Zhang <495181165@qq.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit

public struct ZLClipStatus {
    var editRect: CGRect
    var angle: CGFloat = 0
    var ratio: ZLImageClipRatio?
    
    public init(
        editRect: CGRect,
        angle: CGFloat = 0,
        ratio: ZLImageClipRatio? = nil
    ) {
        self.editRect = editRect
        self.angle = angle
        self.ratio = ratio
    }
}

public struct ZLAdjustStatus {
    var brightness: Float = 0
    var contrast: Float = 0
    var saturation: Float = 0

    var allValueIsZero: Bool {
        brightness == 0 && contrast == 0 && saturation == 0
    }
    
    public init(
        brightness: Float = 0,
        contrast: Float = 0,
        saturation: Float = 0
    ) {
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
    }
}

public class ZLEditImageModel: NSObject {
    public let drawPaths: [ZLDrawPath]
    
    public let mosaicPaths: [ZLMosaicPath]
    
    public let clipStatus: ZLClipStatus?
    
    public let adjustStatus: ZLAdjustStatus?
    
    public let selectFilter: ZLFilter?
    
    public let stickers: [ZLBaseStickertState]
    
    public let actions: [ZLEditorAction]
    
    public init(
        drawPaths: [ZLDrawPath] = [],
        mosaicPaths: [ZLMosaicPath] = [],
        clipStatus: ZLClipStatus? = nil,
        adjustStatus: ZLAdjustStatus? = nil,
        selectFilter: ZLFilter? = nil,
        stickers: [ZLBaseStickertState] = [],
        actions: [ZLEditorAction] = []
    ) {
        self.drawPaths = drawPaths
        self.mosaicPaths = mosaicPaths
        self.clipStatus = clipStatus
        self.adjustStatus = adjustStatus
        self.selectFilter = selectFilter
        self.stickers = stickers
        self.actions = actions
        super.init()
    }
}



open class ZLEditImageViewController: UIViewController {
    static let maxDrawLineImageWidth: CGFloat = 600
    
    public var drawColViewH: CGFloat = 50
    
    public var filterColViewH: CGFloat = 90
    
    public var adjustColViewH: CGFloat = 60
    
    public var ashbinSize = CGSize(width: 160, height: 80)
    
    private var stickerMap: [String: EditableStickerView] = [:]

    open lazy var mainScrollView: UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .black
        view.minimumZoomScale = 1
        view.maximumZoomScale = 3
        view.delegate = self
        return view
    }()
    
    open lazy var containerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()
    
    // Show image.
    public lazy var imageView: UIImageView = {
        let view = UIImageView(image: originalImage)
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.backgroundColor = .white
        return view
    }()
    
    open lazy var eraserCircleView: UIImageView = {
        let imageView = UIImageView(image: .zl.getImage("zl_eraser_circle"))
        imageView.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        imageView.isHidden = true
        return imageView
    }()
    /// 是否是擦除
    var isEraser: Bool = false
    
    var adjustSlider: ZLAdjustSlider?
    
    var animateDismiss = true
    
    public var originalImage: UIImage
    
    // The frame after first layout, used in dismiss animation.
    var originalFrame: CGRect = .zero
    
    var tools: [ZLImageEditorConfiguration.EditTool]
    
    var adjustTools: [ZLImageEditorConfiguration.AdjustTool]
    
    var editImage: UIImage
    
    var editImageWithoutAdjust: UIImage
    
    var editImageAdjustRef: UIImage?
    
    // Show draw lines.
    lazy var drawingImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.isUserInteractionEnabled = true
        return view
    }()
    
    // Show text and image stickers.
    lazy var stickersContainer = UIView()
    
    var mosaicImage: UIImage?
    
    // Show mosaic image
    var mosaicImageLayer: CALayer?
    
    // The mask layer of mosaicImageLayer
    var mosaicImageLayerMaskLayer: CAShapeLayer?
    
    var selectedTool: ZLImageEditorConfiguration.EditTool?
    
    var selectedAdjustTool: ZLImageEditorConfiguration.AdjustTool?
    
    var drawColors: [UIColor]
    
    var currentDrawColor = ZLImageEditorConfiguration.default().defaultDrawColor
    
    var drawPaths: [ZLDrawPath]
    
    var drawLineWidth: CGFloat = 6
    
    var mosaicPaths: [ZLMosaicPath]
    
    var mosaicLineWidth: CGFloat = 25
    
    var thumbnailFilterImages: [UIImage] = []
    
    // Cache the filter image of original image
    var filterImages: [String: UIImage] = [:]
    
    var currentFilter: ZLFilter
    
    var stickers: [ZLBaseStickerView] = []
    
    var isScrolling = false
    
    var shouldLayout = true
    
    var imageStickerContainerIsHidden = true
    
    var fontChooserContainerIsHidden = true
    
    var currentClipStatus: ZLClipStatus
    
    private var preClipStatus: ZLClipStatus
    
    private var preStickerState: ZLBaseStickertState?
    
    var currentAdjustStatus: ZLAdjustStatus
    
    private var preAdjustStatus: ZLAdjustStatus
    
    var editorManager: ZLEditorManager
    
    private lazy var deleteDrawPaths: [ZLDrawPath] = []
    
    private var defaultDrawPathWidth: CGFloat = 0
    
    private var impactFeedback: UIImpactFeedbackGenerator?
    
    private lazy var panGes: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(drawAction(_:)))
        pan.maximumNumberOfTouches = 1
        pan.delegate = self
        return pan
    }()
    
    /// 是否允许交换图片宽高
    private var shouldSwapSize: Bool {
        currentClipStatus.angle.zl.toPi.truncatingRemainder(dividingBy: .pi) != 0
    }
    
    var imageSize: CGSize {
        if shouldSwapSize {
            return CGSize(width: originalImage.size.height, height: originalImage.size.width)
        } else {
            return originalImage.size
        }
    }
    
    
    var hasAdjustedImage = false
    /// 编辑完成
    @objc public var editFinishBlock: ((UIImage, ZLEditImageModel?) -> Void)?
    /// 取消编辑
    @objc public var cancelBlock: (() -> Void)?
    
    override open var prefersStatusBarHidden: Bool { true }
    
    override open var prefersHomeIndicatorAutoHidden: Bool { true }
    
    /// 延缓屏幕上下方通知栏弹出，避免手势冲突
    override open var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { [.top, .bottom] }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        deviceIsiPhone() ? .portrait : .all
    }
    
    deinit {
        zl_debugPrint("ZLEditImageViewController deinit")
    }
    
    @objc public class func showEditImageVC(
        parentVC: UIViewController?,
        animate: Bool = true,
        image: UIImage,
        editModel: ZLEditImageModel? = nil,
        completion: ((UIImage, ZLEditImageModel?) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        let tools = ZLImageEditorConfiguration.default().tools
        if ZLImageEditorConfiguration.default().showClipDirectlyIfOnlyHasClipTool, tools.count == 1, tools.contains(.clip) {
            let vc = ZLClipImageViewController(
                image: image,
                status: editModel?.clipStatus ?? ZLClipStatus(editRect: CGRect(origin: .zero, size: image.size))
            )
            
            vc.clipDoneBlock = { angle, editRect, ratio in
                let m = ZLEditImageModel(
                    clipStatus: ZLClipStatus(editRect: editRect, angle: angle, ratio: ratio)
                )
                completion?(image.zl.clipImage(angle: angle, editRect: editRect, isCircle: ratio.isCircle) ?? image, m)
            }
            vc.cancelClipBlock = {
                cancelBlock?()
            }
            vc.animateDismiss = animate
            vc.modalPresentationStyle = .fullScreen
            parentVC?.present(vc, animated: animate, completion: nil)
        } else {
            let vc = ZLEditImageViewController(image: image, editModel: editModel)
            vc.editFinishBlock = { ei, editImageModel in
                completion?(ei, editImageModel)
            }
            vc.cancelBlock = {
                cancelBlock?()
            }
            vc.animateDismiss = animate
            vc.modalPresentationStyle = .fullScreen
            parentVC?.present(vc, animated: animate, completion: nil)
        }
    }
    
    @objc public init(image: UIImage, editModel: ZLEditImageModel? = nil) {
        var image = image
        if image.scale != 1,
           let cgImage = image.cgImage {
            image = image.zl.resize_vI(
                CGSize(width: cgImage.width, height: cgImage.height),
                scale: 1
            ) ?? image
        }
        
        originalImage = image.zl.fixOrientation()
        editImage = originalImage
        editImageWithoutAdjust = originalImage
        currentClipStatus = editModel?.clipStatus ?? ZLClipStatus(editRect: CGRect(origin: .zero, size: image.size))
        preClipStatus = currentClipStatus
        drawColors = ZLImageEditorConfiguration.default().drawColors
        currentFilter = editModel?.selectFilter ?? .normal
        drawPaths = editModel?.drawPaths ?? []
        mosaicPaths = editModel?.mosaicPaths ?? []
        currentAdjustStatus = editModel?.adjustStatus ?? ZLAdjustStatus()
        preAdjustStatus = currentAdjustStatus
        
        var ts = ZLImageEditorConfiguration.default().tools
        if ts.contains(.imageSticker), ZLImageEditorConfiguration.default().imageStickerContainerView == nil {
            ts.removeAll { $0 == .imageSticker }
        }
        tools = ts
        adjustTools = ZLImageEditorConfiguration.default().adjustTools
        selectedAdjustTool = adjustTools.first
        editorManager = ZLEditorManager(actions: editModel?.actions ?? [])
        
        super.init(nibName: nil, bundle: nil)
        
        editorManager.delegate = self
        if !drawColors.contains(currentDrawColor) {
            currentDrawColor = drawColors.first!
        }
        stickers = editModel?.stickers.compactMap {
            ZLBaseStickerView.initWithState($0)
        } ?? []
    }
    
    public func replaceBgImage(image:UIImage,editModel: ZLEditImageModel? = nil) {
        var image = image
//        if image.scale != 1,
//           let cgImage = image.cgImage {
//            image = image.zl.resize_vI(
//                CGSize(width: cgImage.width, height: cgImage.height),
//                scale: 1
//            ) ?? image
//        }
        
        originalImage = image.zl.fixOrientation()
        editImage = originalImage
        editImageWithoutAdjust = originalImage
        currentClipStatus = editModel?.clipStatus ?? ZLClipStatus(editRect: CGRect(origin: .zero, size: image.size))
        preClipStatus = currentClipStatus
        drawColors = ZLImageEditorConfiguration.default().drawColors
        currentFilter = editModel?.selectFilter ?? .normal
        drawPaths = editModel?.drawPaths ?? []
        mosaicPaths = editModel?.mosaicPaths ?? []
        currentAdjustStatus = editModel?.adjustStatus ?? ZLAdjustStatus()
        preAdjustStatus = currentAdjustStatus
        
        var ts = ZLImageEditorConfiguration.default().tools
        if ts.contains(.imageSticker), ZLImageEditorConfiguration.default().imageStickerContainerView == nil {
            ts.removeAll { $0 == .imageSticker }
        }
        tools = ts
        adjustTools = ZLImageEditorConfiguration.default().adjustTools
        selectedAdjustTool = adjustTools.first
        editorManager = ZLEditorManager(actions: editModel?.actions ?? [])
        editorManager.delegate = self
        if !drawColors.contains(currentDrawColor) {
            currentDrawColor = drawColors.first!
        }
        stickers = editModel?.stickers.compactMap {
            ZLBaseStickerView.initWithState($0)
        } ?? []
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        rotationImageView()
        if tools.contains(.filter) {
            generateFilterImages()
        }
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard tools.contains(.draw) else { return }
        
        var size = drawingImageView.frame.size
        if shouldSwapSize {
            swap(&size.width, &size.height)
        }
        
        var toImageScale = ZLEditImageViewController.maxDrawLineImageWidth / size.width
        if editImage.size.width / editImage.size.height > 1 {
            toImageScale = ZLEditImageViewController.maxDrawLineImageWidth / size.height
        }
        
        let width = drawLineWidth / mainScrollView.zoomScale * toImageScale
        defaultDrawPathWidth = width
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard shouldLayout else {
            return
        }
        
        shouldLayout = false
        zl_debugPrint("edit image layout subviews")
        var insets = UIEdgeInsets.zero
        if #available(iOS 11.0, *) {
            insets = view.safeAreaInsets
        }
        insets.top = max(insets.top, 20)
        
        mainScrollView.frame = view.bounds
        resetContainerViewFrame()
        
        if !drawPaths.isEmpty {
            drawLine()
        }
        if !mosaicPaths.isEmpty {
            generateNewMosaicImage()
        }
    }

    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        shouldLayout = true
    }
    
    func generateFilterImages() {
        let size: CGSize
        let ratio = (originalImage.size.width / originalImage.size.height)
        let fixLength: CGFloat = 200
        if ratio >= 1 {
            size = CGSize(width: fixLength * ratio, height: fixLength)
        } else {
            size = CGSize(width: fixLength, height: fixLength / ratio)
        }
        let thumbnailImage = originalImage.zl.resize(size) ?? originalImage
        
        DispatchQueue.global().async {
            self.thumbnailFilterImages = ZLImageEditorConfiguration.default().filters.map { $0.applier?(thumbnailImage) ?? thumbnailImage }
        }
    }
    
    public func resetContainerViewFrame() {
        mainScrollView.setZoomScale(1, animated: true)
        imageView.image = editImage.forceRGBA()
        let editRect = currentClipStatus.editRect
        
        let editSize = editRect.size
        let scrollViewSize = mainScrollView.frame.size
        let ratio = min(scrollViewSize.width / editSize.width, scrollViewSize.height / editSize.height)
        let w = ratio * editSize.width * mainScrollView.zoomScale
        let h = ratio * editSize.height * mainScrollView.zoomScale
        containerView.frame = CGRect(x: max(0, (scrollViewSize.width - w) / 2), y: max(0, (scrollViewSize.height - h) / 2), width: w, height: h)
        mainScrollView.contentSize = containerView.frame.size
        
        if currentClipStatus.ratio?.isCircle == true {
            let mask = CAShapeLayer()
            let path = UIBezierPath(arcCenter: CGPoint(x: w / 2, y: h / 2), radius: w / 2, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            mask.path = path.cgPath
            containerView.layer.mask = mask
        } else {
            containerView.layer.mask = nil
        }
        
        let scaleImageOrigin = CGPoint(x: -editRect.origin.x * ratio, y: -editRect.origin.y * ratio)
        let scaleImageSize = CGSize(width: imageSize.width * ratio, height: imageSize.height * ratio)
        imageView.frame = CGRect(origin: scaleImageOrigin, size: scaleImageSize)
        mosaicImageLayer?.frame = imageView.bounds
        mosaicImageLayerMaskLayer?.frame = imageView.bounds
        drawingImageView.frame = imageView.frame
        stickersContainer.frame = imageView.frame
        
        // Optimization for long pictures.
        if (editRect.height / editRect.width) > (view.frame.height / view.frame.width * 1.1) {
            let widthScale = view.frame.width / w
            mainScrollView.maximumZoomScale = widthScale
            mainScrollView.zoomScale = widthScale
            mainScrollView.contentOffset = .zero
        } else if editRect.width / editRect.height > 1 {
            mainScrollView.maximumZoomScale = max(3, view.frame.height / h)
        }
        
        originalFrame = view.convert(containerView.frame, from: mainScrollView)
        isScrolling = false
    }
    
    func setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(mainScrollView)
        mainScrollView.addSubview(containerView)
        containerView.addSubview(imageView)
        containerView.addSubview(drawingImageView)
        containerView.addSubview(stickersContainer)
        
        if tools.contains(.draw) {
            containerView.addSubview(eraserCircleView)
            
            impactFeedback = UIImpactFeedbackGenerator(style: .light)
        }
        
        if tools.contains(.filter) {
            if let applier = currentFilter.applier {
                let image = applier(originalImage)
                editImage = image
                editImageWithoutAdjust = image
                filterImages[currentFilter.name] = image
            }
        }
        
        if tools.contains(.adjust) {
            editImage = editImage.zl.adjust(
                brightness: currentAdjustStatus.brightness,
                contrast: currentAdjustStatus.contrast,
                saturation: currentAdjustStatus.saturation
            ) ?? editImage
            
            adjustSlider = ZLAdjustSlider()
            if let selectedAdjustTool = selectedAdjustTool {
                changeAdjustTool(selectedAdjustTool)
            }
            adjustSlider?.beginAdjust = { [weak self] in
                guard let `self` = self else { return }
                self.preAdjustStatus = self.currentAdjustStatus
            }
            adjustSlider?.valueChanged = { [weak self] value in
                self?.adjustValueChanged(value)
            }
            adjustSlider?.endAdjust = { [weak self] in
                guard let `self` = self else { return }
                self.editorManager.storeAction(
                    .adjust(oldStatus: self.preAdjustStatus, newStatus: self.currentAdjustStatus)
                )
                self.hasAdjustedImage = true
            }
            adjustSlider?.isHidden = true
            view.addSubview(adjustSlider!)
        }
        
        if tools.contains(.mosaic) {
            mosaicImage = editImage.zl.mosaicImage()
            
            mosaicImageLayer = CALayer()
            mosaicImageLayer?.contents = mosaicImage?.cgImage
            imageView.layer.addSublayer(mosaicImageLayer!)
            
            mosaicImageLayerMaskLayer = CAShapeLayer()
            mosaicImageLayerMaskLayer?.strokeColor = UIColor.blue.cgColor
            mosaicImageLayerMaskLayer?.fillColor = nil
            mosaicImageLayerMaskLayer?.lineCap = .round
            mosaicImageLayerMaskLayer?.lineJoin = .round
            imageView.layer.addSublayer(mosaicImageLayerMaskLayer!)
            
            mosaicImageLayer?.mask = mosaicImageLayerMaskLayer
        }
        
        if tools.contains(.imageSticker) {
            ZLImageEditorConfiguration.default().imageStickerContainerView?.hideBlock = { [weak self] in
                
                self?.imageStickerContainerIsHidden = true
            }
            
        }
        
        view.addGestureRecognizer(panGes)
        mainScrollView.panGestureRecognizer.require(toFail: panGes)
        
        stickers.forEach { self.addSticker($0) }
    }
    
    /// 根据point查找可响应的sticker
    func findResponderSticker(_ point: CGPoint) -> UIView? {
        // 倒序查找subview
        for sticker in stickersContainer.subviews.reversed() {
            let rect = stickersContainer.convert(sticker.frame, to: view)
            if rect.contains(point) {
                return sticker
            }
        }
        
        return nil
    }
    
    func rotationImageView() {
        let transform = CGAffineTransform(rotationAngle: currentClipStatus.angle.zl.toPi)
        imageView.transform = transform
        drawingImageView.transform = transform
        stickersContainer.transform = transform
    }
    
    func clipBtnClick() {
        preClipStatus = currentClipStatus
        
        var currentEditImage = editImage
        autoreleasepool {
            currentEditImage = buildImage()
        }
        
        let vc = ZLClipImageViewController(image: currentEditImage, status: currentClipStatus)
        let rect = mainScrollView.convert(containerView.frame, to: view)
        vc.presentingEditViewController = self
        vc.presentAnimateFrame = rect
        vc.presentAnimateImage = currentEditImage.zl
            .clipImage(
                angle: currentClipStatus.angle,
                editRect: currentClipStatus.editRect,
                isCircle: currentClipStatus.ratio?.isCircle ?? false
            )
        vc.modalPresentationStyle = .fullScreen
        
        vc.clipDoneBlock = { [weak self] angle, editRect, selectRatio in
            guard let `self` = self else { return }
            
            self.clipImage(status: ZLClipStatus(editRect: editRect, angle: angle, ratio: selectRatio))
            self.editorManager.storeAction(.clip(oldStatus: self.preClipStatus, newStatus: self.currentClipStatus))
        }
        
        vc.cancelClipBlock = { [weak self] () in
            self?.resetContainerViewFrame()
        }
        
        present(vc, animated: false) {
            self.mainScrollView.alpha = 0
            self.adjustSlider?.alpha = 0
        }
        
        selectedTool = nil
    }
    
    private func clipImage(status: ZLClipStatus) {
        let oldAngle = currentClipStatus.angle
        let oldContainerSize = stickersContainer.frame.size
        if oldAngle != status.angle {
            currentClipStatus.angle = status.angle
            rotationImageView()
        }
        
        currentClipStatus.editRect = status.editRect
        currentClipStatus.ratio = status.ratio
        resetContainerViewFrame()
        recalculateStickersFrame(oldContainerSize, oldAngle, status.angle)
    }
    
    
    func changeAdjustTool(_ tool: ZLImageEditorConfiguration.AdjustTool) {
        selectedAdjustTool = tool
        
        switch tool {
        case .brightness:
            adjustSlider?.value = currentAdjustStatus.brightness
        case .contrast:
            adjustSlider?.value = currentAdjustStatus.contrast
        case .saturation:
            adjustSlider?.value = currentAdjustStatus.saturation
        }
    }
    
    @objc func drawAction(_ pan: UIPanGestureRecognizer) {
        // 橡皮擦
        if selectedTool == .draw, isEraser {
            eraserAction(pan)
            return
        }
        // 绘制
        if selectedTool == .draw {
            let point = pan.location(in: drawingImageView)
            if pan.state == .began {
                
                let originalRatio = min(mainScrollView.frame.width / originalImage.size.width, mainScrollView.frame.height / originalImage.size.height)
                let ratio = min(
                    mainScrollView.frame.width / currentClipStatus.editRect.width,
                    mainScrollView.frame.height / currentClipStatus.editRect.height
                )
                let scale = ratio / originalRatio
                // Zoom to original size
                var size = drawingImageView.frame.size
                size.width /= scale
                size.height /= scale
                if shouldSwapSize {
                    swap(&size.width, &size.height)
                }
                
                var toImageScale = ZLEditImageViewController.maxDrawLineImageWidth / size.width
                if editImage.size.width / editImage.size.height > 1 {
                    toImageScale = ZLEditImageViewController.maxDrawLineImageWidth / size.height
                }
                
                let path = ZLDrawPath(
                    pathColor: currentDrawColor,
                    pathWidth: drawLineWidth / mainScrollView.zoomScale,
                    defaultLinePath: defaultDrawPathWidth,
                    ratio: ratio / originalRatio / toImageScale,
                    startPoint: point
                )

                drawPaths.append(path)
            } else if pan.state == .changed {
                let path = drawPaths.last
                path?.addLine(to: point)
                drawLine()
            } else if pan.state == .cancelled || pan.state == .ended {
                if let path = drawPaths.last {
                    editorManager.storeAction(.draw(path))
                }
            }
        } else if selectedTool == .mosaic {
            let point = pan.location(in: imageView)
            if pan.state == .began {
                
                var actualSize = currentClipStatus.editRect.size
                if shouldSwapSize {
                    swap(&actualSize.width, &actualSize.height)
                }
                let ratio = min(
                    mainScrollView.frame.width / currentClipStatus.editRect.width,
                    mainScrollView.frame.height / currentClipStatus.editRect.height
                )
                
                let pathW = mosaicLineWidth / mainScrollView.zoomScale
                let path = ZLMosaicPath(pathWidth: pathW, ratio: ratio, startPoint: point)
                
                mosaicImageLayerMaskLayer?.lineWidth = pathW
                mosaicImageLayerMaskLayer?.path = path.path.cgPath
                mosaicPaths.append(path)
            } else if pan.state == .changed {
                let path = mosaicPaths.last
                path?.addLine(to: point)
                mosaicImageLayerMaskLayer?.path = path?.path.cgPath
            } else if pan.state == .cancelled || pan.state == .ended {
                if let path = mosaicPaths.last {
                    editorManager.storeAction(.mosaic(path))
                }
                generateNewMosaicImage()
            }
        }
    }
    
    private func eraserAction(_ pan: UIPanGestureRecognizer) {
        // 相对于drawingImageView的point
        let point = pan.location(in: drawingImageView)
        let originalRatio = min(mainScrollView.frame.width / originalImage.size.width, mainScrollView.frame.height / originalImage.size.height)
        let ratio = min(
            mainScrollView.frame.width / currentClipStatus.editRect.width,
            mainScrollView.frame.height / currentClipStatus.editRect.height
        )
        let scale = ratio / originalRatio
        // 缩放到最初的size
        var size = drawingImageView.frame.size
        size.width /= scale
        size.height /= scale
        if shouldSwapSize {
            swap(&size.width, &size.height)
        }
        
        var toImageScale = ZLEditImageViewController.maxDrawLineImageWidth / size.width
        if editImage.size.width / editImage.size.height > 1 {
            toImageScale = ZLEditImageViewController.maxDrawLineImageWidth / size.height
        }
        
        let pointScale = ratio / originalRatio / toImageScale
        // 转换为drawPath的point
        let drawPoint = CGPoint(x: point.x / pointScale, y: point.y / pointScale)
        if pan.state == .began {
            eraserCircleView.isHidden = false
            impactFeedback?.prepare()
        }
        
        if pan.state == .began || pan.state == .changed {
            var transform: CGAffineTransform = .identity
            
            let angle = ((Int(currentClipStatus.angle) % 360) + 360) % 360
            let drawingImageViewSize = drawingImageView.frame.size
            if angle == 90 {
                transform = transform.translatedBy(x: 0, y: -drawingImageViewSize.width)
            } else if angle == 180 {
                transform = transform.translatedBy(x: -drawingImageViewSize.width, y: -drawingImageViewSize.height)
            } else if angle == 270 {
                transform = transform.translatedBy(x: -drawingImageViewSize.height, y: 0)
            }
            transform = transform.concatenating(drawingImageView.transform)
            let transformedPoint = point.applying(transform)
            // 将变换后的点转换到 containerView 的坐标系
            let pointInContainerView = drawingImageView.convert(transformedPoint, to: containerView)
            eraserCircleView.center = pointInContainerView
            
            var needDraw = false
            for path in drawPaths {
                if path.path.contains(drawPoint), !deleteDrawPaths.contains(path) {
                    path.willDelete = true
                    deleteDrawPaths.append(path)
                    needDraw = true
                    impactFeedback?.impactOccurred()
                }
            }
            if needDraw {
                drawLine()
            }
        } else {
            eraserCircleView.isHidden = true
            if !deleteDrawPaths.isEmpty {
                editorManager.storeAction(.eraser(deleteDrawPaths))
                drawPaths.removeAll { deleteDrawPaths.contains($0) }
                deleteDrawPaths.removeAll()
                drawLine()
            }
        }
    }
    
    // 生成一个没有调整参数前的图片
    func generateAdjustImageRef() {
        editImageAdjustRef = generateNewMosaicImage(
            inputImage: editImageWithoutAdjust,
            inputMosaicImage: editImageWithoutAdjust.zl.mosaicImage()
        )
    }
    
    func adjustValueChanged(_ value: Float) {
        guard let selectedAdjustTool else {
            return
        }
        
        switch selectedAdjustTool {
        case .brightness:
            if currentAdjustStatus.brightness == value {
                return
            }
            
            currentAdjustStatus.brightness = value
        case .contrast:
            if currentAdjustStatus.contrast == value {
                return
            }
            
            currentAdjustStatus.contrast = value
        case .saturation:
            if currentAdjustStatus.saturation == value {
                return
            }
            
            currentAdjustStatus.saturation = value
        }
        
        adjustStatusChanged()
    }
    
    private func adjustStatusChanged() {
        let resultImage = editImageAdjustRef?.zl.adjust(
            brightness: currentAdjustStatus.brightness,
            contrast: currentAdjustStatus.contrast,
            saturation: currentAdjustStatus.saturation
        )
        
        guard let resultImage else { return }
        
        editImage = resultImage
        imageView.image = editImage.forceRGBA()
    }
    
    private func generateNewMosaicLayerIfAdjust() {
        defer {
            hasAdjustedImage = false
        }
        
        guard tools.contains(.mosaic), hasAdjustedImage else { return }
        generateNewMosaicImageLayer()
        
        if !mosaicPaths.isEmpty {
            generateNewMosaicImage()
        }
    }
    
    
    func showInputTextVC(_ text: String? = nil, textColor: UIColor? = nil, font: UIFont? = nil, style: ZLInputTextStyle = .normal, completion: @escaping (String, UIColor, UIFont, UIImage?, ZLInputTextStyle) -> Void) {
        var bgImage: UIImage?
        autoreleasepool {
            // Calculate image displayed frame on the screen.
            var r = mainScrollView.convert(view.frame, to: containerView)
            r.origin.x += mainScrollView.contentOffset.x / mainScrollView.zoomScale
            r.origin.y += mainScrollView.contentOffset.y / mainScrollView.zoomScale
            let scale = imageSize.width / imageView.frame.width
            r.origin.x *= scale
            r.origin.y *= scale
            r.size.width *= scale
            r.size.height *= scale
            
            let isCircle = currentClipStatus.ratio?.isCircle ?? false
            bgImage = buildImage()
                .zl.clipImage(angle: currentClipStatus.angle, editRect: currentClipStatus.editRect, isCircle: isCircle)?
                .zl.clipImage(angle: 0, editRect: r, isCircle: isCircle)
        }
        
        let vc = ZLInputTextViewController(image: bgImage, text: text, font: font, textColor: textColor, style: style)
        
        vc.endInput = { text, textColor, font, image, style in
            completion(text, textColor, font, image, style)
        }
        
        vc.modalPresentationStyle = .fullScreen
        showDetailViewController(vc, sender: nil)
    }
    
    func getStickerOriginFrame(_ size: CGSize) -> CGRect {
        let scale = mainScrollView.zoomScale
        // Calculate the display rect of container view.
        let x = (mainScrollView.contentOffset.x - containerView.frame.minX) / scale
        let y = (mainScrollView.contentOffset.y - containerView.frame.minY) / scale
        let w = view.frame.width / scale
        let h = view.frame.height / scale
        // Convert to text stickers container view.
        let r = containerView.convert(CGRect(x: x, y: y, width: w, height: h), to: stickersContainer)
        let originFrame = CGRect(x: r.minX + (r.width - size.width) / 2, y: r.minY + (r.height - size.height) / 2, width: size.width, height: size.height)
        return originFrame
    }
    
    /// Add text sticker
    public func addTextStickersView01(_ text: String, textColor: UIColor, font: UIFont, image: UIImage?, style: ZLInputTextStyle,originFrame:CGRect,originScale:CGFloat,originAngle:CGFloat,gesScale:CGFloat,gesRotation:CGFloat,totalTranslationPoint:CGPoint) {
        guard !text.isEmpty, let image = image else { return }
        
        let size = EditableTextStickerView.calculateSize(image: image)
        let originFrame = getStickerOriginFrame(size)
        
        let textSticker = EditableTextStickerView(
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
            totalTranslationPoint: totalTranslationPoint
        )
        addSticker(textSticker)
        
        editorManager.storeAction(.sticker(oldState: nil, newState: textSticker.state))
    }
    /// Add text sticker
    public func addTextStickersView(_ text: String, textColor: UIColor, font: UIFont, image: UIImage?, style: ZLInputTextStyle) {
        guard !text.isEmpty, let image = image else { return }
        
        let scale = mainScrollView.zoomScale
        let size = EditableTextStickerView.calculateSize(image: image)
        let originFrame = getStickerOriginFrame(size)
        
        let textSticker = EditableTextStickerView(
            text: text,
            textColor: textColor,
            font: font,
            style: style,
            image: image,
            originScale: 1 / scale,
            originAngle: -currentClipStatus.angle,
            originFrame: originFrame,
            imageData:createTransparentImage(size: CGSize(width: originFrame.width, height: originFrame.height))?.pngData()
        )
        
        addSticker(textSticker)
        
        editorManager.storeAction(.sticker(oldState: nil, newState: textSticker.state))
    }
    
    public func addTextStickersView02(_ text: String, textColor: UIColor, font: UIFont, image: UIImage?, style: ZLInputTextStyle) -> (sticker: EditableTextStickerView, originFrame: CGRect)? {
        guard !text.isEmpty, let image = image else { return nil}
        
        let scale = mainScrollView.zoomScale
        let size = EditableTextStickerView.calculateSize(image: image)
        let originFrame = getStickerOriginFrame(size)
        
        let textSticker = EditableTextStickerView(
            text: text,
            textColor: textColor,
            font: font,
            style: style,
            image: image,
            originScale: 1 / scale,
            originAngle: -currentClipStatus.angle,
            originFrame: originFrame,
            imageData:createTransparentImage(size: CGSize(width: originFrame.width, height: originFrame.height))?.pngData()
        )
        return (textSticker, originFrame)
    }
    
    func addSticker(_ sticker: ZLBaseStickerView) {
        stickersContainer.addSubview(sticker)
        sticker.frame = sticker.originFrame
        configSticker(sticker)
    }
    
    func addSticker01(_ sticker: ZLBaseStickerView, at index: Int? = nil) {
        if let idx = index, idx < stickersContainer.subviews.count {
            stickersContainer.insertSubview(sticker, at: idx)
        } else {
            stickersContainer.addSubview(sticker)
        }

        sticker.frame = sticker.originFrame
        configSticker(sticker)
    }

    
    private func removeSticker(id: String?) {
        guard let id else { return }
        
        for sticker in stickersContainer.subviews.reversed() {
            guard let stickerID = (sticker as? ZLBaseStickerView)?.id,
                  stickerID == id else {
                continue
            }
            
            (sticker as? ZLBaseStickerView)?.moveToAshbin()
            
            break
        }
    }
    
    private func configSticker(_ sticker: ZLBaseStickerView) {
        sticker.delegate = self
        mainScrollView.pinchGestureRecognizer?.require(toFail: sticker.pinchGes)
        mainScrollView.panGestureRecognizer.require(toFail: sticker.panGes)
        panGes.require(toFail: sticker.panGes)
    }
    
    func recalculateStickersFrame(_ oldSize: CGSize, _ oldAngle: CGFloat, _ newAngle: CGFloat) {
        let currSize = stickersContainer.frame.size
        let scale: CGFloat
        if Int(newAngle - oldAngle) % 180 == 0 {
            scale = currSize.width / oldSize.width
        } else {
            scale = currSize.height / oldSize.width
        }
        
        stickersContainer.subviews.forEach { view in
            (view as? ZLStickerViewAdditional)?.addScale(scale)
        }
    }
    
    func drawLine() {
        let originalRatio = min(mainScrollView.frame.width / originalImage.size.width, mainScrollView.frame.height / originalImage.size.height)
        let ratio = min(
            mainScrollView.frame.width / currentClipStatus.editRect.width,
            mainScrollView.frame.height / currentClipStatus.editRect.height
        )
        let scale = ratio / originalRatio
        // Zoom to original size
        var size = drawingImageView.frame.size
        size.width /= scale
        size.height /= scale
        if shouldSwapSize {
            swap(&size.width, &size.height)
        }
        var toImageScale = ZLEditImageViewController.maxDrawLineImageWidth / size.width
        if editImage.size.width / editImage.size.height > 1 {
            toImageScale = ZLEditImageViewController.maxDrawLineImageWidth / size.height
        }
        size.width *= toImageScale
        size.height *= toImageScale
        
        drawingImageView.image = UIGraphicsImageRenderer.zl.renderImage(size: size) { context in
            context.setAllowsAntialiasing(true)
            context.setShouldAntialias(true)
            for path in drawPaths {
                path.drawPath()
            }
        }
    }
    
    func changeFilter(_ filter: ZLFilter) {
        func adjustImage(_ image: UIImage) -> UIImage {
            guard tools.contains(.adjust), !currentAdjustStatus.allValueIsZero else {
                return image
            }
            
            return image.zl.adjust(
                brightness: currentAdjustStatus.brightness,
                contrast: currentAdjustStatus.contrast,
                saturation: currentAdjustStatus.saturation
            ) ?? image
        }
        
        currentFilter = filter
        if let image = filterImages[currentFilter.name] {
            editImage = adjustImage(image)
            editImageWithoutAdjust = image
        } else {
            let image = currentFilter.applier?(originalImage) ?? originalImage
            editImage = adjustImage(image)
            editImageWithoutAdjust = image
            filterImages[currentFilter.name] = image
        }
        
        if tools.contains(.mosaic) {
            generateNewMosaicImageLayer()
            
            if mosaicPaths.isEmpty {
                imageView.image = editImage.forceRGBA()
            } else {
                generateNewMosaicImage()
            }
        } else {
            imageView.image = editImage.forceRGBA()
        }
    }
    
    func generateNewMosaicImageLayer() {
        mosaicImage = editImage.zl.mosaicImage()
        
        mosaicImageLayer?.removeFromSuperlayer()
        
        mosaicImageLayer = CALayer()
        mosaicImageLayer?.frame = imageView.bounds
        mosaicImageLayer?.contents = mosaicImage?.cgImage
        imageView.layer.insertSublayer(mosaicImageLayer!, below: mosaicImageLayerMaskLayer)
        
        mosaicImageLayer?.mask = mosaicImageLayerMaskLayer
    }
    
    /// 传入inputImage 和 inputMosaicImage则代表仅想要获取新生成的mosaic图片
    @discardableResult
    func generateNewMosaicImage(inputImage: UIImage? = nil, inputMosaicImage: UIImage? = nil) -> UIImage? {
        let renderRect = CGRect(origin: .zero, size: originalImage.size)
        
        var midImage = UIGraphicsImageRenderer.zl.renderImage(size: originalImage.size) { format in
            format.scale = self.originalImage.scale
        } imageActions: { context in
            if inputImage != nil {
                inputImage?.draw(in: renderRect)
            } else {
                var drawImage: UIImage?
                if tools.contains(.filter), let image = filterImages[currentFilter.name] {
                    drawImage = image
                } else {
                    drawImage = originalImage
                }
                
                drawImage?.draw(at: .zero)
                if tools.contains(.adjust), !currentAdjustStatus.allValueIsZero {
                    drawImage = drawImage?.zl.adjust(
                        brightness: currentAdjustStatus.brightness,
                        contrast: currentAdjustStatus.contrast,
                        saturation: currentAdjustStatus.saturation
                    )
                }
                
                drawImage?.draw(in: renderRect)
            }
            
            mosaicPaths.forEach { path in
                context.move(to: path.startPoint)
                path.linePoints.forEach { point in
                    context.addLine(to: point)
                }
                context.setLineWidth(path.path.lineWidth / path.ratio)
                context.setLineCap(.round)
                context.setLineJoin(.round)
                context.setBlendMode(.clear)
                context.strokePath()
            }
        }
        
        guard let midCgImage = midImage.cgImage else { return nil }
        midImage = UIImage(cgImage: midCgImage, scale: editImage.scale, orientation: .up)
        
        let temp = UIGraphicsImageRenderer.zl.renderImage(size: originalImage.size) { format in
            format.scale = self.originalImage.scale
        } imageActions: { _ in
            // 由于生成的mosaic图片可能在边缘区域出现空白部分，导致合成后会有黑边，所以在最下面先画一张原图
            originalImage.draw(in: renderRect)
            (inputMosaicImage ?? mosaicImage)?.draw(in: renderRect)
            midImage.draw(at: .zero)
        }
        
        guard let cgi = temp.cgImage else { return nil }
        let image = UIImage(cgImage: cgi, scale: editImage.scale, orientation: .up).forceRGBA()
        
        if inputImage != nil {
            return image
        }
        
        editImage = image!
        imageView.image = image
        mosaicImageLayerMaskLayer?.path = nil
        
        return image
    }
    
    func buildImage() -> UIImage {
        let imageSize = originalImage.size
        
        let temp = UIGraphicsImageRenderer.zl.renderImage(size: editImage.size) { format in
            format.scale = self.editImage.scale
        } imageActions: { context in
            editImage.draw(at: .zero)
            drawingImageView.image?.draw(in: CGRect(origin: .zero, size: imageSize))
            
            if !stickersContainer.subviews.isEmpty {
                let scale = self.imageSize.width / stickersContainer.frame.width
                stickersContainer.subviews.forEach { view in
                    (view as? ZLStickerViewAdditional)?.resetState()
                }
                context.concatenate(CGAffineTransform(scaleX: scale, y: scale))
                stickersContainer.layer.render(in: context)
                context.concatenate(CGAffineTransform(scaleX: 1 / scale, y: 1 / scale))
            }
        }
        
        guard let cgi = temp.cgImage else {
            return editImage
        }
        return UIImage(cgImage: cgi, scale: editImage.scale, orientation: .up)
    }
    
    func finishClipDismissAnimate() {
        mainScrollView.alpha = 1
        UIView.animate(withDuration: 0.1) {
            self.adjustSlider?.alpha = 1
        }
    }
}

extension ZLEditImageViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard imageStickerContainerIsHidden, fontChooserContainerIsHidden else {
            return false
        }
        if gestureRecognizer is UIPanGestureRecognizer {
            guard let st = selectedTool else {
                return false
            }
            return (st == .draw || st == .mosaic) && !isScrolling
        }
        
        return true
    }
}

// MARK: scroll view delegate
extension ZLEditImageViewController: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return containerView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = (scrollView.frame.width > scrollView.contentSize.width) ? (scrollView.frame.width - scrollView.contentSize.width) * 0.5 : 0
        let offsetY = (scrollView.frame.height > scrollView.contentSize.height) ? (scrollView.frame.height - scrollView.contentSize.height) * 0.5 : 0
        containerView.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        isScrolling = false
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == mainScrollView else {
            return
        }
        isScrolling = true
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView == mainScrollView else {
            return
        }
        isScrolling = decelerate
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == mainScrollView else {
            return
        }
        isScrolling = false
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView == mainScrollView else {
            return
        }
        isScrolling = false
    }
}



extension ZLEditImageViewController: ZLStickerViewDelegate {

    func stickerBeginOperation(_ sticker: ZLBaseStickerView) {
//        stickersContainer.bringSubviewToFront(sticker)
        preStickerState = sticker.state
        
        stickersContainer.subviews.forEach { view in
            if view !== sticker {
                (view as? ZLStickerViewAdditional)?.resetState()
                (view as? ZLStickerViewAdditional)?.gesIsEnabled = false
            }
        }
    }
    
    func stickerBeginOperation01(_ sticker: ZLBaseStickerView) {
//        stickersContainer.bringSubviewToFront(sticker)
        stickersContainer.subviews.forEach { view in
            if view !== sticker {
                (view as? ZLStickerViewAdditional)?.resetState()
                (view as? ZLStickerViewAdditional)?.gesIsEnabled = false
            }
        }
    }
    
    func stickerOnOperation(_ sticker: ZLBaseStickerView, panGes: UIPanGestureRecognizer) {
        
    }
    
    func stickerEndOperation(_ sticker: ZLBaseStickerView, panGes: UIPanGestureRecognizer) {
        
        let endState: ZLBaseStickertState? = sticker.state
        editorManager.storeAction(.sticker(oldState: preStickerState, newState: endState))
        preStickerState = nil
        
        stickersContainer.subviews.forEach { view in
            (view as? ZLStickerViewAdditional)?.gesIsEnabled = true
        }
    }
    
    func stickerEndOperation01(_ sticker: ZLBaseStickerView, panGes: UIPanGestureRecognizer) {

//        let endState: ZLBaseStickertState? = sticker.state
//        editorManager.storeAction(.sticker(oldState: preStickerState, newState: endState))
//        preStickerState = nil
        
        stickersContainer.subviews.forEach { view in
            (view as? ZLStickerViewAdditional)?.gesIsEnabled = true
        }
    }
    
    func stickerEndOperation02(_ sticker: ZLBaseStickerView, panGes: UIPanGestureRecognizer, oldState: ZLImageStickerState, newState: ZLImageStickerState) {

        let endState: ZLBaseStickertState? = sticker.state
        editorManager.storeAction(.sticker(oldState: preStickerState, newState: endState))
        preStickerState = nil
        
        stickersContainer.subviews.forEach { view in
            (view as? ZLStickerViewAdditional)?.gesIsEnabled = true
        }
    }
    func stickerDidTap(_ sticker: ZLBaseStickerView) {
        stickersContainer.bringSubviewToFront(sticker)
        stickersContainer.subviews.forEach { view in
            if view !== sticker {
                (view as? ZLStickerViewAdditional)?.resetState()
            }
        }
    }
    
    func sticker(_ textSticker: ZLTextStickerView, editText text: String) {
        showInputTextVC(text, textColor: textSticker.textColor, font: textSticker.font, style: textSticker.style) { text, textColor, font, image, style in
            guard let image = image, !text.isEmpty else {
                textSticker.moveToAshbin()
                return
            }
            
//            textSticker.startTimer()
            guard textSticker.text != text || textSticker.textColor != textColor || textSticker.style != style || textSticker.font != font else {
                return
            }
            textSticker.text = text
            textSticker.textColor = textColor
            textSticker.style = style
            textSticker.image = image
            textSticker.font = font
            let newSize = ZLTextStickerView.calculateSize(image: image)
            textSticker.changeSize(to: newSize)
        }
    }
}

// MARK: unod & redo

extension ZLEditImageViewController: ZLEditorManagerDelegate {
    func editorManager(_ manager: ZLEditorManager, didUpdateActions actions: [ZLEditorAction], redoActions: [ZLEditorAction]) {
//        undoBtn.isEnabled = !actions.isEmpty
//        redoBtn.isEnabled = actions.count != redoActions.count
    }
    
    func editorManager(_ manager: ZLEditorManager, undoAction action: ZLEditorAction) {
        switch action {
        case let .draw(path):
            undoDraw(path)
        case let .eraser(paths):
            undoEraser(paths)
        case let .clip(oldStatus, _):
            undoOrRedoClip(oldStatus)
        case let .sticker(oldState, newState):
            undoSticker(oldState, newState)
        case let .mosaic(path):
            undoMosaic(path)
        case let .filter(oldFilter, _):
            undoOrRedoFilter(oldFilter)
        case let .adjust(oldStatus, _):
            undoOrRedoAdjust(oldStatus)
        }
    }
    
    func editorManager(_ manager: ZLEditorManager, redoAction action: ZLEditorAction) {
        switch action {
        case let .draw(path):
            redoDraw(path)
        case let .eraser(paths):
            redoEraser(paths)
        case let .clip(_, newStatus):
            undoOrRedoClip(newStatus)
        case let .sticker(oldState, newState):
            redoSticker(oldState, newState)
        case let .mosaic(path):
            redoMosaic(path)
        case let .filter(_, newFilter):
            undoOrRedoFilter(newFilter)
        case let .adjust(_, newStatus):
            undoOrRedoAdjust(newStatus)
        }
    }
    
    private func undoDraw(_ path: ZLDrawPath) {
        drawPaths.removeLast()
        drawLine()
    }
    
    private func redoDraw(_ path: ZLDrawPath) {
        drawPaths.append(path)
        drawLine()
    }
    
    private func undoEraser(_ paths: [ZLDrawPath]) {
        paths.forEach { $0.willDelete = false }
        drawPaths.append(contentsOf: paths)
        drawPaths = drawPaths.sorted { $0.index < $1.index }
        drawLine()
    }
    
    private func redoEraser(_ paths: [ZLDrawPath]) {
        drawPaths.removeAll { paths.contains($0) }
        drawLine()
    }
    
    private func undoOrRedoClip(_ status: ZLClipStatus) {
        clipImage(status: status)
        preClipStatus = status
    }
    
    private func undoMosaic(_ path: ZLMosaicPath) {
        mosaicPaths.removeLast()
        generateNewMosaicImage()
    }
    
    private func redoMosaic(_ path: ZLMosaicPath) {
        mosaicPaths.append(path)
        generateNewMosaicImage()
    }
    
    private func undoSticker(_ oldState: ZLBaseStickertState?, _ newState: ZLBaseStickertState?) {
        guard let oldState else {
            removeSticker(id: newState?.id)
            return
        }
        
        removeSticker(id: oldState.id)
        if oldState.isMember(of: ZLTextStickerState.self) {
            if let sticker = EditableTextStickerView.initWithState(oldState) as? EditableTextStickerView {
                addSticker(sticker)
                sticker.enableTapSelection()
                sticker.hideBorder()
            }
        }else{
            if let sticker = EditableStickerView.initWithState(oldState) {
//                addSticker(sticker)
                addSticker01(sticker, at: oldState.zIndex)
                if oldState.isBgImage == true {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "stickerImageAddTap"), object: ["sticker":sticker])
                }
            }
        }
    }
    
    private func redoSticker(_ oldState: ZLBaseStickertState?, _ newState: ZLBaseStickertState?) {
        guard let newState else {
            removeSticker(id: oldState?.id)
            return
        }
        
        removeSticker(id: newState.id)
        if newState.isMember(of: ZLTextStickerState.self) {
            if let sticker = EditableTextStickerView.initWithState(newState) as? EditableTextStickerView {
                addSticker(sticker)
                sticker.enableTapSelection()
                sticker.hideBorder()
            }
        }else{
            if let sticker = EditableStickerView.initWithState(newState) {
//                addSticker(sticker)
                addSticker01(sticker, at: newState.zIndex)
                if newState.isBgImage == true {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "stickerImageAddTap"), object: ["sticker":sticker])
                }
            }
        }
    }
    
    private func undoOrRedoFilter(_ filter: ZLFilter?) {
        guard let filter else { return }
        changeFilter(filter)
//        
//        let filters = ZLImageEditorConfiguration.default().filters
//        
//        guard let index = filters.firstIndex(where: { $0.name == filter.name }) else {
//            return
//        }
//        
//        let indexPath = IndexPath(row: index, section: 0)
//        filterCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
//        filterCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
//        filterCollectionView.reloadData()
    }
    
    private func undoOrRedoAdjust(_ status: ZLAdjustStatus) {
//        var adjustTool: ZLImageEditorConfiguration.AdjustTool?
//        
//        if currentAdjustStatus.brightness != status.brightness {
//            adjustTool = .brightness
//        } else if currentAdjustStatus.contrast != status.contrast {
//            adjustTool = .contrast
//        } else if currentAdjustStatus.saturation != status.saturation {
//            adjustTool = .saturation
//        }
//        
//        currentAdjustStatus = status
//        preAdjustStatus = status
//        adjustStatusChanged()
//        
//        guard let adjustTool else { return }
//        
//        changeAdjustTool(adjustTool)
//        
//        guard let adjustCollectionView,
//              let index = adjustTools.firstIndex(where: { $0 == adjustTool }) else {
//            return
//        }
//        
//        let indexPath = IndexPath(row: index, section: 0)
//        adjustCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
//        adjustCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
//        adjustCollectionView.reloadData()
    }
}


//extension ZLEditImageViewController: UICollectionViewDataSource, UICollectionViewDelegate {
//    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        if collectionView == editToolCollectionView {
//            return tools.count
//        } else if collectionView == drawColorCollectionView {
//            return drawColors.count
//        } else if collectionView == filterCollectionView {
//            return thumbnailFilterImages.count
//        } else {
//            return adjustTools.count
//        }
//    }
//
//    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        if collectionView == editToolCollectionView {
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLEditToolCell.zl.identifier, for: indexPath) as! ZLEditToolCell
//
//            let toolType = tools[indexPath.row]
//            cell.icon.isHighlighted = false
//            cell.toolType = toolType
//            cell.icon.isHighlighted = toolType == selectedTool
//
//            return cell
//        } else if collectionView == drawColorCollectionView {
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLDrawColorCell.zl.identifier, for: indexPath) as! ZLDrawColorCell
//
//            let c = drawColors[indexPath.row]
//            cell.color = c
//
//            return cell
//        } else if collectionView == filterCollectionView {
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLFilterImageCell.zl.identifier, for: indexPath) as! ZLFilterImageCell
//
//            let image = thumbnailFilterImages[indexPath.row]
//            let filter = ZLImageEditorConfiguration.default().filters[indexPath.row]
//
//            cell.nameLabel.text = filter.name
//            cell.imageView.image = image
//
//            if currentFilter === filter {
//                cell.nameLabel.textColor = .zl.toolTitleTintColor
//            } else {
//                cell.nameLabel.textColor = .zl.toolTitleNormalColor
//            }
//
//            return cell
//        } else {
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLAdjustToolCell.zl.identifier, for: indexPath) as! ZLAdjustToolCell
//
//            let tool = adjustTools[indexPath.row]
//
//            cell.imageView.isHighlighted = false
//            cell.adjustTool = tool
//            let isSelected = tool == selectedAdjustTool
//            cell.imageView.isHighlighted = isSelected
//
//            if isSelected {
//                cell.nameLabel.textColor = .zl.toolTitleTintColor
//            } else {
//                cell.nameLabel.textColor = .zl.toolTitleNormalColor
//            }
//
//            return cell
//        }
//    }
//
//    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        if collectionView == editToolCollectionView {
//            let toolType = tools[indexPath.row]
//            switch toolType {
//            case .draw:
//                break
//            case .clip:
//                clipBtnClick()
//            case .imageSticker:
//                imageStickerBtnClick()
//            case .textSticker:
//                textStickerBtnClick()
//            case .mosaic:
//                break
//            case .filter:
//                break
//            case .adjust:
//                break
//            }
//        } else {
//            let tool = adjustTools[indexPath.row]
//            if tool != selectedAdjustTool {
//                changeAdjustTool(tool)
//            }
//        }
//        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
//        collectionView.reloadData()
//    }
//}
