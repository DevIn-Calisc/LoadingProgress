//
//  HCWaitingProgressProtocol.swift
//  WaitingProgress
//
//  Created by Hung Cao on 4/8/20.
//  Copyright © 2020 Hung Cao. All rights reserved.
//

import UIKit

@objc protocol HCWaitingProgressProtocol {
    var emptyView: UIView { get }
    var backgroundView: UIView { get }
    
    @objc optional var outerCircle: CAShapeLayer { get set }
    @objc optional var middleCircle: CAShapeLayer { get set }
    @objc optional var innerCircle: CAShapeLayer { get set }
    @objc optional weak var targetView: UIView? { get set }
}
