//
//  StatusWaitingProgress.swift
//  WaitingProgress
//
//  Created by Hung Cao on 4/8/20.
//  Copyright © 2020 Hung Cao. All rights reserved.
//

import UIKit

enum StatusType {
    case success
    case fail
}
class LoaderProgress: HCWaitingProgressProtocol {
    var emptyView: UIView = UIView()
    @objc var backgroundBlurView: UIVisualEffectView
    @objc var backgroundSimpleView: UIView
    @objc var backgroundFullView: UIView
    
    @objc var outerCircle: CAShapeLayer = CAShapeLayer()
    @objc var middleCircle: CAShapeLayer = CAShapeLayer()
    @objc var innerCircle: CAShapeLayer = CAShapeLayer()
    
    @objc weak var targetView: UIView?
    
    var loaderType: LoaderType
    var backgroundView: UIView {
        switch WaitingProgressConfig.backgroundViewStyle {
        case .blur:
            return backgroundBlurView
        case .simple:
            return backgroundSimpleView
        default:
            return backgroundFullView
        }
    }
    
    
    init() {
        // blurred background view
        let blur = UIBlurEffect(style: WaitingProgressConfig.blurStyle)
        let effectView = UIVisualEffectView(effect: blur)
        effectView.clipsToBounds = true
        backgroundBlurView = effectView
        
        // a simple background view
        backgroundSimpleView = UIView()
        backgroundSimpleView.backgroundColor = UIColor(cgColor: WaitingProgressConfig.backgroundViewColor)
        
        // full view
        backgroundFullView = UIView()
        backgroundFullView.backgroundColor = UIColor(cgColor: WaitingProgressConfig.backgroundViewColor)
        
        // Register a notification
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged(notification:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        // must override type of loader
        loaderType = .infinite
    }
    
    @objc func orientationChanged(notification: Notification) {
        DispatchQueue.main.async {
            if let loader = current_loader {
                if let targetView = loader.targetView {
                    checkCreatedFrameForBackgroundView(backgroundView: loader.backgroundView, onView: targetView)
                } else {
                    checkCreatedFrameForBackgroundView(backgroundView: loader.backgroundView, onView: nil)
                }
            }
        }
    }
    
    func showOnView(view: UIView?, completionBlock: (() -> Void)?) {
        if !checkCreatedFrameForBackgroundView(backgroundView: backgroundView, onView: view) {
            return
        }
        
        self.targetView = view
        
        createCircles(outerCircle: outerCircle, middleCircle: middleCircle, innerCircle: innerCircle, onView: ((backgroundView as? UIVisualEffectView)?.contentView) ?? backgroundView, loaderType: self.loaderType)
        
        // animate
        animateCircles(outerCircle: outerCircle, middleCircle: middleCircle, innerCircle: innerCircle)
        
        // present a loader
        presentLoader(loader: self, onView: view, completionBlock: completionBlock)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
}
final class InfiniteLoader: LoaderProgress {
    
    override init() {
        super.init()
        self.loaderType = .infinite
    }
}

final class ProgressLoader: LoaderProgress {
    var multiplier: CGFloat = 1.0
    var lastMultiplierValue: CGFloat = 1.0
    var progressValue: CGFloat = 0.0
    var progress: Progress?
    var failed = false
    
    static weak var weakSelf: ProgressLoader?
    
    override init() {
        super.init()
        self.loaderType = .progress
        ProgressLoader.weakSelf = self
    }
    
    
    func showWithValue(value: CGFloat, onView view: UIView?, progress: Progress?, completionBlock: (() -> Void)?) {
        if !checkCreatedFrameForBackgroundView(backgroundView: backgroundView, onView: view) {
            return
        }
        if let progress = progress {
            self.progress = progress
        }
        
        current_completionBlock = completionBlock
        targetView = view
        
        createCircles(outerCircle: outerCircle, middleCircle: middleCircle, innerCircle: innerCircle, onView: ((backgroundView as? UIVisualEffectView)?.contentView) ?? backgroundView, loaderType: loaderType)
        
        animateCircles(outerCircle: outerCircle, middleCircle: middleCircle, innerCircle: innerCircle)
        presentLoader(loader: self, onView: view, completionBlock: nil)
        
        launchTimer()
    }
    
    func launchTimer() {
        DispatchQueue.main.async {
            guard let strongSelf = ProgressLoader.weakSelf else { return }
            
            strongSelf.incrementCircleRadius()
            strongSelf.launchTimer()
        }
    }
    
    func progressSource() -> CGFloat {
        if let progress = self.progress {
            return CGFloat(progress.fractionCompleted * 100.0)
        } else {
            return self.progressValue
        }
    }
    func didIncrementMultiplier() -> Bool {
        if failed {
            multiplier -= 1.5
            return true
        }
        let progress: CGFloat = progressSource()
        if lastMultiplierValue == progress {
            return false
        }
        
        if progress / multiplier > 2 {
            if multiplier < progress {
                multiplier += 0.75
            }
        } else {
            if multiplier < progress {
                multiplier += 0.25
            }
        }
        
        self.lastMultiplierValue = multiplier
        return true
    }
    func incrementCircleRadius() {
        if !didIncrementMultiplier() {
            
            return
        }
        
        drawCirclePath()
        
        if failed && multiplier <= 0.0 {
            ProgressLoader.weakSelf = nil
            multiplier = 0.01
            drawCirclePath()
            failedLoading()
        } else {
            ProgressLoader.weakSelf = nil
            completed()
        }
    }
    func drawCirclePath() {
        let viewBounds = backgroundView.bounds
        let center = CGPoint(x: viewBounds.midX, y: viewBounds.midY)
        let endAngle = CGFloat.pi / 180 * 3.6 * multiplier
        let outerPath = UIBezierPath(arcCenter: center, radius: CIRCLE_RADIUS_OUTER, startAngle: 0, endAngle: endAngle, clockwise: true)
        let middlePath = UIBezierPath(arcCenter: center, radius: CIRCLE_RADIUS_MIDDLE, startAngle: 0, endAngle: endAngle, clockwise: true)
        let innerPath = UIBezierPath(arcCenter: center, radius: CIRCLE_RADIUS_INNER, startAngle: 0, endAngle: endAngle, clockwise: true)
        
        self.outerCircle.path = outerPath.cgPath
        self.middleCircle.path = middlePath.cgPath
        self.innerCircle.path = innerPath.cgPath
    }
    
    func failedLoading() {
        StatusWaitingProgress.show(type: .fail)
        
        let dismissDelay = 0.5 + max(WaitingProgressConfig.failCircleAnimationDrawDuration, WaitingProgressConfig.failCrossAnimationDrawDuration)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + dismissDelay) {
            hideLoader(loader: current_loader, withCompletionBlock: current_completionBlock)
        }
    }
    
    func completed() {
        let transform = CATransform3DMakeScale(0.01, 0.01, 1)
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.5)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.7, -0.8, 0.68, 0.95))
        self.innerCircle.transform = transform
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.7)
        self.middleCircle.transform = transform
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.9)
        self.outerCircle.transform = transform
        CATransaction.commit()
        CATransaction.commit()
        CATransaction.commit()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            if WaitingProgressConfig.showSuccessCheckmark {
                StatusWaitingProgress.show(type: .success)
                
                let dismissDelay = 0.5 + max(WaitingProgressConfig.successCircleAnimationDrawDuration, WaitingProgressConfig.checkmarkAnimationDrawAnimation)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + dismissDelay) {
                    hideLoader(loader: current_loader, withCompletionBlock: current_completionBlock)
                }
            } else {
                hideLoader(loader: current_loader, withCompletionBlock: current_completionBlock)
            }
        }
    }
}

final class StatusWaitingProgress: LoaderProgress {
    static func show(type: StatusType) {
        if let loader = current_loader {
            stopCircleAnimation(loader: loader) {
                drawStatus(type: type, loader: loader)
            }
        } else {
            let loader = StatusWaitingProgress()
            presentLoader(loader: loader, onView: nil) {
                drawStatus(type: type, loader: loader)
            }
        }
    }
    
    static func drawSuccess(backgroundView: UIView) {
        let backgroundViewBounds = backgroundView.bounds
        let backgroundLayer = backgroundView.layer
        
        let checkmarkSideLength = STATUS_PATH_SIDE_LENGTH
        let checkmarkPathCenter = CGPoint(x: (backgroundViewBounds.width - checkmarkSideLength) / 2, y: (backgroundViewBounds.height - checkmarkSideLength) / 2)
        
        let checkmarkPath = UIBezierPath()
        checkmarkPath.move(to: CGPoint(x: checkmarkSideLength * 0.28, y: checkmarkSideLength * 0.53))
        checkmarkPath.addLine(to: CGPoint(x: checkmarkSideLength * 0.42, y: checkmarkSideLength * 0.66))
        checkmarkPath.addLine(to: CGPoint(x: checkmarkSideLength * 0.72, y: checkmarkSideLength * 0.36))
        checkmarkPath.apply(CGAffineTransform(translationX: checkmarkPathCenter.x, y: checkmarkPathCenter.y))
        checkmarkPath.lineCapStyle = .square
        
        let checkmark = CAShapeLayer()
        checkmark.path = checkmarkPath.cgPath
        checkmark.fillColor = nil
        checkmark.strokeColor = WaitingProgressConfig.checkmarkColor
        checkmark.lineWidth = WaitingProgressConfig.checkmarkLineWidth
        backgroundLayer.addSublayer(checkmark)
        
        let successCircleCenter = CGPoint(x: backgroundViewBounds.midX, y: backgroundViewBounds.midY)
        let successCircle = CAShapeLayer()
        successCircle.path = UIBezierPath(arcCenter: successCircleCenter, radius: CIRCLE_RADIUS_OUTER, startAngle: -CGFloat.pi / 2, endAngle: CGFloat.pi / 180 * 270, clockwise: true).cgPath
        successCircle.fillColor = nil
        successCircle.strokeColor = WaitingProgressConfig.successCircleColor
        successCircle.lineWidth = WaitingProgressConfig.successCircleLineWidth
        backgroundLayer.addSublayer(successCircle)
        
        let animationCheckmark = CABasicAnimation(keyPath: "strokeEnd")
        animationCheckmark.isRemovedOnCompletion = true
        animationCheckmark.fromValue = 0
        animationCheckmark.toValue = 1
        animationCheckmark.fillMode = .both
        animationCheckmark.duration = WaitingProgressConfig.checkmarkAnimationDrawAnimation
        animationCheckmark.timingFunction = CAMediaTimingFunction(name: .easeOut)
        checkmark.add(animationCheckmark, forKey: nil)
        
        let animationCircle = CABasicAnimation(keyPath: "strokeEnd")
        animationCircle.isRemovedOnCompletion = true
        animationCircle.fromValue = 0
        animationCircle.toValue = 1
        animationCircle.fillMode = .both
        animationCircle.duration = WaitingProgressConfig.successCircleAnimationDrawDuration
        animationCircle.timingFunction = CAMediaTimingFunction(name: .easeOut)
        successCircle.add(animationCircle, forKey: nil)
    }
    static func drawFail(backgroundView: UIView) {
        let backgroundViewBounds = backgroundView.bounds
        let backgroundViewLayer = backgroundView.layer
        
        let crossSideLength = STATUS_PATH_SIDE_LENGTH
        let crossPathCenter = CGPoint(x: (backgroundViewBounds.width - crossSideLength) / 2, y: (backgroundViewBounds.height - crossSideLength) / 2)
        
        let crossPath = UIBezierPath()
        crossPath.move(to: CGPoint(x: crossSideLength * 0.67, y: crossSideLength * 0.32))
        crossPath.addLine(to: CGPoint(x: crossSideLength * 0.32, y: crossSideLength * 0.67))
        crossPath.move(to: CGPoint(x: crossSideLength * 0.32, y: crossSideLength * 0.32))
        crossPath.addLine(to: CGPoint(x: crossSideLength * 0.67, y: crossSideLength * 0.67))
        crossPath.apply(CGAffineTransform(translationX: crossPathCenter.x, y: crossPathCenter.y))
        crossPath.lineCapStyle = .square
        
        let cross = CAShapeLayer()
        cross.path = crossPath.cgPath
        cross.fillColor = nil
        cross.strokeColor = WaitingProgressConfig.failCrossColor
        cross.lineWidth = WaitingProgressConfig.failCrossLineWidth
        cross.frame = backgroundViewBounds
        backgroundViewLayer.addSublayer(cross)
        
        let failCircleArcCenter = CGPoint(x: backgroundViewBounds.midX, y: backgroundViewBounds.midY)
        let failCircle = CAShapeLayer()
        failCircle.path = UIBezierPath(arcCenter: failCircleArcCenter, radius: CIRCLE_RADIUS_OUTER, startAngle: -CGFloat.pi / 2, endAngle: CGFloat.pi / 180 * 270, clockwise: true).cgPath
        failCircle.fillColor = nil
        failCircle.strokeColor = WaitingProgressConfig.failCircleColor
        failCircle.lineWidth = WaitingProgressConfig.failCircleLineWidth
        backgroundViewLayer.addSublayer(failCircle)
        
        let animationCross = CABasicAnimation(keyPath: "strokeEnd")
        animationCross.isRemovedOnCompletion = false
        animationCross.fromValue = 0
        animationCross.toValue = 1
        animationCross.duration = WaitingProgressConfig.failCrossAnimationDrawDuration
        animationCross.fillMode = .both
        animationCross.timingFunction = CAMediaTimingFunction(name: .easeIn)
        cross.add(animationCross, forKey: nil)
        
        let animationCircle = CABasicAnimation(keyPath: "opacity")
        animationCircle.isRemovedOnCompletion = true
        animationCircle.fromValue = 0
        animationCircle.toValue = 1
        animationCircle.fillMode = .both
        animationCircle.duration = WaitingProgressConfig.failCircleAnimationDrawDuration
        animationCircle.timingFunction = CAMediaTimingFunction(name: .easeOut)
        failCircle.add(animationCircle, forKey: nil)
    }
    static func drawStatus(type: StatusType, loader: HCWaitingProgressProtocol) {
        current_status = loader
        
        switch type {
        case .success:
            StatusWaitingProgress.drawSuccess(backgroundView: loader.backgroundView)
        default:
            StatusWaitingProgress.drawFail(backgroundView: loader.backgroundView)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
            hideLoader(loader: loader, withCompletionBlock: nil)
        }
    }
}
