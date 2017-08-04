//
//  ViewController.swift
//
//  Created by Alex on 07/12/2016.
//  Copyright © 2016 Alexandru Brie. All rights reserved.
//  Contact the author at alexbrie@gmail.com for licensing inquiries.

import UIKit


class IntroViewController: UITableViewController {
    var nowReadingStory : Story?

    @IBOutlet weak var nowReadingTitle: UILabel!
    @IBOutlet weak var nowReadingAuthor: UILabel!
    @IBOutlet weak var nowReadingProgress: UILabel!
    
    @IBOutlet weak var startedCountLabel: UILabel!
    @IBOutlet weak var completedCountLabel: UILabel!
    @IBOutlet weak var totalStoriesCountLabel: UILabel!
    @IBOutlet weak var totalAuthorsCountLabel: UILabel!
    @IBOutlet weak var nowReadingCell: UITableViewCell!
    @IBOutlet weak var startedCell: UITableViewCell!
    @IBOutlet weak var completedCell: UITableViewCell!
    
    var hasStartedCell : Bool = false
    var hasCompletedCell : Bool = false
    var hasReadingCell : Bool = false
    
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
    }

    var isTallScreen : Bool { return view.frame.size.height > 600 }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let nVariableCells = (hasStartedCell ? 1 : 0) + (hasReadingCell ? 1 : 0) + (hasCompletedCell ? 1 : 0)
        
        if indexPath.section == 2 {
            return 44
        }
        else if indexPath.section == 0 {
            if isTallScreen || nVariableCells <= 1 {
                return 120
            }
            else {
                return 100
            }
        }
        else {
            if (isTallScreen && nVariableCells <= 2) || (indexPath.row == 0 && hasReadingCell) {
                return 96
            }
            else {
                return 64
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 1 && isTallScreen {
            return 96
        }
        return 1
    }
    
    func updateUI() {
        let nStarted = Persistence.shared.countStories(author_id: nil, state: StoryPersistedState.opened)
        hasStartedCell = nStarted > 0
        startedCell.isHidden = !hasStartedCell
        if hasStartedCell {
            startedCountLabel.text = "\(nStarted) \(plural(nStarted, "Story", "Stories"))"
        }
        
        let nCompleted = Persistence.shared.countStories(author_id: nil, state: StoryPersistedState.completed)
        hasCompletedCell = (nCompleted > 0)
        completedCell.isHidden = !hasCompletedCell
        
        if hasCompletedCell {
            completedCountLabel.text = "\(nCompleted) \(plural(nCompleted, "Story", "Stories"))"
        }

        nowReadingStory = nil

        hasReadingCell = AppModel.shared.lastStoryId != nil
        nowReadingCell.isHidden = !hasReadingCell

        if let lsid = AppModel.shared.lastStoryId {
            if let ls = Persistence.shared.storyFor(story_id: lsid) {
                nowReadingStory = ls
                nowReadingTitle.text = ls.title
                nowReadingAuthor.text = ls.author?.name
                nowReadingProgress.text = String(format:"%.1f%%", ls.progress)
            }
        }
        
        let bc = Persistence.shared.countStories()
        totalStoriesCountLabel.text = "\(bc) \(plural(bc, "Story", "Stories"))"
        let ac = Persistence.shared.authorsCount()
        totalAuthorsCountLabel.text = "\(ac) \(plural(ac, "Author"))"
     }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(IntroViewController.updateUI), name: NSNotification.Name(rawValue: "INTRO_SCREEN_UPDATE"), object: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "INTRO_SCREEN_UPDATE"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
     // MARK: - Navigation
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        /*if identifier == "showFeatured" {
            if let cs = AppModel.shared.featuredStory {
                return cs.tryAccessAlert(self) {
                    self.updateUI()
                }
            }
        }
        else
            */
        if identifier == "showStarted" {
            return true
        }
        else if identifier == "showAll" {
            return true
        }
        else if identifier == "showNowReading" {
            if let ns = nowReadingStory {
                return ns.canOpen
            }
        }
        
        return true
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 {
            IntroViewController.rateAppInStore(APP_ID)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        /*if segue.identifier == "showFeatured" {
            if let rc = segue.destination as? ReadingViewController {
                rc.currentStory = AppModel.shared.featuredStory!
            }
        }
        else*/ if segue.identifier == "showAll" {
            if let rc = segue.destination as? AuthorsListViewController {
                rc.authorsList = AppModel.shared.authorsListGroupedByInitialAscending()
                //rc.tableOfContents = AppModel.shared.tableOfContents
            }
        }
        else if segue.identifier == "showStarted" {
            if let rc = segue.destination as? BooksListViewController {
                rc.details = ListDetails(name: "OPENED STORIES", detailsURLPath: nil, imgURLPath: nil, description: nil)
                rc.storiesList = Persistence.shared.retrieveStories(author_id: nil, state: StoryPersistedState.opened)
            }
        }
        else if segue.identifier == "showFinished" {
            if let rc = segue.destination as? BooksListViewController {
                rc.details = ListDetails(name: "COMPLETED", detailsURLPath: nil, imgURLPath: nil, description: nil)
                rc.storiesList = Persistence.shared.retrieveStories(author_id: nil, state: StoryPersistedState.completed)
            }
        }
        else if segue.identifier == "showNowReading" {
            if let rc = segue.destination as? ReadingViewController {
                rc.currentStory = nowReadingStory
            }
        }
     }
    
    class func rateAppInStore(_ appId: String) {
        UIApplication.shared.openURL(URL(string: appReviewURL(appId))!)
    }
    
    class func appReviewURL(_ appId : String) -> String {
        var templateReviewURL = "itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=\(appId)"
        
        if UIDevice.current.systemVersion.compare("7.0", options: NSString.CompareOptions.numeric, range: nil, locale: nil) != ComparisonResult.orderedAscending {
            templateReviewURL = "itms-apps://itunes.apple.com/app/id\(appId)"
        }
        return templateReviewURL
    }

}

