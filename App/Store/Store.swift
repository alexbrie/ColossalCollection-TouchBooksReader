//
//  Store.swift
//
//  Created by Alex on 17/11/15.
//  Copyright 2016 Alexandru Brie. All rights reserved.
//  Contact the author at alexbrie@gmail.com for licensing inquiries.

import Foundation
import StoreKit

enum StoreState {
    case unknown, unavailable, busy, available
}

protocol StoreProtocol {
    func didChange(_ store: Store, toState: StoreState)
    func didFinishTransactionForIdentifier(_ store: Store, identifier: String?, receiptURL: URL?)
    func didRestoreTransactionForIdentifier(_ store: Store, identifier: String?, receiptURL: URL?)
    func didFailTransactionForIdentifier(_ store: Store, identifier: String?, userCancel: Bool, error: String?)
}

class Store : NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    // singleton
    static let shared = Store()
    
    var delegate : StoreProtocol?
    var state : StoreState {
        didSet{
            delegate?.didChange(self, toState: state)
        }
    }
    var products : [SKProduct]?

    override init(){
        state = .unknown
        super.init()
        forceReload()
    }
    
    func forceReload() {
        //Init StoreKit
        self.state = .unknown
        
        //Verify if payments can be made on this device
        if SKPaymentQueue.canMakePayments() {
            requestProductData()
        }
        else {
            self.state = .unavailable
        }
    }
    
    func requestProductData() {
        state = .busy
        let ids = NSArray(contentsOfFile: Bundle.main.path(forResource: "PurchasesIds", ofType: "plist")!)!
        
        let request = SKProductsRequest(productIdentifiers: NSSet(array: ids as [AnyObject]) as! Set<String>)
        request.delegate = self
        request.start()
    }
    
    func startTransactionObserver() {
        //Make this object a transaction observer
        SKPaymentQueue.default().add(self)
    }

    func purchaseProduct(_ product:SKProduct) {
        state = .busy
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    func restorePurchase() {
        state = .busy
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    // MARK - SKProductsRequestDelegate
    
    internal func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.products = response.products
    
        DLog("In-App-Purchases: \(self.products ?? [])")
    
    //Set state
        if (self.products != nil && self.products!.count > 0) {
            self.state = .available
        }
        else {
            self.state = .unavailable
        }
    
    //Initiate transaction observer
        if (self.state == .available) {
            self.startTransactionObserver()
        }
    }
    
     // MARK - SKPaymentTransactionObserver
    
    internal func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased :
                self.completeTransaction(transaction)
            case .failed:
                self.failedTransaction(transaction)
            case .restored:
                self.restoreTransaction(transaction)
            default : break
            }
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        if queue.transactions.count == 0 {
            self.delegate?.didFailTransactionForIdentifier(self, identifier:nil, userCancel: false, error: "Could not restore")
        }
        //No longer busy
        self.state = .available
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        //Notify delegate
        self.delegate?.didFailTransactionForIdentifier(self, identifier:nil, userCancel: false, error: error.localizedDescription)
        //Finish transaction
        //No longer busy
        self.state = .available
    }
    
    
    func completeTransaction(_ transaction : SKPaymentTransaction){
        //Notify delegate
        self.delegate?.didFinishTransactionForIdentifier(self, identifier:transaction.payment.productIdentifier, receiptURL:
            Bundle.main.appStoreReceiptURL)

        //Finish transaction
        SKPaymentQueue.default().finishTransaction(transaction)
        
        //No longer busy
        self.state = .available
    }
    
    func failedTransaction(_ transaction : SKPaymentTransaction){
        //Flag
        if transaction.error != nil  {
            let userCancel = (transaction.error!._code == 2) // SKErrorPaymentCancelled
            
            //Notify delegate
            self.delegate?.didFailTransactionForIdentifier(self, identifier:transaction.payment.productIdentifier, userCancel: userCancel, error: transaction.error!.localizedDescription)
        }
        //Finish transaction
        SKPaymentQueue.default().finishTransaction(transaction)
        //No longer busy
        self.state = .available
    }
    
    func restoreTransaction(_ transaction : SKPaymentTransaction){
    //Notify delegate
        if transaction.payment.productIdentifier == PRO_VERSION_PRODUCT_ID {
            self.delegate?.didRestoreTransactionForIdentifier(self, identifier:transaction.payment.productIdentifier, receiptURL:
            Bundle.main.appStoreReceiptURL)
        }
        else {
            self.delegate?.didFailTransactionForIdentifier(self, identifier:transaction.payment.productIdentifier, userCancel: false, error: nil)

        }
        
        //Finish transaction
        SKPaymentQueue.default().finishTransaction(transaction)
        //No longer busy
        self.state = .available
    }
}
