//
//  WaitingProgressHelper.swift
//  WaitingProgress
//
//  Created by Hung Cao on 4/8/20.
//  Copyright © 2020 Hung Cao. All rights reserved.
//

import UIKit

enum LoaderType {
    case infinite
    case progress
}

public enum BackgroundStyle {
    case blur
    case simple
    case full
}

func target_window() -> UIWindow? {
    var targetWindow: UIWindow?
    let windows = UIApplication.shared.windows
    
    for window in windows {
        guard window.screen == UIScreen.main else {
            continue
        }
        if !window.isHidden && window.alpha == 0 { continue }
        if window.windowLevel  != UIWindow.Level.normal { continue }
        
        targetWindow = window
        break
    }
    return targetWindow
}

@discardableResult func checkCreatedFrameForBackgroundView(backgroundView: UIView, onView view: UIView?) -> Bool {
    let center: CGPoint
    let bounds: CGRect
    
    if view != nil {
        bounds = view!.bounds
        center = view!.center
    } else {
        guard let window = target_window() else { return false }
        bounds = window.screen.bounds
        center = window.center
    }
    
    
    let sideLengs = BACKGROUND_VIEW_SIDE_LENGTH
    
    switch WaitingProgressConfig.backgroundViewStyle {
    case .blur, .simple:
        backgroundView.frame = CGRect(x: center.x - sideLengs / 2, y: center.y - sideLengs / 2, width: sideLengs, height: sideLengs)
        backgroundView.layer.cornerRadius = WaitingProgressConfig.backgroundViewCornerRadius
    default:
        backgroundView.frame = CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: bounds.height)
        backgroundView.layer.cornerRadius = 0
    }
    
    backgroundView.backgroundColor = UIColor(cgColor: WaitingProgressConfig.backgroundViewColor)
    return true
}

func animateCircles(outerCircle: CAShapeLayer, middleCircle: CAShapeLayer, innerCircle: CAShapeLayer) {
    DispatchQueue.main.async {
        let outerAnimation = CABasicAnimation(keyPath: "transform.rotation")
        outerAnimation.toValue = CIRCLE_ROTATION_TO_VALUE
        outerAnimation.duration = WaitingProgressConfig.circleRotationDurationOuter
        outerAnimation.repeatCount = CIRCLE_ROTATION_REPEAT_COUNT
        outerAnimation.isRemovedOnCompletion = false
        outerCircle.add(outerAnimation, forKey: "outerCircleRotation")
        
        let middleAnimation = outerAnimation.copy() as! CABasicAnimation
        middleAnimation.duration = WaitingProgressConfig.circleRotationDurationMiddle
        middleCircle.add(middleAnimation, forKey: "middleCircleRotation")
        
        let innerAnimation = outerAnimation.copy() as! CABasicAnimation
        innerAnimation.duration = WaitingProgressConfig.circleRotationDurationInner
        innerCircle.add(innerAnimation, forKey: "innerCircleRotation")
    }
}

func configureLayer(layer: CAShapeLayer, forView view: UIView, withPath path: CGPath, withBounds bounds: CGRect, withColor color: CGColor) {
    layer.path = path
    layer.frame = bounds
    layer.lineWidth = CIRCLE_LINE_WIDTH
    layer.strokeColor = color
    layer.fillColor = UIColor.clear.cgColor
    layer.isOpaque = true
    
    view.layer.addSublayer(layer)
}

func cleanupLoader(loader: HCWaitingProgressProtocol) {
    loader.emptyView.removeFromSuperview()
    
    current_loader = nil
    completionBlock = nil
}


func hideLoader(loader: HCWaitingProgressProtocol?, withCompletionBlock block: (() -> Void)?) {
    guard let loader = loader else { return }
    
    DispatchQueue.main.async {
        let currentLayer = loader.emptyView.layer.presentation()
        
        let alpha = Double(currentLayer?.opacity ?? 0)
        let fixedTime = alpha * WaitingProgressConfig.backgroundViewDismissAnimationDuration
        
        
        CATransaction.begin()
        CATransaction.setCompletionBlock(block)
        let alphaAnimation = CABasicAnimation(keyPath: "opacity")
        alphaAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        alphaAnimation.fromValue = alpha
        alphaAnimation.toValue = 0
        alphaAnimation.duration = fixedTime
        alphaAnimation.isRemovedOnCompletion = true
        
        CATransaction.commit()
        
        
        loader.emptyView.layer.removeAnimation(forKey: "alpha")
        loader.emptyView.alpha = 0
        loader.emptyView.layer.add(alphaAnimation, forKey: "alpha")
        
        let scaleAnimation = CABasicAnimation(keyPath: "transform")
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        scaleAnimation.fromValue = CGAffineTransform(scaleX: 1, y: 1)
        scaleAnimation.toValue = CGAffineTransform(scaleX: WaitingProgressConfig.backgroundViewDismissTransfromScale, y: WaitingProgressConfig.backgroundViewDismissTransfromScale)
        scaleAnimation.duration = fixedTime
        scaleAnimation.isRemovedOnCompletion = true
        
        loader.backgroundView.layer.removeAnimation(forKey: "transform")
        loader.backgroundView.layer.add(scaleAnimation, forKey: "transform")
        
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + WaitingProgressConfig.backgroundViewDismissAnimationDuration) {
        cleanupLoader(loader: loader)
    }
    
}


func presentLoader(loader: HCWaitingProgressProtocol, onView view: UIView?, completionBlock block: (() -> Void)?) {
    current_loader = loader

    let emptyView = loader.emptyView
    emptyView.backgroundColor = .clear
    emptyView.frame = loader.backgroundView.bounds
    emptyView.addSubview(loader.backgroundView)
    
    DispatchQueue.main.async {
        if let targetView = view {
            targetView.addSubview(emptyView)
        } else {
            target_window()!.addSubview(emptyView)
        }
        
        CATransaction.begin()
        CATransaction.setCompletionBlock(completionBlock)
        
        let alphaAnimation = CABasicAnimation(keyPath: "opacity")
        alphaAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        alphaAnimation.fromValue = 0
        alphaAnimation.toValue = 1
        alphaAnimation.duration = WaitingProgressConfig.backgroundViewPresentAnimationDuration
        
        emptyView.layer.removeAnimation(forKey: "alpha")
        emptyView.layer.add(alphaAnimation, forKey: "alpha")
        
        CATransaction.commit()
    }
}


func stopCircleAnimation(loader: HCWaitingProgressProtocol, completionBlock: @escaping () -> Void) {
    CATransaction.begin()
    CATransaction.setAnimationDuration(0.25)
    CATransaction.setCompletionBlock(completionBlock)
    loader.outerCircle?.opacity = 0.0
    loader.middleCircle?.opacity = 0.0
    loader.innerCircle?.opacity = 0.0
    CATransaction.commit()
}


func createCircles(outerCircle: CAShapeLayer, middleCircle: CAShapeLayer, innerCircle: CAShapeLayer, onView view: UIView, loaderType: LoaderType) {
    let circleRadiusOuter = CIRCLE_RADIUS_OUTER
    let circleRadiusMiddle = CIRCLE_RADIUS_MIDDLE
    let circleRadiusInner = CIRCLE_RADIUS_INNER
    let viewBounds = view.bounds
    let arcCenter = CGPoint(x: viewBounds.midX, y: viewBounds.midY)
    var path: UIBezierPath
    
    switch loaderType {
    case .infinite:
        path = UIBezierPath(arcCenter: arcCenter, radius: circleRadiusOuter, startAngle: CIRCLE_START_ANGLE, endAngle: CIRCLE_END_ANGLE, clockwise: true)
        
    default:
        path = UIBezierPath(arcCenter: arcCenter, radius: circleRadiusOuter, startAngle: 0, endAngle: CGFloat.pi / 180 * 3.6, clockwise: true)
    }
    // Draw line for outer
    configureLayer(layer: outerCircle, forView: view, withPath: path.cgPath, withBounds: viewBounds, withColor: WaitingProgressConfig.circleColorOutre)
    
    
    switch loaderType {
    case .infinite:
        path = UIBezierPath(arcCenter: arcCenter, radius: circleRadiusMiddle, startAngle: CIRCLE_START_ANGLE, endAngle: CIRCLE_END_ANGLE, clockwise: true)
        
    default:
        path = UIBezierPath(arcCenter: arcCenter, radius: circleRadiusMiddle, startAngle: 0, endAngle: CGFloat.pi / 180 * 3.6, clockwise: true)
    }
    // Draw line for middle
    configureLayer(layer: middleCircle, forView: view, withPath: path.cgPath, withBounds: viewBounds, withColor: WaitingProgressConfig.circleColorMiddle)
    
    
    switch loaderType {
    case .infinite:
        path = UIBezierPath(arcCenter: arcCenter, radius: circleRadiusInner, startAngle: CIRCLE_START_ANGLE, endAngle: CIRCLE_END_ANGLE, clockwise: true)
        
    default:
        path = UIBezierPath(arcCenter: arcCenter, radius: circleRadiusInner, startAngle: 0, endAngle: CGFloat.pi / 180 * 3.6, clockwise: true)
    }
    // Draw line for outer
    configureLayer(layer: innerCircle, forView: view, withPath: path.cgPath, withBounds: viewBounds, withColor: WaitingProgressConfig.circleColorInner)
}
