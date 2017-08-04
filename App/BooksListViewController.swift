//
//  BooksListViewController.swift
//
//  Created by Alex on 29/12/2016.
//  Copyright © 2016 Alexandru Brie. All rights reserved.
//  Contact the author at alexbrie@gmail.com for licensing inquiries.

import UIKit
import UICircularProgressRing

// by default this is for featured authors; but I want to reserve the option of
// making it possible also for stories categories (horror, romance, sf...)

class BooksListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!

    var details : ListDetails!
    var storiesList : [Story]!
    var isFeatured : Bool = false
    
    @IBOutlet weak var detailsTitleLabel: UILabel!

    @IBAction func unwindToIntro(segue : UIStoryboardSegue ) {
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        isFeatured = self.restorationIdentifier == "featuredStories"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        detailsTitleLabel.text = details.name.localizedUppercase
        tableView.reloadData()
    }

    // In a storyboard-based application, you will often want to do a little preparation before 

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.

        if segue.identifier == "showStory" || segue.identifier == "showStoryDetail" {
            if let rc = segue.destination as? ReadingViewController {
                if let crtPath = tableView.indexPathForSelectedRow {
                    rc.currentStory = storiesList[crtPath.row]

                    tableView.deselectRow(at: crtPath, animated: false)
                }
            }
        }
    }

    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "showStory"  || identifier == "showStoryDetail" {
            if let crtPath = tableView.indexPathForSelectedRow {
                let cs = storiesList[crtPath.row]
                return cs.canOpen
            }
        }

        return true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return storiesList.count
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as? UITableViewHeaderFooterView
        header?.textLabel?.font = UIFont(name: "Lato-Light", size: 16)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = isFeatured ? tableView.dequeueReusableCell(withIdentifier: "largeStoryCell", for: indexPath) : tableView.dequeueReusableCell(withIdentifier: "storyCell", for: indexPath)
        let story = storiesList[indexPath.row]
        if let tl = cell.contentView.viewWithTag(11) as? UILabel {
            //cell.textLabel?.text = story.title
            tl.text = story.title
            
            if story.canOpen {
                tl.textColor = UIColor(red:0.05, green:0.36, blue:0.61, alpha:1.00)
            }
            else {
                tl.textColor = UIColor.lightGray
            }
        }
        
        if let tl = cell.contentView.viewWithTag(14) as? UILabel {
            tl.text = story.author?.name
        }

        if let tl = cell.contentView.viewWithTag(12) as? UILabel {
            //cell.detailTextLabel?.text = String(format:"%.1f%%", story.progress)
            tl.text =  "\(story.wordCount/150)m reading" //String(format:"%.1f%%", story.progress)
        }
        if let cp = cell.contentView.viewWithTag(13) as? UICircularProgressRingView {
            if story.progress > 0 {
                cp.isHidden = false
                cp.shouldShowValueText = true
                cp.setProgress(value: CGFloat(story.progress), animationDuration: 0)
                if story.progress == 100 {
                    cp.shouldShowValueText = false
                }
            }
            else {
                cp.isHidden = true
                cp.shouldShowValueText = false
            }
        }

        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

}
