//
//  AWMenuView.swift
//  AWBabyTeacher
//
//  Created by 刘宏亮 on 2020/12/9.
//

import UIKit

@objc public protocol AWMenuViewProtocol {
    
    @objc optional func selectIndex(index: NSInteger)
}

open class AWMenuView: UIView {
    
    enum AWMenuViewType {
        case equal   // 子控件等分排列(不可滚动)
        case scroll  // 子控件自排列（可滚动）
    }
    
    enum AWMenuIndicatorType {
        case line           // 短线
        case lineSize       // 短线跟随buton宽度
        case lineStretch    // 短线 可伸缩
        case back           // 背景色
    }
    
    //MARK: 公有属性
    var menuViewType = AWMenuViewType.scroll
    var indicatorType = AWMenuIndicatorType.line
    
    var marginH: CGFloat = 0.0
    var marginV: CGFloat = 0.0
    var itemMargin: CGFloat = 15.0
    
    open var items: [UIButton]? {
        didSet {
            setItems()
        }
    }
    
    weak public var bridgeScrollView: UIScrollView? {
        didSet {
            guard let _ = bridgeScrollView else {
                assert(false, "bridgeScrollView 不能为空")
                return
            }
            setupBridgeScrollView()
        }
    }
    
    weak public var imp: AWMenuViewProtocol?
    
    var currentIndex: NSInteger = 0
    
    //MARK: 私有属性
    private var scrollview: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.showsHorizontalScrollIndicator = false
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.bounces = false
        return scroll
    }()
    private lazy var lineImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.backgroundColor = UIColor.blue.cgColor
        imageView.width = 20
        imageView.height = 2
        imageView.layer.cornerRadius = 1
        return imageView
    }()
    
    //MARK: 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        scrollview.frame = self.bounds
        if indicatorType != .back {
            lineImageView.frame.origin.y = scrollview.bounds.size.height - lineImageView.bounds.size.height;
        }
        
        if let items = items {
            layoutItems(items: items)
        }
    }
    
    //MARK: 私有
    private func setupUI() {
        backgroundColor = .clear
        addSubview(scrollview)
        scrollview.addSubview(lineImageView)
    }
    
    private func setItems() {
        guard let items = items else {
            return
        }
        for item in items {
            scrollview.addSubview(item)
            item.addTarget(self, action: #selector(action_button(button:)), for: .touchUpInside)
        }
        layoutItems(items: items)
        scrollview.bringSubviewToFront(lineImageView)
    }
    
    private func layoutItems(items: [UIButton]) {
        var maxW: CGFloat = 0.0
        if menuViewType == .scroll {
            var left = marginH
            for (index, item) in items.enumerated() {
                item.sizeToFit()
                if marginV != 0.0 {
                    item.origin = CGPoint(x: left, y: marginV)
                } else {
                    item.origin = CGPoint(x: left, y: marginV)
                    item.center.y = scrollview.frame.size.height * 0.5;
                }
                left = left + item.frame.size.width + itemMargin
                if index == items.count - 1 {
                    maxW = item.frame.origin.x + item.bounds.size.width + marginH
                }
            }
        } else {
            let itemW = (scrollview.frame.width - marginH * 2 - CGFloat(items.count - 1) * itemMargin) / CGFloat(items.count)
            let itemH = scrollview.frame.height
            var left = marginH
            for (_, item) in items.enumerated() {
                item.size = CGSize(width: itemW, height: itemH)
                item.origin = CGPoint(x: left, y: marginV)
                left = left + (item.frame.size.width + itemMargin)
            }
        }
        
        let itemTemp = items[currentIndex]
        if indicatorType != .back {
            if indicatorType == .lineSize {
                // 获取item的文字宽度
            }
            lineImageView.center.x = itemTemp.center.x
        }
        scrollview.contentSize = CGSize(width: maxW, height: 0)
    }
    
    // action_button
    @objc private func action_button(button: UIButton) {
        let index = items?.firstIndex(of: button)
        if currentIndex == index {
            return
        }
        imp?.selectIndex?(index: index ?? 0)
        currentIndex = index ?? 0
        // 移动items
        moveItems(button: button)
        // 下划线动画
        UIView.animate(withDuration: 0.15) {
            self.lineImageView.center = CGPoint(x: button.center.x, y: self.lineImageView.center.y)
        } completion: { (finish) in
            
        }

    }
    
    private func moveItems(button: UIButton) {
        if self.frame.equalTo(.zero) {
            return
        }

        let centerPageMenu = button.center
        var offsetX = centerPageMenu.x - self.scrollview.frame.midX
        let maxoffsetX = self.scrollview.contentSize.width - self.scrollview.frame.size.width
        if offsetX <= 0 || maxoffsetX <= 0 {
            offsetX = 0
        } else if offsetX > maxoffsetX {
            offsetX = maxoffsetX
        }
        if translatesAutoresizingMaskIntoConstraints == false {
            self.scrollview.setContentOffset(CGPoint(x: offsetX, y: 0), animated: true)
        }
        
    }
    
    // 监听scrollview
    private func setupBridgeScrollView() {
        bridgeScrollView?.addObserver(self, forKeyPath: "contentOffset", options: NSKeyValueObservingOptions.new, context: nil)
    }
    
    //MARK: 公有
    
    deinit {
        
        bridgeScrollView?.removeObserver(self, forKeyPath: "contentOffset", context: nil)
    }
}

extension AWMenuView {
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentOffset" {
            guard let bridge = bridgeScrollView else {
                return
            }
            prepareMoveTrackerFollowScrollView(scrollView: bridge)
        }
    }
    
    private func prepareMoveTrackerFollowScrollView(scrollView: UIScrollView) {
        guard let items = items else {
            return
        }
        if !scrollView.isDragging && !scrollView.isDecelerating {return}
        
        if scrollView.contentOffset.x < 0 || scrollView.contentOffset.x > scrollView.contentSize.width-scrollView.bounds.size.width {
            return
        }
        
        
        let currentOffSetX: CGFloat = scrollView.contentOffset.x;
        let offsetProgress = currentOffSetX / scrollView.bounds.size.width
        var progress = offsetProgress - floor(offsetProgress)
        
        var fromIndex = 0
        var toIndex = 0
        
        let beginOffsetX: CGFloat = scrollView.bounds.size.width * CGFloat(currentIndex)
        
        if currentOffSetX - beginOffsetX > 0 {
            // 向左拖拽了
            fromIndex = Int(currentOffSetX / scrollView.bounds.size.width);
            toIndex = fromIndex + 1;
            if toIndex >= items.count {
                toIndex = fromIndex
            }
        } else if currentOffSetX - beginOffsetX < 0 {
            toIndex = Int(currentOffSetX / scrollView.bounds.size.width);
            fromIndex = toIndex + 1;
            progress = 1.0 - progress
        } else {
            progress = 1.0;
            fromIndex = currentIndex;
            toIndex = fromIndex
        }
        
        if currentOffSetX == scrollView.bounds.size.width * CGFloat(fromIndex) {
            // 滚动停止了
            progress = 1.0;
            toIndex = fromIndex
        }
        if currentOffSetX == scrollView.bounds.size.width * CGFloat(toIndex) {
            if currentIndex != toIndex {
                currentIndex = toIndex
            }
            return;
        }

        let fromButton = items[fromIndex]
        let toButton = items[toIndex]
        
        // 2个按钮之间的距离
        let xDistance: CGFloat = toButton.center.x - fromButton.center.x
        // 2个按钮宽度的差值
        let _: CGFloat = toButton.frame.size.width - fromButton.frame.size.width
        
        moveItems(button: toButton)
        
        if indicatorType == .line || indicatorType == .lineSize {
            lineImageView.center.x = fromButton.center.x + xDistance * progress
        }
        
    }
}



