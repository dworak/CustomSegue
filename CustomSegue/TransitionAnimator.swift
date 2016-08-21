//
//  TransitionAnimator.swift
//  CustomSegue
/*
 The MIT License (MIT)
 Copyright (c) 2016 Eric Marchand (phimage)
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import AppKit

// Simple enum for transition type.
public enum TransitionType {
    case Present, Dismiss
}

// Protocol that view controllers can implement to receive notification of transition.
// This could be used to change controller behaviours.
public protocol TransitionAnimatorNotifiable {
  
    // Notify the transition completion
    func notifyTransitionCompletion(transition: TransitionType)
}

// An animator to present view controller using NSViewControllerTransitionOptions
public class TransitionAnimator: NSObject, NSViewControllerPresentationAnimator {

    // Duration of animation (default: 0.3)
    public var duration: NSTimeInterval
    // Animation options for view transitions
    public var transition: NSViewControllerTransitionOptions
    // Background color used on destination controller if not already defined
    public var backgroundColor = NSColor.windowBackgroundColor()
    // If false, destination controller take the size of the source controller
    // If true, when sliding the destination controller keep one of its size element.(ex: for slide down and up, the height is kept)
    // (default: false)
    public var keepOriginalSize = false
    // Remove view of fromViewController from view hierarchy. Best use with crossfade effect.
    public var removeFromView = false
    // Optional origin point for displayed view
    public var origin: NSPoint? = nil {
        didSet {
            assert(keepOriginalSize)
        }
    }
    
    private var fromView: NSView? = nil

    // Init
    public init(duration: NSTimeInterval =  0.3, transition: NSViewControllerTransitionOptions = [.Crossfade, .SlideDown]) {
        self.duration = duration
        self.transition = transition
    }

    // MARK: NSViewControllerPresentationAnimator
    
    
    @objc public func animatePresentationOfViewController(viewController: NSViewController, fromViewController: NSViewController) {
        let fromFrame = fromViewController.view.frame

        let originalFrame = viewController.view.frame
        let startFrame = transition.slideStartFrame(fromFrame, keepOriginalSize: keepOriginalSize, originalFrame: originalFrame)
        var destinationFrame = transition.slideStopFrame(fromFrame, keepOriginalSize: keepOriginalSize, originalFrame: originalFrame)
        
        if let origin = self.origin {
            destinationFrame.origin = origin
        }

        viewController.view.frame = startFrame
        viewController.view.autoresizingMask = [.ViewWidthSizable, .ViewHeightSizable]

        if transition.contains(.Crossfade) {
            viewController.view.alphaValue = 0
        }

        if !viewController.view.wantsLayer { // remove potential transparency
            viewController.view.wantsLayer = true
            viewController.view.layer?.backgroundColor = backgroundColor.CGColor
            viewController.view.layer?.opaque = true
        }
        // maybe create an intermediate container view to remove from controller view from hierarchy
        if removeFromView {
            fromView = fromViewController.view
            fromViewController.view = NSView(frame: fromViewController.view.frame)
            fromViewController.view.addSubview(fromView!)
        }
        fromViewController.view.addSubview(viewController.view)

        NSAnimationContext.runAnimationGroup(
            { [unowned self] context in
                context.duration = self.duration
                context.timingFunction =  CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
                
                viewController.view.animator().frame = destinationFrame
                if self.transition.contains(.Crossfade) {
                    viewController.view.animator().alphaValue = 1
                    self.fromView?.animator().alphaValue = 0
                }
                
            }, completionHandler: { [unowned self] in
                if self.removeFromView {
                    self.fromView?.removeFromSuperview()
                }
                if let src = viewController as? TransitionAnimatorNotifiable {
                    src.notifyTransitionCompletion(.Present)
                }
                if let dst = viewController as? TransitionAnimatorNotifiable {
                    dst.notifyTransitionCompletion(.Present)
                }
        })
    }

    @objc public func animateDismissalOfViewController(viewController: NSViewController, fromViewController: NSViewController) {
        let fromFrame = fromViewController.view.frame
        let originalFrame = viewController.view.frame
        let destinationFrame = transition.slideStartFrame(fromFrame, keepOriginalSize: keepOriginalSize, originalFrame: originalFrame)
        
        if self.removeFromView {
            fromViewController.view.addSubview(self.fromView!)
        }
        
        NSAnimationContext.runAnimationGroup(
            { [unowned self] context in
                context.duration = self.duration
                context.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
                
                viewController.view.animator().frame = destinationFrame
                if self.transition.contains(.Crossfade) {
                    viewController.view.animator().alphaValue = 0
                    self.fromView?.animator().alphaValue = 1
                }

            }, completionHandler: {
                viewController.view.removeFromSuperview()
                if self.removeFromView {
                    if let view = self.fromView {
                        fromViewController.view = view
                    }
                }
                
                if let src = viewController as? TransitionAnimatorNotifiable {
                    src.notifyTransitionCompletion(.Dismiss)
                }
                if let dst = viewController as? TransitionAnimatorNotifiable {
                    dst.notifyTransitionCompletion(.Dismiss)
                }
        })
    }
}


// MARK: NSViewControllerTransitionOptions

extension NSViewControllerTransitionOptions {
    
    func slideStartFrame(fromFrame: NSRect, keepOriginalSize: Bool, originalFrame: NSRect) -> NSRect {
        if self.contains(.SlideLeft) {
            let width = keepOriginalSize ? originalFrame.width : fromFrame.width
            return NSRect(x: fromFrame.width, y: 0, width: width, height: fromFrame.height)
        }
        if self.contains(.SlideRight) {
            let width = keepOriginalSize ? originalFrame.width : fromFrame.width
            return NSRect(x: -width, y: 0, width: width, height: fromFrame.height)
        }
        if self.contains(.SlideDown) {
            let height = keepOriginalSize ? originalFrame.height : fromFrame.height
            return NSRect(x: 0, y: fromFrame.height, width: fromFrame.width, height: height)
        }
        if self.contains(.SlideUp) {
            let height = keepOriginalSize ? originalFrame.height : fromFrame.height
            return NSRect(x: 0, y: -height, width: fromFrame.width, height: height)
        }
        if self.contains(.SlideForward) {
            switch NSApp.userInterfaceLayoutDirection {
            case .LeftToRight:
                return NSViewControllerTransitionOptions.SlideLeft.slideStartFrame(fromFrame, keepOriginalSize: keepOriginalSize, originalFrame: originalFrame)
            case .RightToLeft:
                return NSViewControllerTransitionOptions.SlideRight.slideStartFrame(fromFrame, keepOriginalSize: keepOriginalSize, originalFrame: originalFrame)
            }
        }
        if self.contains(.SlideBackward) {
            switch NSApp.userInterfaceLayoutDirection {
            case .LeftToRight:
                return NSViewControllerTransitionOptions.SlideRight.slideStartFrame(fromFrame, keepOriginalSize: keepOriginalSize, originalFrame: originalFrame)
            case .RightToLeft:
                return NSViewControllerTransitionOptions.SlideLeft.slideStartFrame(fromFrame, keepOriginalSize: keepOriginalSize, originalFrame: originalFrame)
            }
        }
        return fromFrame
    }
    
    func slideStopFrame(fromFrame: NSRect, keepOriginalSize: Bool, originalFrame: NSRect) -> NSRect {
        if !keepOriginalSize {
            return fromFrame
        }
        if self.contains(.SlideLeft) {
            return NSRect(x: fromFrame.width - originalFrame.width , y: 0, width: originalFrame.width , height: fromFrame.height)
        }
        if self.contains(.SlideRight) {
            return NSRect(x: 0, y: 0, width: originalFrame.width , height: fromFrame.height)
        }
        if self.contains(.SlideUp) {
            return NSRect(x: 0, y: 0, width: fromFrame.width, height: originalFrame.height )
        }
        if self.contains(.SlideDown) {
            return NSRect(x: 0, y: fromFrame.height - originalFrame.height , width: fromFrame.width, height: originalFrame.height)
        }
        if self.contains(.SlideForward) {
            switch NSApp.userInterfaceLayoutDirection {
            case .LeftToRight:
                return NSViewControllerTransitionOptions.SlideLeft.slideStopFrame(fromFrame, keepOriginalSize: keepOriginalSize, originalFrame: originalFrame)
            case .RightToLeft:
                return NSViewControllerTransitionOptions.SlideRight.slideStopFrame(fromFrame, keepOriginalSize: keepOriginalSize, originalFrame: originalFrame)
            }
        }
        if self.contains(.SlideBackward) {
            switch NSApp.userInterfaceLayoutDirection {
            case .LeftToRight:
                return NSViewControllerTransitionOptions.SlideRight.slideStopFrame(fromFrame, keepOriginalSize: keepOriginalSize, originalFrame: originalFrame)
            case .RightToLeft:
                return NSViewControllerTransitionOptions.SlideLeft.slideStopFrame(fromFrame, keepOriginalSize: keepOriginalSize, originalFrame: originalFrame)
            }
        }
        return fromFrame
    }
    
}
