//
//  Common.swift
//
//  Created by Alex on 03/03/16.
//  Copyright © 2016 Alex. All rights reserved.
//  Contact the author at alexbrie@gmail.com for licensing inquiries.

import UIKit



func DLog(_ message: String, function: String = #function) {
    #if DEBUG
        NSLog("\(function): \(message)")
    #endif
}

func showSimpleAlert(_ title:String? = nil, button:String = "OK", text: String, inController: UIViewController, _ onOk: (()->())? = nil) {
    DispatchQueue.main.async {
        let ac = UIAlertController(title: title, message: text, preferredStyle: UIAlertControllerStyle.alert)
        ac.addAction(UIAlertAction(title: button, style: UIAlertActionStyle.default, handler: { (action) in
            onOk?()
        }))
        inController.present(ac, animated: true, completion: nil)
    }
}

func plural(_ count: Int, _ singular:String, _ plural:String? = nil) -> String {
    return count==1 ? singular : (plural == nil ? "\(singular)s" : plural!)
}

// bundle of commonly used utility functions
struct CommonSwift {
    static func prepareActionSheetForiPad(_ view: UIView, ac : UIAlertController, sender : AnyObject?) {
        
        if let popoverController = ac.popoverPresentationController {
            if let sd = sender as? UIBarButtonItem {
                popoverController.barButtonItem = sd
            }
            else if let v = sender as? UIView {
                popoverController.sourceView = v
                popoverController.sourceRect = v.bounds
            }
            else {
                popoverController.sourceView = view
                popoverController.sourceRect = CGRect(x: view.frame.origin.x + view.frame.size.width/2, y: view.frame.size.height/2, width: 20, height: 20)
                //self.view.bounds
                popoverController.permittedArrowDirections = UIPopoverArrowDirection.up
            }
        }
    }
    
    static func matchesForRegexInText(_ regex: String!, text: String!) -> [String] {
        var expr: NSRegularExpression?
        do {
            expr = try NSRegularExpression(pattern: regex, options: [])
            let nsString = text as NSString
            let results = expr!.matches(in: text, options: [], range: NSMakeRange(0, nsString.length))
                
            return results.map { nsString.substring(with: $0.range)}
        } catch {
            DLog("invalid regex")
            return []
        }
    }

    // animations
    static func heartbeatPulse(_ v : UIView, duration: Double = 1.5, delay: Double = 0.4) {
        v.layer.removeAllAnimations()
        
        UIView.animate(withDuration: duration, delay: delay,  usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [UIViewAnimationOptions.repeat, UIViewAnimationOptions.allowUserInteraction, UIViewAnimationOptions.autoreverse], animations: { () -> Void in
            v.transform  = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { (finished) -> Void in
            v.transform = CGAffineTransform.identity
        }
    }
    
    static func heartbeatPulse2(_ v : UIView, delay: Double) {
        v.layer.removeAllAnimations()
        UIView.animate(withDuration: 1.5, delay: delay,  usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [UIViewAnimationOptions.allowUserInteraction], animations: { () -> Void in
            v.transform  = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { (finished) -> Void in
            UIView.animate(withDuration: 3.0, delay: delay,  usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [UIViewAnimationOptions.repeat, UIViewAnimationOptions.allowUserInteraction, .autoreverse], animations: { () -> Void in
                v.transform  = CGAffineTransform.identity
            }) { (finished) -> Void in
                v.transform  = CGAffineTransform.identity
            }
        }
        
    }

    static func addShadowsAndBorder(_ v: UIView, corner: CGFloat = 10.0) {
        v.layer.cornerRadius = corner
        v.layer.shadowOffset = CGSize(width: 4, height: 4)
        v.layer.shadowRadius = 1
        v.layer.shadowOpacity = 0.2
        v.layer.shadowColor = UIColor.black.cgColor
    }
    
    static func LogEvent(_ type:String, name:String) {
//        [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"General" action:@"Purchase" label:@"Purchase complete" value:nil] build]];
    }

    static func LogPurchase(_ type:String, name:String) {
//        [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"General" action:@"Purchase" label:@"Purchase complete" value:nil] build]];
//        Answers.logPurchase(withPrice: 0.99,
//                                     currency: "USD",
//                                     success: true,
//                                     itemName: name,
//                                     itemType: type,
//                                     itemId: name,
//                                     customAttributes: [:])
    }
    
}

// shorthand utility for localization
public func LOC(_ str: String) -> String {
    return NSLocalizedString(str, comment: "")
}

