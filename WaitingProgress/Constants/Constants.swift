//
//  Constants.swift
//  WaitingProgress
//
//  Created by Hung Cao on 4/8/20.
//  Copyright © 2020 Hung Cao. All rights reserved.
//

import UIKit

let BACKGROUND_VIEW_SIDE_LENGTH: CGFloat = 125.0
let STATUS_PATH_SIDE_LENGTH: CGFloat = 125.0

let CIRCLE_ROTATION_TO_VALUE = 2 * CGFloat.pi
let CIRCLE_ROTATION_REPEAT_COUNT = Float(UINT64_MAX)
let CIRCLE_RADIUS_OUTER: CGFloat = 40.0
let CIRCLE_RADIUS_MIDDLE: CGFloat = 30.0
let CIRCLE_RADIUS_INNER: CGFloat = 20.0

let CIRCLE_LINE_WIDTH: CGFloat = 2.0
let CIRCLE_START_ANGLE: CGFloat = -CGFloat.pi / 2
let CIRCLE_END_ANGLE: CGFloat = 0.0

weak var current_status: HCWaitingProgressProtocol?
var current_loader: HCWaitingProgressProtocol?
var current_completionBlock: (() -> Void)?

