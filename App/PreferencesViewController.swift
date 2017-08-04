//
//  PreferencesViewController.swift
//
//  Created by Alex on 09/12/2016.
//  Copyright © 2016 Alexandru Brie. All rights reserved.
//  Contact the author at alexbrie@gmail.com for licensing inquiries.

import UIKit

class PreferencesViewController: UIViewController {
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var btnFontSmall: UIButton!
    @IBOutlet weak var btnFontLarge: UIButton!
    var delegate : ReadingViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        [btnFontLarge, btnFontSmall].forEach{ b in
            b?.layer.borderColor = UIColor.black.cgColor
            b?.layer.borderWidth = 1.0
            b?.layer.cornerRadius = 4.0
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func onShow() {
        let style = UserDefaults.standard.integer(forKey: "styleSheetKey")
        themeControl.isOn = (style == 1)
        let crtFont = UserDefaults.standard.integer(forKey: "fontFamilyKey")
        fontControl.selectedSegmentIndex = crtFont
        let crtVoice = UserDefaults.standard.integer(forKey: "accentKey")
        accentControl.selectedSegmentIndex = crtVoice
        UIView.animate(withDuration: PREFERENCES_ANIM_DURATION){
            self.bgView.alpha = 1.0
        }
    }
    
    func onHide() {
        UIView.animate(withDuration: PREFERENCES_ANIM_DURATION){
            
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func onFontSmall(_ sender: Any) {
        let fs = delegate?.fontSize ?? 10
        delegate?.fontSize = fs > 10 ? fs-1 : fs
    }

    @IBOutlet weak var accentControl: UISegmentedControl!
    @IBAction func onChangeAccent(_ sender: Any) {
        UserDefaults.standard.set(accentControl.selectedSegmentIndex, forKey: "accentKey")
        UserDefaults.standard.synchronize()
    }

    @IBAction func onFontLarge(_ sender: Any) {
        let fs = delegate?.fontSize ?? 10
        delegate?.fontSize = fs < 20 ? fs+1 : fs
    }
    
    @IBOutlet weak var fontControl: UISegmentedControl!
    @IBAction func onChangeFont(_ sender: Any) {
        UserDefaults.standard.set(fontControl.selectedSegmentIndex, forKey: "fontFamilyKey")
        UserDefaults.standard.synchronize()
        delegate?.updateStylesheet()
    }
    
    @IBOutlet weak var themeControl: UISwitch!
    @IBAction func onChangeTheme(_ sender: Any) {
        UserDefaults.standard.set(themeControl.isOn ? 1 : 0, forKey: "styleSheetKey")
        UserDefaults.standard.synchronize()
        delegate?.updateStylesheet()
    }
    
    @IBAction func onDismiss(_ sender: Any) {
        self.bgView.alpha = 0.0
        delegate?.onHidePreferences(){
            //self.onHide()
        }
    }
}
