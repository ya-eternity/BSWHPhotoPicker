//
//  BackGroundViewController.swift
//  BSWHPhotoPicker
//
//  Created by 笔尚文化 on 2025/12/2.
//


public class BackGroundViewController: UIViewController, UIScrollViewDelegate {
    
    let topView = UIView()
    private lazy var backBtn = UIImageView().image(BSWHBundle.image(named: "templateNavBack")).enable(true).onTap { [weak self] in
        self?.dismiss(animated: true)
    }
    private lazy var titleLab = UILabel().color(kkColorFromHex("333333")).hnFont(size: 18.h, weight: .boldBase).centerAligned()
    let tabView = CustomScrViewList()
    var collectionView: UICollectionView!
    private var titles:[String] = []
    var items:[[TemplateModel]] = []
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.hidden(true)
    }
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        StickerManager.shared.templateOrBackground = 1
        titles = ConfigDataItem.getBackgroundTabData()
        items = ConfigDataItem.getBackgroundListData()
        
        setupTabView()
        setupCollectionView()
        tabView.delegate?.scrViewDidSelect(index: StickerManager.shared.selectedTemplateIndex)
    }
    
    private func setupTabView() {
        
        view.addSubview(topView)
        topView.backgroundColor(.white)
        topView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(kkNAVIGATION_BAR_HEIGHT + 44.h)
        }
        
        tabView.titles = titles
        tabView.backgroundColor = .white
        tabView.delegate = self
        topView.addSubview(tabView)
        topView.addSubview(backBtn)
        topView.addSubview(titleLab)
        tabView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(24.w)
            make.right.equalToSuperview()
            make.height.equalTo((44.h))
        }
        
        backBtn.snp.makeConstraints { make in
            make.width.height.equalTo(24.w)
            make.left.equalToSuperview().offset(12.w)
            make.bottom.equalTo(tabView.snp.top).offset(-8.h)
        }
        
        titleLab.snp.makeConstraints { make in
            make.height.equalTo(backBtn.snp.height)
            make.centerY.equalTo(backBtn.snp.centerY)
            make.centerX.equalToSuperview()
            make.left.equalToSuperview().offset(36.w)
            make.right.equalToSuperview().offset(-36.w)
        }
        titleLab.text = BSWHPhotoPickerLocalization.shared.localized("ChooseATemplate")
        
    }
    deinit {
        print("BackGroundViewController deinit 🔥🔥🔥")
        collectionView.delegate = nil
        collectionView.dataSource = nil
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.itemSize = CGSize(width: view.frame.width, height: view.frame.height - kkNAVIGATION_BAR_HEIGHT - 44.h)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .white
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(BackGroundContentCell.self, forCellWithReuseIdentifier: "BackGroundContentCell")
        
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(tabView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }

    // MARK: - =====================actions==========================
   
    
    // MARK: - =====================delegate==========================
    
    
    // MARK: - =====================Deinit==========================

}

// MARK: - UICollectionViewDataSource & Delegate
extension BackGroundViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return titles.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BackGroundContentCell", for: indexPath) as! BackGroundContentCell
        cell.delegate = self
        cell.items = items[indexPath.row]
        return cell
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(round(scrollView.contentOffset.x / scrollView.frame.width))
        tabView.selectIndex(index: page, animated: true)
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        let page = Int(round(scrollView.contentOffset.x / scrollView.frame.width))
        tabView.selectIndex(index: page, animated: true)
    }
}

// MARK: - CustomScrViewListDelegate
extension BackGroundViewController: CustomScrViewListDelegate {
    func scrViewDidSelect(index: Int) {
        collectionView.layoutIfNeeded()
        if let attributes = collectionView.layoutAttributesForItem(at: IndexPath(item: index, section: 0)) {
            collectionView.scrollRectToVisible(attributes.frame, animated: true)
        }
    }
}

extension BackGroundViewController: BackGroundContentCellDelegate {
    func backGroundContentCell(_ cell: BackGroundContentCell, didSelectItem item: TemplateModel, at index: IndexPath) {
//        guard let image = BSWHBundle.image(named: item.imageBg) else { return }
        var image:UIImage? = nil

        // --- special fixed icons ---
        if item.imageBg == "BackgroundPicker" {
            image = BSWHBundle.image(named: "BackgroundPicker")
        }
        if item.imageBg == "BackgroundNoColor" {
            image = BSWHBundle.image(named: "BackgroundNoColor")
        }
        
        if item.imageBg.hasPrefix("#") {
            image = kkCommon.imageFromHex(item.imageBg)
        }else{
            image = BSWHBundle.image(named: item.imageBg)
        }
        
        let controller = EditImageViewController(image: image!)
        controller.item = item
        controller.modalPresentationStyle = .fullScreen
        self.present(controller, animated: true)
    }
}



protocol BackGroundContentCellDelegate: AnyObject {
    func backGroundContentCell(_ cell: BackGroundContentCell, didSelectItem item: TemplateModel, at index: IndexPath)
}

// MARK: - UICollectionViewCell
class BackGroundContentCell: UICollectionViewCell {
    
    private var collectionView: UICollectionView!
    private var layout: BackGroundWaterfallLayout!
    weak var delegate: BackGroundContentCellDelegate?

    var items: [TemplateModel] = [] {
        didSet {
            // ✅ 每次更新都清空旧高度
            itemHeights = []
            calculateItemHeights()
            reloadCollectionView()
        }
    }
    
    deinit {
        print("BackGroundContentCell deinit")
        collectionView.delegate = nil
        collectionView.dataSource = nil
    }

    private var itemHeights: [CGFloat] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCollectionViewIfNeeded()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - CollectionView Setup
    
    private func setupCollectionViewIfNeeded() {
        guard collectionView == nil else { return }
        
        layout = BackGroundWaterfallLayout()
        layout.columnCount = 3
        layout.columnSpacing = 9
        layout.rowSpacing = 9
        layout.sectionInset = UIEdgeInsets(top: 12, left: 12, bottom: 8, right: 12)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(BackGroundWaterfallImageCell.self, forCellWithReuseIdentifier: "BackGroundWaterfallImageCell")
        
        contentView.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func reloadCollectionView() {
        layout.itemHeights = itemHeights
        collectionView.reloadData()
        // 确保在当前 runloop 后再刷新布局（避免闪动）
        DispatchQueue.main.async { [weak self] in
            self?.layout.invalidateLayout()
        }
    }

    
    // MARK: - Calculate Item Heights
    private func calculateItemHeights() {
        collectionView.layoutIfNeeded()
        let totalWidth = collectionView.bounds.width
        let columnCount: CGFloat = CGFloat(layout.columnCount)
        let spacing = layout.sectionInset.left
                    + layout.sectionInset.right
                    + layout.columnSpacing * (columnCount - 1)

        let itemWidth = (totalWidth - spacing) / columnCount

        itemHeights = items.map { item in
            let imageName = item.imageName
            if let cached = ImageHeightCache.shared.get(imageName: imageName, width: itemWidth) {
                return cached
            }
            let height: CGFloat
            if let img = BSWHBundle.image(named: imageName) {
                let ratio = img.size.height / img.size.width
                height = itemWidth * ratio
            } else {
                height = itemWidth
            }
            ImageHeightCache.shared.set(imageName: imageName, width: itemWidth, height: height)
            return height
        }
    }

}

// MARK: - UICollectionViewDataSource & Delegate
extension BackGroundContentCell: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BackGroundWaterfallImageCell", for: indexPath) as! BackGroundWaterfallImageCell
        cell.setItem(item: items[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        delegate?.backGroundContentCell(self, didSelectItem: item, at: indexPath)
    }

}

class BackGroundWaterfallImageCell: UICollectionViewCell {

    private let imgView: UIImageView = {
        let img = UIImageView()
        img.contentMode = .scaleAspectFill // ✅ 保持比例裁切
        img.clipsToBounds = true
        img.layer.cornerRadius = 10
        return img
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imgView)
        imgView.frame = contentView.bounds
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        imgView.frame = contentView.bounds
    }

    
    func setItem(item: TemplateModel) {
        
        // --- Color hex background ---
        if item.imageBg.hasPrefix("#") {
            imgView.image = kkCommon.imageFromHex(item.imageBg)
            return
        }

        // --- special fixed icons ---
        if item.imageBg == "BackgroundPicker" {
            imgView.image = BSWHBundle.image(named: "BackgroundPicker")
            return
        }
        if item.imageBg == "BackgroundNoColor" {
            imgView.image = BSWHBundle.image(named: "BackgroundNoColor")
            return
        }
        
        imgView.image = BSWHBundle.image(named: item.imageName)
    }
}

class BackGroundWaterfallLayout: UICollectionViewLayout {

    var columnCount = 3            // 两列
    var columnSpacing: CGFloat = 8 // 列间距
    var rowSpacing: CGFloat = 8    // 行间距
    var sectionInset: UIEdgeInsets = .init(top: 8, left: 8, bottom: 8, right: 8)

    var itemHeights: [CGFloat] = [] // 外部传入的动态高度数组
    private var attributes: [UICollectionViewLayoutAttributes] = []
    private var contentHeight: CGFloat = 0

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

    override func prepare() {
        guard let collectionView = collectionView else { return }
        attributes.removeAll()
        contentHeight = 0

        let width = collectionView.bounds.width
        let itemWidth = (width - sectionInset.left - sectionInset.right - CGFloat(columnCount - 1) * columnSpacing) / CGFloat(columnCount)

        var columnHeights = Array(repeating: sectionInset.top, count: columnCount)

        for item in 0 ..< itemHeights.count {
            let indexPath = IndexPath(item: item, section: 0)
            let height = itemHeights[item]

            // 找最短列
            let minColumn = columnHeights.firstIndex(of: columnHeights.min()!)!
            let x = sectionInset.left + CGFloat(minColumn) * (itemWidth + columnSpacing)
            let y = columnHeights[minColumn]

            let attr = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attr.frame = CGRect(x: x, y: y, width: itemWidth, height: height)

            attributes.append(attr)

            columnHeights[minColumn] = attr.frame.maxY + rowSpacing
            contentHeight = max(contentHeight, attr.frame.maxY)
        }
    }

    override var collectionViewContentSize: CGSize {
        return CGSize(width: collectionView?.bounds.width ?? 0, height: contentHeight + sectionInset.bottom)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return attributes.filter { $0.frame.intersects(rect) }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return attributes[indexPath.item]
    }
}

