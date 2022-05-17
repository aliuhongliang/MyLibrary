//
//  AWTabView.swift
//  AWBabyTeacher
//
//  Created by 刘宏亮 on 2020/12/9.
//

import UIKit
import SnapKit

@objc public protocol AWTabContentViewProtocol {
    @objc optional func tabContentHoverHeight() -> CGFloat
    @objc optional func tabContentSubScrollView(index: NSInteger) -> UIScrollView
}

public class AWTabContentView: UIView {

    public enum ScrollType {
        case top   // 整体滑动
        case middle // header和content 断开 滑动
    }
    
    public var scrollType = ScrollType.middle
    
    //MARK: 公有方法
    public var items: [UIViewController]?
    
    public var headView: UIView? {
        didSet {
            let view = oldValue
            if view?.superview == headerScrollview {
                view?.removeFromSuperview()
            }
            updateHeaderFrame()
        }
    }
    
    weak public var imp: AWTabContentViewProtocol?
    weak public var viewController: UIViewController?
    
    //MARK: 私有属性
    private var hoverHeight: CGFloat = 0 // 悬停高度
    private var initialed: Bool = false  // 是否初始化完成
    private var keepHover: Bool = false  // 是否需要悬停
    private var keepVscrollZero: Bool = false // 主视图设置偏移量为0(保证能从中间断开)
    
    private var scrollViews = Array<UIScrollView>()
    
    private lazy var headerScrollview: UIScrollView = {
        let scroll = UIScrollView()
        scroll.backgroundColor = .clear
        scroll.showsVerticalScrollIndicator = false
        scroll.showsHorizontalScrollIndicator = false
        return scroll
    }()
    
    private lazy var vScrollview: AWTabScrollViewtionView = {
        let scroll = AWTabScrollViewtionView()
        scroll.showsVerticalScrollIndicator = false
        scroll.showsHorizontalScrollIndicator = false
        scroll.backgroundColor = .clear
        scroll.delegate = self
        scroll.contentInsetAdjustmentBehavior = .never
        return scroll
    }()
    
    private lazy var flow: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        return layout
    }()
    
    open lazy var collectionview: UICollectionView = {
        let collect = UICollectionView(frame: .zero, collectionViewLayout: flow)
        collect.backgroundColor = .clear
        collect.showsVerticalScrollIndicator = false
        collect.showsHorizontalScrollIndicator = false
        collect.delegate = self
        collect.dataSource = self
        collect.register(AWCollectCell.self, forCellWithReuseIdentifier: "AWCollectCell_aw")
        collect.isPagingEnabled = true
        collect.bounces = false
        collect.contentInsetAdjustmentBehavior = .never
        return collect
    }()
    
    //MARK: 私有方法
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: 初始化
    private func setupUI() {
        
        addSubview(vScrollview)
        vScrollview.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
            make.width.equalToSuperview()
        }
        vScrollview.addSubview(headerScrollview)
        headerScrollview.snp.makeConstraints { (make) in
            make.top.equalTo(vScrollview)
            make.width.equalToSuperview()
            make.height.equalTo(0)
        }
        vScrollview.addSubview(collectionview)
        collectionview.snp.makeConstraints { (make) in
            make.width.equalTo(vScrollview)
            make.height.equalTo(vScrollview).offset(-hoverHeight+1)
            make.top.equalTo(headerScrollview.snp.bottom)
            make.bottom.equalTo(vScrollview)
        }
    }
    
    private func setupHeadView() {
        if let head = headView {
            head.layoutIfNeeded()
            let w: CGFloat = head.frame.size.width
            let h: CGFloat = head.frame.size.height
            headerScrollview.addSubview(head)
            headerScrollview.snp.remakeConstraints { (make) in
                make.top.equalTo(vScrollview)
                make.width.equalTo(w)
                make.height.equalTo(h)
            }
        }
    }
    
    //MARK: 布置左右滚动cell的大小
    public override func layoutSubviews() {
        super.layoutSubviews()
        print(collectionview.contentOffset.x)
        print(flow.itemSize)
        flow.itemSize = CGSize(width: width, height: height - hoverHeight)
        print(collectionview.contentOffset.x)
        print(flow.itemSize)
    }
    
    // MARK: 更新headerview
    private func updateHeaderFrame() {
        if !initialed {
            return
        }
        guard let _ = headView else {
            headerScrollview.snp.remakeConstraints { (make) in
                make.top.equalTo(vScrollview)
                make.width.equalTo(0)
                make.height.equalTo(0)
            }
            return
        }
        setupHeadView()
        // 重置所有控件的位置
        makeZero()
        vScrollview.contentOffset = .zero
    }
    
    // MARK: 外面滚动视图的上下滑动监听
    private func addNotiWithScrollPath(items: Array<UIViewController>) {
        // 移除监听
        removeNotiWithScrollPath()
        for (index, _) in items.enumerated() {
            let scrollview = imp?.tabContentSubScrollView?(index: index)
            if let scroll = scrollview {
                scrollViews.append(scroll)
            }
            if scrollview != nil {
                scrollview?.addObserver(self, forKeyPath: "contentOffset", options: [.new,.old], context: nil)
            }
        }
    }
    
    private func removeNotiWithScrollPath() {
        
        if scrollViews.count > 0 {
            // 移除监听
            for view in scrollViews {
                view.removeObserver(self, forKeyPath: "contentOffset", context: nil)
            }
            scrollViews.removeAll()
        }
    }
    
    deinit {
        removeNotiWithScrollPath()
    }
    
    //MARK: 公有方法
    public func reload() {
        if initialed {
            initialed = false
            // 重置所有控件的位置
            makeZero()
            vScrollview.contentOffset = .zero
            
        }
        guard let items = items else {
            return
        }
        hoverHeight = imp?.tabContentHoverHeight?() ?? 0
        collectionview.snp.remakeConstraints { (make) in
            make.width.equalTo(vScrollview)
            make.height.equalTo(vScrollview).offset(-hoverHeight+1)
            make.top.equalTo(headerScrollview.snp.bottom)
            make.bottom.equalTo(vScrollview)
        }
        initialed = true
        //监听左右scrollview
        addNotiWithScrollPath(items: items)
        setupHeadView()
        collectionview.reloadData()
    }
    
    public func scrollIndex(index: NSInteger, animate: Bool) {
        let indexp = IndexPath(item: index, section: 0)
        collectionview.scrollToItem(at: indexp, at: UICollectionView.ScrollPosition.left, animated: animate)
    }
}

extension AWTabContentView: UIScrollViewDelegate {
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentOffset" {
            let newk = change?[NSKeyValueChangeKey.newKey] as? CGPoint
            let oldk = change?[NSKeyValueChangeKey.oldKey] as? CGPoint
            if newk?.y == oldk?.y {
                return
            }
            setupOutsideVcScroll(object: object)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    private func makeZero() {
        guard let items = items else {
            return
        }
        if hoverHeight == headView?.frame.size.height || headView == nil {
            return
        }
        for (index, _) in items.enumerated() {
            let scrollview = imp?.tabContentSubScrollView?(index: index)
            if scrollview != nil {
                scrollview?.contentOffset = .zero
            }
        }
    }
    
    private func setupOutsideVcScroll(object: Any?) {
        // 判断滚动方向
        let subScroll = object as! UIScrollView
        let subScrollOff = subScroll.contentOffset.y
        let vOff = vScrollview.contentOffset.y
        
        let headH = headerScrollview.bounds.size.height
        let maxOff = headH - hoverHeight
        
        if subScrollOff > 0 {
            if vOff < maxOff {
                subScroll.contentOffset = .zero
            }
            keepHover = (vOff >= maxOff)
        } else {
            if scrollType == ScrollType.top {
                subScroll.contentOffset = .zero
                keepHover = false
                makeZero()
            } else {
                keepHover = false
                
                if subScrollOff < 0 && vOff <= 0 {
                    keepVscrollZero = true
                } else {
                    keepVscrollZero = false
                    subScroll.contentOffset = .zero
                    makeZero()
                }
            }
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == collectionview {
            // 滚动的左右collectionview视图
            if vScrollview.contentOffset.y < 0 {
                scrollView.isScrollEnabled = false
            } else {
                scrollView.isScrollEnabled = true
            }
        } else {
            // 滚动的主scroll视图
            let headH = headerScrollview.bounds.size.height
            let maxOff = headH - hoverHeight
            if scrollType == ScrollType.middle {
                if keepVscrollZero || vScrollview.contentOffset.y <= 0 {
                    scrollView.contentOffset = .zero
                }
            }
            if vScrollview.contentOffset.y >= maxOff {
                vScrollview.contentOffset = CGPoint(x: 0, y: maxOff)
            }
            
            if keepHover {
                vScrollview.contentOffset = CGPoint(x: 0, y: maxOff)
            }
            if vScrollview.contentOffset.y >= 0 {
                collectionview.isScrollEnabled = true
            }
            
            if scrollView.contentOffset.y <= -5 {
                scrollView.decelerationRate = UIScrollView.DecelerationRate(rawValue: 0.991)
            }
        }
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        if scrollView == collectionview {
            // 滚动的左右collectionview视图
            vScrollview.isGestureRecognizer = false
        } else {
            // 滚动的主scroll视图
            // 是否保持悬停
            let headH = headerScrollview.bounds.size.height
            let vOff = vScrollview.contentOffset.y
            let maxOff = headH - hoverHeight
            if vOff >= maxOff {
                keepHover = true
            }
        }
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView == collectionview && !decelerate {
            vScrollview.isGestureRecognizer = true
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == collectionview {
            vScrollview.isGestureRecognizer = true
        }
    }
}

extension AWTabContentView: UICollectionViewDelegate, UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items?.count ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AWCollectCell_aw", for: indexPath) as! AWCollectCell
        let temp = items?[indexPath.item]
        cell.contentView.subviews.forEach { view in
            view.removeFromSuperview()
        }
        cell.contentView.addSubview(temp!.view)
        temp?.view.frame = cell.contentView.bounds
        if let tempvc = temp, temp?.parent == nil {
            viewController?.addChild(tempvc)
        }
        return cell
    }
}

 private class AWCollectCell: UICollectionViewCell {
    
    var vc: UIViewController? {
        didSet {
            guard let vc = vc else {
                return
            }
            
            contentView.addSubview(vc.view)
            vc.view.snp.makeConstraints { (make) in
                make.edges.equalTo(contentView)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
    }
}

class AWTabScrollViewtionView: UIScrollView,UIGestureRecognizerDelegate {
    var isGestureRecognizer = true
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        isGestureRecognizer
    }
}
