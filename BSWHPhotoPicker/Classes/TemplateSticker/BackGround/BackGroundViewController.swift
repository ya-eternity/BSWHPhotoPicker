//
//  BackGroundViewController.swift
//  BSWHPhotoPicker
//
//  Created by 笔尚文化 on 2025/12/2.
//

import UIKit

public class BackGroundViewController: UIViewController, UIScrollViewDelegate {
    
    let topView = UIView()
    private lazy var backBtn = UIImageView().image(BSWHBundle.image(named: "templateNavBack")).enable(true).onTap {
        self.dismiss(animated: true)
    }
    private lazy var titleLab = UILabel().color(kkColorFromHex("333333")).hnFont(size: 18.h, weight: .boldBase).centerAligned()
    let tabView = CustomScrViewList()
    var collectionView: UICollectionView!
    private var titles:[String] = []
    var items:[[TemplateModel]] = []
    var colorItem:TemplateModel? = nil
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.hidden(true)
    }
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        StickerManager.shared.templateOrBackground = 2
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
        titleLab.text = BSWHPhotoPickerLocalization.shared.localized("Background")
        
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
        collectionView.register(BackgroundContentCell.self, forCellWithReuseIdentifier: "BackgroundContentCell")
        
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BackgroundContentCell", for: indexPath) as! BackgroundContentCell
        cell.items = items[indexPath.row]
        cell.delegate = self
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

extension BackGroundViewController: BackgroundContentCellDelegate {
    func backgroundContentCell(_ cell: BackgroundContentCell, didSelectItem item: TemplateModel, at index: IndexPath) {
        var imageBG:UIImage? = nil
        if item.imageBg.hasPrefix("#") {
            if let img = kkCommon.imageFromHex(item.imageBg) {
                imageBG = img
            }
            guard let image = imageBG else { return }
            persentVC(item: item, image: image)
        }else if item.imageBg == "BackgroundNoColor" {
            if let img = kkCommon.imageFromHex("#FFFFFF",alpha: 0) {
                imageBG = img
            }
            guard let image = imageBG else { return }
            persentVC(item: item, image: image)
        }else if item.imageBg == "BackgroundPicker" {
            colorItem = item
            let picker = UIColorPickerViewController()
            picker.delegate = self
            picker.supportsAlpha = true
            picker.modalPresentationStyle = .automatic
            present(picker, animated: true, completion: nil)
        }else {
            imageBG = BSWHBundle.image(named: item.imageBg)
            guard let image = imageBG else { return }
            persentVC(item: item, image: image)
        }
    }
    
    func persentVC(item: TemplateModel,image:UIImage){
        let controller = EditImageViewController(image: image)
        controller.item = item
        controller.modalPresentationStyle = .fullScreen
        self.present(controller, animated: true)
    }
}

extension BackGroundViewController: UIColorPickerViewControllerDelegate {
    public func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {

    }

    public func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController){
        let color = viewController.selectedColor
        print("选中的颜色:", color)
        if let cItem = colorItem {
            viewController.dismiss(animated: false)
            let img = UIImage.from(color: color, size: CGSize(width: 400, height: 400))
            let controller = EditImageViewController(image: img)
            controller.pickerColor = color
            controller.item = cItem
            controller.modalPresentationStyle = .fullScreen
            self.present(controller, animated: true)
        }
    }

}

protocol BackgroundContentCellDelegate: AnyObject {
    func backgroundContentCell(_ cell: BackgroundContentCell, didSelectItem item: TemplateModel, at index: IndexPath)
}

// MARK: - UICollectionViewCell
class BackgroundContentCell: UICollectionViewCell {

    private var collectionView: UICollectionView!
    weak var delegate: BackgroundContentCellDelegate?
    var items: [TemplateModel] = [] {
        didSet {
            collectionView?.reloadData()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCollectionView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCollectionView() {

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical

        layout.minimumInteritemSpacing = 9.w    // 左右 cell 间距
        layout.minimumLineSpacing = 9.w         // 上下 cell 间距

        let screenWidth = UIScreen.main.bounds.width
        let itemWidth = (screenWidth - 24.w - 24.w - 9*2.w) / 3

        layout.sectionInset = UIEdgeInsets(top: 9.w, left: 24.w, bottom: 9.w, right: 24.w)
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(BackGroundImageCell.self, forCellWithReuseIdentifier: "BackGroundImageCell")

        contentView.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

}


// MARK: - UICollectionViewDataSource & Delegate
extension BackgroundContentCell: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BackGroundImageCell", for: indexPath) as! BackGroundImageCell
        cell.setItem(item: items[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        delegate?.backgroundContentCell(self, didSelectItem: item, at: indexPath)
    }
}

class BackGroundImageCell: UICollectionViewCell {

    private let imgView: UIImageView = {
        let img = UIImageView()
        img.contentMode = .scaleAspectFill
        img.clipsToBounds = true
        img.layer.cornerRadius = 10
        return img
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imgView)
        imgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setItem(item: TemplateModel) {
        if item.imageBg.hasPrefix("#") {
            if let img = kkCommon.imageFromHex(item.imageBg) {
                imgView.image = img
            }
        }else{
            imgView.image = BSWHBundle.image(named: item.imageBg)
        }
    }
}

