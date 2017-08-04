//
//  StoreViewController.swift
//
//  Created by Alex on 06/01/2017.
//  Copyright © 2017 Cognitive Bits. All rights reserved.
//  Contact the author at alexbrie@gmail.com for licensing inquiries.

import UIKit
import SVProgressHUD

class StoreViewController: UIViewController {
    @IBOutlet weak var btnUpgrade: UIButton!
    @IBOutlet weak var labelAlreadyPro: UILabel!
    
    var closeCompletion : ((Void)->Void)?
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(StoreViewController.handleProChanged(_:)), name: NSNotification.Name(rawValue: NOTIF_PURCHASED), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(StoreViewController.handleProChanged(_:)), name: NSNotification.Name(rawValue: NOTIF_RESTORED), object: nil)
        
        if let productPrice = StoreListener.sharedInstance.localizedPriceForProduct(PRO_VERSION_PRODUCT_ID) {
            btnUpgrade.setTitle("ONLY \(productPrice)", for: UIControlState())
        }
        else {
            btnUpgrade.setTitle("Get Premium", for: UIControlState())
            SVProgressHUD.showError(withStatus: "Error connecting to store.")
        }
        updateUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    func  updateUI() {
        if AppModel.shared.isPremium {
            labelAlreadyPro.isHidden = false
            btnUpgrade.isHidden = true
        }
        else {
            labelAlreadyPro.isHidden = true
            btnUpgrade.isHidden = false
        }
    }
    
    func handleProChanged(_ notif : Notification) {
        SVProgressHUD.dismiss()
        updateUI()
    }

    @IBAction func onClose(_ sender: Any) {
        dismiss(animated: true) { 
            self.closeCompletion?()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onUpgrade(_ sender: AnyObject) {
        SVProgressHUD.show(withStatus: "Purchasing...")
        StoreListener.sharedInstance.purchaseProduct(PRO_VERSION_PRODUCT_ID)
    }
    @IBAction func onRestore(_ sender: AnyObject) {
        SVProgressHUD.show(withStatus: "Restoring...")
        StoreListener.sharedInstance.restorePurchases()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
