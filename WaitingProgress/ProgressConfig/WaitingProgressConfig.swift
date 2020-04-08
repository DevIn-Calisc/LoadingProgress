//
//  WaitingProgressConfig.swift
//  WaitingProgress
//
//  Created by Hung Cao on 4/8/20.
//  Copyright © 2020 Hung Cao. All rights reserved.
//

import UIKit

@objcMembers final public class WaitingProgressConfig: NSObject {
    public static var showSuccessCheckmark = true
    
    public static var backgroundViewDismissTransfromScale: CGFloat = 0.9
    public static var backgroundViewColor: CGColor = UIColor.clear.cgColor
    public static var backgroundViewStyle: BackgroundStyle = .blur
    public static var backgroundViewCornerRadius: CGFloat = 20.0
    public static var backgroundViewPresentAnimationDuration: CFTimeInterval = 0.3
    public static var backgroundViewDismissAnimationDuration: CFTimeInterval = 0.3
    
    public static var blurStyle: UIBlurEffect.Style = .dark
    public static var circleColorOutre: CGColor = UIColor.colorWithRGB(red: 130, green: 149, blue: 173, alpha: 1.0).cgColor
    public static var circleColorMiddle: CGColor = UIColor.colorWithRGB(red: 82, green: 124, blue: 194, alpha: 1.0).cgColor
    public static var circleColorInner: CGColor = UIColor.colorWithRGB(red: 60, green: 132, blue: 196, alpha: 1.0).cgColor
    
    public static var circleRotationDurationOuter: CFTimeInterval = 3.0
    public static var circleRotationDurationMiddle: CFTimeInterval = 1.5
    public static var circleRotationDurationInner: CFTimeInterval = 0.75
    
    public static var checkmarkAnimationDrawAnimation: CFTimeInterval = 0.4
    public static var checkmarkLineWidth: CGFloat = 2.0
    public static var checkmarkColor: CGColor = UIColor.colorWithRGB(red: 130, green: 149, blue: 173, alpha: 1).cgColor
    
    public static var successCircleAnimationDrawDuration: CFTimeInterval = 0.7
    public static var successCircleLineWidth: CGFloat = 2.0
    public static var successCircleColor: CGColor = UIColor.colorWithRGB(red: 130, green: 149, blue: 173, alpha: 1).cgColor
    
    public static var failCrossAnimationDrawDuration: CFTimeInterval = 0.7
    public static var failCrossLineWidth: CGFloat = 2.0
    public static var failCrossColor: CGColor = UIColor.colorWithRGB(red: 130, green: 149, blue: 173, alpha: 1).cgColor
    
    public static var failCircleAnimationDrawDuration: CFTimeInterval = 0.7
    public static var failCircleLineWidth: CGFloat = 2.0
    public static var failCircleColor: CGColor = UIColor.colorWithRGB(red: 130, green: 149, blue: 173, alpha: 1).cgColor
    
    public static func restoreDefault() {
        
    }
}
