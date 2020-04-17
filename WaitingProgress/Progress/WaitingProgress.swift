//
//  WaitingProgress.swift
//  WaitingProgress
//
//  Created by Hung Cao on 4/8/20.
//  Copyright © 2020 Hung Cao. All rights reserved.
//

import UIKit

@objcMembers public final class WaitingProgress: NSObject {
    public static var shown: Bool {
        return current_loader != nil ? true : false
    }
    public static var statusShown: Bool {
        return current_status != nil ? true : false
    }
    
    // MARK: Show status
    public static func showSuccess() {
        if !statusShown {
            StatusWaitingProgress.show(type: .success)
        }
    }
    public static func showFail() {
        if !statusShown {
            StatusWaitingProgress.show(type: .fail)
        }
    }
    
    // MARK: Show Infinite Loader
    public static func show() {
        if !shown {
            InfiniteLoader().showOnView(view: nil, completionBlock: nil)
        }
    }
    
    public static func showWithPresentCompletionBlock(block: @escaping () -> Void) {
        if !shown {
            InfiniteLoader().showOnView(view: nil, completionBlock: block)
        }
    }
    public static func showOnView(view: UIView) {
        if !shown {
            InfiniteLoader().showOnView(view: view, completionBlock: nil)
        }
    }
    public static func showOnView(view: UIView, completionBlock: @escaping () -> Void) {
        if !shown {
            InfiniteLoader().showOnView(view: view, completionBlock: completionBlock)
        }
    }
    
    // MARK: Show Progress Loader
    public static func showWithProgress(initialValue value: CGFloat) {
        if !shown {
            ProgressLoader().showWithValue(value: value, onView: nil, progress: nil, completionBlock: nil)
        }
    }
    public static func showWithProgress(initialValue value: CGFloat = 0.0, progress: Progress? = nil, onView view: UIView? = nil, completionBlock:(() -> Void)? = nil) {
        if !shown {
            ProgressLoader().showWithValue(value: value, onView: view, progress: progress, completionBlock: completionBlock)
        }
    }
    
    // MARK: Update Progress Loader
    public static func updateWithProgress(value: CGFloat) {
        ProgressLoader.weakSelf?.progressValue = value
    }
    public static func cancelProgressWithFailAnimation(showFail: Bool, completionBlock: (() -> Void)? = nil) {
        ProgressLoader.weakSelf?.cancelWithFailAnimation(failAnim: showFail, completionBlock: completionBlock)
    }
    
    // MARK: Hide Loader
    public static func hide(block: (() -> Void)? = nil) {
        hideLoader(loader: current_loader, withCompletionBlock: block)
    }
}
