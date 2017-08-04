//
//  ReadingViewController.swift
//
//  Created by Alex on 09/12/2016.
//  Copyright © 2016 Alexandru Brie. All rights reserved.
//  Contact the author at alexbrie@gmail.com for licensing inquiries.

import UIKit
import WebKit
import AVFoundation
import SVProgressHUD
import MediaPlayer


let PREFERENCES_ANIM_DURATION = 0.5

let FG_COLOR_DEFAULT = UIColor(red:1, green:0.14, blue:0.32, alpha:1)
let BG_COLOR_DEFAULT = UIColor(red:0.96, green:0.96, blue:0.96, alpha:1.00) //UIColor(white: 1.0, alpha: 1)

let FG_COLOR_NIGHT = UIColor(white: 0.9, alpha: 1)
let BG_COLOR_NIGHT = UIColor(white: 0.02, alpha: 1)

let StyleSheetThemeDefault = 0
let StyleSheetThemeNightmode = 1


class ReadingViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler, UIScrollViewDelegate, AVSpeechSynthesizerDelegate  {
    var webView: WKWebView!
    var currentStory : Story!
    var webConfiguration: WKWebViewConfiguration!
    var userContentController : WKUserContentController!
    var synthesizer : AVSpeechSynthesizer!

    var currentSpokenFragmentDict: [String : Any]?
    var preferencesController : PreferencesViewController!
    var isSoundReadingOn: Bool = false
    var isChapterLoaded : Bool = false
    
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var labelProgress: UILabel!
    @IBOutlet weak var preferencesContainerTop: NSLayoutConstraint!
    @IBOutlet weak var preferencesContainerView: UIView!
    @IBOutlet weak var speechToolbar: UIView!
    @IBOutlet weak var btnSpeechState: UIButton!
    @IBOutlet weak var btnSpeechStart: UIButton!
    @IBOutlet weak var btnSpeechStop: UIButton!

    @IBOutlet weak var bgOver: UIView!
    @IBOutlet weak var contentsView: UIView!
    @IBOutlet weak var bannerHeight: NSLayoutConstraint!
    var bannerConstraints : [NSLayoutConstraint] = []
    
    @IBOutlet var backGesture: UIScreenEdgePanGestureRecognizer!
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UserDefaults.standard.integer(forKey:
        "styleSheetKey") == 0 ? UIStatusBarStyle.default : UIStatusBarStyle.default
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addWebview()
        contentsView.backgroundColor = ReadingViewController.getBackgroundColor(UserDefaults.standard.integer(forKey:
            "styleSheetKey"))
        
        loadContent()
        speechToolbar.transform = CGAffineTransform(translationX: 0, y: -100)
        // Do any additional setup after loading the view.
        //UIApplication.shared.setStatusBarHidden(true, with: UIStatusBarAnimation.none)

        synthesizer = AVSpeechSynthesizer()
        synthesizer.delegate = self

        btnSpeechStop.layer.cornerRadius = 4
        btnSpeechStop.layer.borderColor = UIColor.white.cgColor
        btnSpeechStop.layer.borderWidth = 1
        
        MPRemoteCommandCenter.shared().previousTrackCommand.isEnabled = false
        MPRemoteCommandCenter.shared().nextTrackCommand.isEnabled = false

        MPRemoteCommandCenter.shared().pauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.onSpeechPause(self)
            return .success
        }
        
        MPRemoteCommandCenter.shared().playCommand.isEnabled = true
        MPRemoteCommandCenter.shared().playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.onSpeechResumeOrStart(self)
            return .success
        }

        MPRemoteCommandCenter.shared().stopCommand.isEnabled = true
        MPRemoteCommandCenter.shared().stopCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.onSpeechEnd(self)
            return .success
        }

        MPRemoteCommandCenter.shared().togglePlayPauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().togglePlayPauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.onSpeechToggle(self)
            return .success
        }

        UIApplication.shared.beginReceivingRemoteControlEvents()

        try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        preferencesContainerTop.constant = -contentsView.frame.size.height
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var topWVConstraint : NSLayoutConstraint!
    
    func addWebview() {
        webConfiguration = WKWebViewConfiguration()
        userContentController = WKUserContentController()
        
        //webView.navigationDelegate = self
        webConfiguration.userContentController = userContentController
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.backgroundColor = UIColor.clear
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.delegate = self
        webView.navigationDelegate = self
        
        contentsView.insertSubview(webView, belowSubview: bgOver)
        topWVConstraint = webView.topAnchor.constraint(equalTo: contentsView.topAnchor)
        
        NSLayoutConstraint.activate([topWVConstraint, webView.bottomAnchor.constraint(equalTo: contentsView.bottomAnchor), webView.leftAnchor.constraint(equalTo: contentsView.leftAnchor), webView.rightAnchor.constraint(equalTo: contentsView.rightAnchor)])

        //backGesture.addTarget(webView, action:  #selector(ReadingViewController.back))
        //NSLayoutConstraint.activate([webView.topAnchor.constraint(equalTo: btnBack.bottomAnchor), webView.bottomAnchor.constraint(equalTo: contentsView.bottomAnchor), webView.leftAnchor.constraint(equalTo: contentsView.leftAnchor), webView.rightAnchor.constraint(equalTo: contentsView.rightAnchor)])

        addUserScripts(userContentController: userContentController)
    }
    override func didMove(toParentViewController parent: UIViewController?) {
        super.didMove(toParentViewController: parent)
        if parent == nil {
            UIApplication.shared.endReceivingRemoteControlEvents()
            //try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        }
    }
    func back() {
        self.performSegue(withIdentifier: "back", sender: self)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateBackgroundColor()
        SVProgressHUD.dismiss()
    }
    
    func addUserScripts(userContentController : WKUserContentController) {
        guard currentStory != nil else { return }

        if let tbjJSString = try? String(contentsOf: Bundle.main.url(forResource: "tbr", withExtension: "js")!) {
            let script = WKUserScript(source: tbjJSString, injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: true)
            userContentController.addUserScript(script)
        }
        
//        let getFontSize = WKUserScript(source: "Tbr.getFontSize();", injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: true)
//        userContentController.addUserScript(getFontSize)
//        userContentController.add(self, name: "didGetFontSize")

        let onPageLoaded = WKUserScript(source: "Tbr.onPageLoaded();", injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: true)
        userContentController.addUserScript(onPageLoaded)
        userContentController.add(self, name: "onPageLoaded")
        
        let updateThemeScript = WKUserScript(source: "Tbr.replaceCss(\"\(getCurrentStyleSheet())\");", injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: true)
        userContentController.addUserScript(updateThemeScript)

        let scrollToBookmarkScript = WKUserScript(source: "Tbr.scrollToPercent(\"\(currentStory.progress)\");", injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: true)
        userContentController.addUserScript(scrollToBookmarkScript)
        userContentController.add(self, name: "didScroll")

        userContentController.add(self, name: "newTextToRead")
    }

    func updateScroll(percent : Float) {
        self.labelProgress.text = String(format:"%.1f%%", abs(percent))
        self.currentStory.updateProgress(percent)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "onPageLoaded" {
            let fs = UserDefaults.standard.integer(forKey: "fontSize")
            fontSize = fs > 9 ? fs : 9
            SVProgressHUD.dismiss()
        }
        else if message.name == "didScroll" {
            if let fs_dict = message.body as? [String : Any] {
                let percent = fs_dict["percent"] as! Float
                self.updateScroll(percent: percent)
            }
        }
        else if message.name == "newTextToRead" {
            if let fs_dict = message.body as? [String : Any] {
                if let text = fs_dict["text"] as? String {
                    currentSpokenFragmentDict = fs_dict
                    let utterance = AVSpeechUtterance(string: text)
                    let voiceId = UserDefaults.standard.integer(forKey: "accentKey")
                    utterance.voice = AVSpeechSynthesisVoice(language: voiceId == 1 ? "en-UK" : "en-US")
                    synthesizer.speak(utterance)
                }
            }
        }
    }
    
    // MARK : - speech
    
    func speechSynthesizer(_: AVSpeechSynthesizer, didFinish: AVSpeechUtterance) {
        webView.evaluateJavaScript("Tbr.readNext();")
    }
    
    func speechSynthesizer(_: AVSpeechSynthesizer, willSpeakRangeOfSpeechString: NSRange, utterance: AVSpeechUtterance) {
        // highlight current word and/or scroll
        return
        
        if let nodeOffset = currentSpokenFragmentDict?["node_offset"] as? Float {
            if let nodeHeight = currentSpokenFragmentDict?["node_height"] as? Float {
                if let utterance = currentSpokenFragmentDict?["text"] as? String {
                    let deltaH = max(0, nodeHeight - 2*Float(fontSize));
                    let newHeight = nodeOffset + deltaH * Float(willSpeakRangeOfSpeechString.location) / Float(utterance.lengthOfBytes(using: String.Encoding.utf8))
                    
                    webView.evaluateJavaScript("Tbr.setScrollValue(\(Int(newHeight)));")
                }
            }
        }
    }

    // MARK: - speech controls
    
    func onSpeechPause(_ sender: Any) {
        guard isSoundReadingOn else { return }

        isSoundReadingOn = !isSoundReadingOn
        synthesizer.pauseSpeaking(at: AVSpeechBoundary.immediate)
        btnSpeechState.setImage(UIImage(named:"sound_resume_big"), for: UIControlState.normal)
    }
    
    func onSpeechResume(_ sender: Any) {
        guard !isSoundReadingOn else { return }
        guard synthesizer.isPaused else { return }

        isSoundReadingOn = !isSoundReadingOn
        synthesizer.continueSpeaking()
        btnSpeechState.setImage(UIImage(named:"sound_pause_big"), for: UIControlState.normal)
    }

    
    @IBAction func onSpeechStart(_ sender: Any) {
        guard !isSoundReadingOn else { return }
        guard !synthesizer.isPaused else { return }

        topWVConstraint.constant = btnBack.frame.size.height
        
        self.btnSpeechState.setImage(UIImage(named:"sound_pause_big"), for: UIControlState.normal)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 0, options: [], animations: {
            self.speechToolbar.transform = CGAffineTransform.identity
            self.btnSpeechState.isHidden = false
        }){_ in
            self.isSoundReadingOn = true
            self.webView.isUserInteractionEnabled = false
            self.webView.evaluateJavaScript("Tbr.readNext();")
        }
    }

    func onSpeechResumeOrStart(_ sender: Any) {
        guard !isSoundReadingOn else { return }
        if synthesizer.isPaused {
            onSpeechResume(sender)
        }
        else {
            onSpeechStart(sender)
        }
    }
    

    @IBAction func onSpeechEnd(_ sender: Any) {
        //self.webView.evaluateJavaScript("Tbr.clearReading();")
        //if isSoundReadingOn {
        if !synthesizer.isPaused {
            synthesizer.pauseSpeaking(at: AVSpeechBoundary.immediate)
        }
        self.isSoundReadingOn = false

        synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
        //}
        self.stopReading()
        
        UIView.animate(withDuration: 0.3, animations: {
            self.speechToolbar.transform = CGAffineTransform(translationX: 0, y: -100)
            self.btnSpeechState.isHidden = true
        }) {_ in
            self.webView.isUserInteractionEnabled = true
            self.synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
            self.isSoundReadingOn = false
            self.topWVConstraint.constant = 0
        }
    }
    
    @IBAction func onSpeechToggle(_ sender: Any) {
        if isSoundReadingOn {
            onSpeechPause(sender)
        }
        else {
            onSpeechResumeOrStart(sender)
        }
    }

    // MARK: -
    
    class func getForegroundColor(_ style : Int) -> UIColor {
        if style == StyleSheetThemeDefault {
            return FG_COLOR_DEFAULT
        }
        else {
            return FG_COLOR_NIGHT
        }
    }
    
    class func getBackgroundColor(_ style : Int) -> UIColor {
        if style == StyleSheetThemeDefault {
            return BG_COLOR_DEFAULT
        }
        else {
            return BG_COLOR_NIGHT
        }
    }


    // only scroll after end of scrolling, to prevent overhead:
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        saveScroll()
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            saveScroll()
        }
    }

    func saveScroll() {
        webView.evaluateJavaScript("Tbr.getScrollPercent()", completionHandler:{
            value, _ in
            let percent = (value as? Float) ?? 0
            self.updateScroll(percent: percent)
        })
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "prefsEmbed" {
            preferencesController = segue.destination as? PreferencesViewController
            preferencesController.delegate = self
        }
    }

    @IBAction func onShowPreferences(_ sender: Any) {
        preferencesContainerTop.constant = 0
        contentsView.bringSubview(toFront: preferencesContainerView)
        UIView.animate(withDuration: PREFERENCES_ANIM_DURATION, animations:{
            self.view.layoutIfNeeded()
        }, completion: {_ in
            self.preferencesController.onShow()
        })
    }
    
    func onHidePreferences(completion:((Void)->Void)? = nil) {
        preferencesContainerTop.constant = -self.contentsView.frame.size.height
        UIView.animate(withDuration: PREFERENCES_ANIM_DURATION, animations:{
            self.view.layoutIfNeeded()
        }, completion: {
            _ in
            self.contentsView.sendSubview(toBack: self.preferencesContainerView)
            completion?()
        })
    }
    
    //MARK - Web
    
    let templateStringFront = "<!DOCTYPE html><html><head><title>title</title><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0\"><link rel=\"stylesheet\" href=\"main.css\" type=\"text/css\" media=\"all\" /><meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\"></head><body><div id=\"content\">"
    let templateStringBack  = "</div></body></html>"

    func loadContent() {
        let baseURL = Bundle.main.bundleURL
        DLog(baseURL.absoluteString)
        SVProgressHUD.show()
        if currentStory != nil {
            currentStory.fetchFormattedContents { cts in
                self.webView.loadHTMLString("\(self.templateStringFront)<h2>\(self.currentStory.title ?? "")</h2><h3>\(self.currentStory.author?.name ?? "")</h3>\(cts ?? "<h1>Error loading contents</h1>")\(self.templateStringBack)", baseURL: baseURL)
            }
        }
        else {
            self.webView.loadHTMLString("\(self.templateStringFront)<h1>Error loading contents</h1>\(self.templateStringBack)", baseURL: baseURL)
        }
        //updateBackgroundColor()
    }

    var _fontSize : Int!
    var fontSize : Int {
      get {
        return _fontSize
      }
      set(newSize) {
        _fontSize = newSize
        webView.evaluateJavaScript("Tbr.setFontSize(\"body\", \"\(newSize)pt\");")
        UserDefaults.standard.set(newSize, forKey: "fontSize")
        UserDefaults.standard.synchronize()
      }
    }

    func getCurrentStyleSheet() -> String {
        let style = UserDefaults.standard.integer(forKey: "styleSheetKey")
        let crtFont = UserDefaults.standard.integer(forKey: "fontFamilyKey")
        
        let themeLight = "*{color: #0a0a0a;} .TbrSelection{background-color: #ffffdd;} body{background-color: #f4f4f4;}"
        let themeDark = "*{color: #eee;} .TbrSelection{background-color: #772;} body{background-color: #000;}"
        
        let theme = style == 0 ? themeLight : themeDark;
        let ft = crtFont == 0 ? "body{font-family:'Lato';}" : "body{font-family:'Optima';}"

        return "\(theme)\(ft)";
    }
    
    func updateBackgroundColor() {
        contentsView.backgroundColor = ReadingViewController.getBackgroundColor(UserDefaults.standard.integer(forKey: "styleSheetKey"))
        
        bgOver.layer.sublayers?.forEach({ l in
            l.removeFromSuperlayer()
        })
        let gradient = CAGradientLayer()
        gradient.frame = bgOver.bounds
        gradient.colors = [contentsView.backgroundColor!.cgColor, contentsView.backgroundColor!.withAlphaComponent(0.75).cgColor, contentsView.backgroundColor!.withAlphaComponent(0).cgColor]
        bgOver.layer.insertSublayer(gradient, at: 0)
    }
    
    func updateStylesheet(completion:((Void)->Void)?=nil) {
        webView.evaluateJavaScript("Tbr.replaceCss(\"\(getCurrentStyleSheet())\");")
        updateBackgroundColor()
    }
    /*
    func getNextBlob(isFirst : Bool = false, completion:((Void)->String?)? = nil) {
        let jsScript = isFirst ? "voiceFragmentContents = Tbr.findLeafAfterCurrentPos();" : "voiceFragmentContents = Tbr.nextLeaf(voiceFragmentContents);"
    }
    */
    func stopReading() {
        currentSpokenFragmentDict = nil
        webView.evaluateJavaScript("Tbr.stopReading();")
    }
    
    
}


