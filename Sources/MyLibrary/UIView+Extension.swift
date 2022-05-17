//
//  UIView+Extension.swift
//  AdminSoftware
//
//  Created by rabbit super on 2019/12/16.
//  Copyright © 2019 rabbit super. All rights reserved.
//

import UIKit

extension UIView {
    //:x
    var x: CGFloat {
        get {
           frame.origin.x
        }
        set {
            var rect = frame
            rect.origin.x = newValue
            frame = rect
        }
    }
    //:y
    var y: CGFloat {
        get {
            frame.origin.y
        }
        set {
            var rect = frame
            rect.origin.y = newValue
            frame = rect
        }
    }
    // .maxX
    public var maxX: CGFloat {
        get {
            return self.frame.maxX
        }
    }
    
    // .maxY
    public var maxY: CGFloat {
        get {
            return self.frame.maxY
        }
    }
    
    // .centerX
    public var centerX: CGFloat {
        get {
            return self.center.x
        }
        set {
            self.center = CGPoint(x: newValue, y: self.center.y)
        }
    }
    
    // .centerY
    public var centerY: CGFloat {
        get {
            return self.center.y
        }
        set {
            self.center = CGPoint(x: self.center.x, y: newValue)
        }
    }
    
    // .width
    public var width: CGFloat {
        get {
            return self.frame.size.width
        }
        set {
            var rect = self.frame
            rect.size.width = newValue
            self.frame = rect
        }
    }
    
    // .height
    public var height: CGFloat {
        get {
            return self.frame.size.height
        }
        set {
            var rect = self.frame
            rect.size.height = newValue
            self.frame = rect
        }
    }
    
    // .top
    public var top: CGFloat {
        get {
            return self.frame.origin.y
        }
        set {
            var rect = self.frame
            rect.origin.y = newValue
            self.frame = rect
        }
    }
    
    // .left
    public var left: CGFloat {
        get {
            return self.frame.origin.x
        }
        set {
            var rect = self.frame
            rect.origin.x = newValue
            self.frame = rect
        }
    }
    
    // .bottom
    public var bottom: CGFloat {
        get {
            return self.frame.size.height + frame.origin.y
        }
        set {
            var rect = self.frame
            rect.origin.y = newValue - frame.size.height
            self.frame = rect
        }
    }
    
    // .right
    public var right: CGFloat {
        get {
            return self.frame.size.width + frame.origin.x
        }
        set {
            var rect = self.frame
            rect.origin.x = newValue - frame.size.width
            self.frame = rect
        }
    }
    
    // .size
    public var size: CGSize {
        get {
            return frame.size
        }
        set {
            var rect = self.frame
            rect.size = newValue
            self.frame = rect
        }
    }
    
    // .origin
    public var origin: CGPoint {
        get {
            return self.frame.origin
        }
        set {
            var rect = self.frame
            rect.origin = newValue
            self.frame = rect
        }
    }
    
    // .radius 圆角
    public var radius: CGFloat {
        get {
           layer.cornerRadius
        }
        set {
            cornerRadius(radius: newValue, corner: .allCorners)
        }
    }
    // .radius 圆角
    func cornerRadius(radius:CGFloat,corner:UIRectCorner) {
        let maskPath = UIBezierPath.init(roundedRect:bounds, byRoundingCorners: corner, cornerRadii: CGSize.init(width: radius, height: radius))
        let maskLayer = CAShapeLayer.init()
        maskLayer.frame = self.bounds
        maskLayer.path = maskPath.cgPath
        layer.mask = maskLayer
    }
    // .边 圆角
    func border(borderW:CGFloat,borderColor:UIColor) {
        layer.borderWidth = borderW
        layer.borderColor = borderColor.cgColor
    }
    // .radius 圆角
    func cornerRadius(radius:CGFloat,borderW:CGFloat,borderColor:UIColor) {
        layer.cornerRadius = radius
        layer.borderWidth = borderW
        layer.borderColor = borderColor.cgColor
        layer.masksToBounds = true
    }
    
    //添加阴影
    func shadow(shadowColor:UIColor,opacity:Float,radius:CGFloat,offset:CGSize){
        
        layer.masksToBounds = false
        layer.shadowColor = shadowColor.cgColor
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
        layer.shadowOffset = offset
    }
    
    //添加渐变色
    func gradient(colors:Array<UIColor>,startPoint:CGPoint,endPoint:CGPoint,locations:Array<NSNumber>){
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = colors.map{$0.cgColor}
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.locations = locations
        layer.addSublayer(gradientLayer)
    }
    
    func animation_scale() {
        let animation = CAKeyframeAnimation.init()
        animation.keyPath = "transform.scale"
        animation.values = [1.0, 1.4, 0.9, 1.15, 0.95, 1.02, 1.0]
        animation.duration = 0.5
        animation.calculationMode = CAAnimationCalculationMode.cubic
        layer.add(animation, forKey: nil)
    }
    
//    func <#name#>(<#parameters#>) -> <#return type#> {
//        <#function body#>
//    }
}
