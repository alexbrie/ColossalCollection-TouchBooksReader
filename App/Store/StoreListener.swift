//
//  StoreListener.swift
//
//  Created by Alex on 05/09/16.
//  Copyright 2016 Alexandru Brie. All rights reserved.
//  Contact the author at alexbrie@gmail.com for licensing inquiries.

import UIKit
import SVProgressHUD
import StoreKit

let NOTIF_STORE_UNAVAILABLE = "NOTIFICATION_STORE_UNAVAILABLE"
let NOTIF_STORE_AVAILABLE = "NOTIFICATION_STORE_AVAILABLE"
let NOTIF_PURCHASED = "NOTIFICATION_PURCHASED"
let NOTIF_RESTORED = "NOTIFICATION_RESTORED"
let NOTIF_NOT_VALIDATED = "NOTIFICATION_NOT_VALIDATED"
let NOTIF_FAILED = "NOTIFICATION_FAILED"
let NOTIF_CANCELED = "NOTIFICATION_CANCELED"


class StoreListener: NSObject, StoreProtocol {
    // singleton
    static let sharedInstance = StoreListener()
    var priceFormatter : NumberFormatter? = nil
    
    override init() {
        super.init()
        
        Store.shared.delegate = self
    }
    
    deinit {
        Store.shared.delegate = nil
    }
    
    //MARK - Methods
    func productForProductId(_ productId: String?) -> SKProduct? {
        guard let productId = productId else {return nil}
        
        guard let products = Store.shared.products else {return nil}
        for product in  products {
            if product.productIdentifier == productId {
                return product as? SKProduct
            }
        }
        return nil
    }
    
    func purchaseProduct(_ productId: String?) {
        guard let product = productForProductId(productId) else {
            NotificationCenter.default.post(name: Notification.Name(rawValue: NOTIF_STORE_UNAVAILABLE), object: productId)
            return
        }
        Store.shared.purchaseProduct(product)
    }
    
    func restorePurchases() {
        Store.shared.restorePurchase()
    }
    
    func localizedPriceForProduct(_ productId : String?) -> String? {
        let productOrNil = productForProductId(productId)
        guard let product = productOrNil else {return nil}
        
        if priceFormatter == nil {
            priceFormatter = NumberFormatter()
            priceFormatter!.formatterBehavior = NumberFormatter.Behavior.behavior10_4
            priceFormatter!.numberStyle = NumberFormatter.Style.currency
            priceFormatter!.locale = product.priceLocale
        }
        return priceFormatter?.string(from: product.price)
    }
    
    // MARK : Store protocol
    
    func didChange(_ store: Store, toState newState: StoreState) {
        if newState == StoreState.available {
            NotificationCenter.default.post(name: Notification.Name(rawValue: NOTIF_STORE_AVAILABLE), object: nil)
        }
    }
    func didFinishTransactionForIdentifier(_ store: Store, identifier: String?, receiptURL: URL?) {
        SVProgressHUD.dismiss()
        AppModel.shared.isPremium = true
        NotificationCenter.default.post(name: Notification.Name(rawValue: NOTIF_PURCHASED), object: nil, userInfo: nil)
        
//        Answers.logPurchase(withPrice: NSDecimalNumber(string: PRO_VERSION_INTERNAL_PRICE), currency: "USD", success: 1, itemName: "Pro", itemType: "Upgrade", itemId: PRO_VERSION_PRODUCT_ID, customAttributes: [:])
    }
    
    func didRestoreTransactionForIdentifier(_ store: Store,  identifier: String?, receiptURL: URL?) {
        SVProgressHUD.dismiss()
        AppModel.shared.isPremium = true
        NotificationCenter.default.post(name: Notification.Name(rawValue: NOTIF_RESTORED), object: nil, userInfo: nil)
    }
    
    func didFailTransactionForIdentifier(_ store: Store, identifier: String?, userCancel cancel: Bool, error: String?) {
        if cancel {
            NotificationCenter.default.post(name: Notification.Name(rawValue: NOTIF_CANCELED), object: nil)
            SVProgressHUD.dismiss()
        }
        else {
            NotificationCenter.default.post(name: Notification.Name(rawValue: NOTIF_FAILED), object: nil)
            if error != nil {
                SVProgressHUD.showError(withStatus: error!)
            }
            else {
                SVProgressHUD.dismiss()
            }
        }
    }
}
