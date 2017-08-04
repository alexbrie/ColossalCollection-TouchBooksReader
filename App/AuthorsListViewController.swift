//
//  AuthorsListViewController.swift
//
//  Created by Alex on 24/12/2016.
//  Copyright © 2016 Alexandru Brie. All rights reserved.
//  Contact the author at alexbrie@gmail.com for licensing inquiries.

import UIKit
import SVProgressHUD

class AuthorsListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    var authorsList: [(sectionName: String, authors:[Author])]!

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before 
    @IBAction func unwindToAuthor(segue : UIStoryboardSegue ) {
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.

        if segue.identifier == "showBooks" {
            if let rc = segue.destination as? BooksListViewController {
                if let crtPath = tableView.indexPathForSelectedRow {
                    let author = authorsList[crtPath.section].authors[crtPath.row]

                    rc.details = AppModel.shared.detailsFor(author: author)
                    rc.storiesList = Persistence.shared.retrieveStories(author_id: author.uid)

                    tableView.deselectRow(at: crtPath, animated: false)
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return authorsList[section].authors.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "   \(authorsList[section].sectionName)"
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as? UITableViewHeaderFooterView
        header?.textLabel?.font = UIFont(name: "Lato-Light", size: 16)
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return authorsList.map { sn, _  in
            return sn
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "authorCell", for: indexPath)
        let author = authorsList[indexPath.section].authors[indexPath.row]

        cell.textLabel?.text = author.name
        DispatchQueue.global().async {
            let bc = Persistence.shared.countStories(author_id: author.uid, state: StoryPersistedState.any)

            DispatchQueue.main.async {
                cell.detailTextLabel?.text = "\(bc) Stor\(bc==1 ? "y" : "ies")"
            }
        }
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return authorsList.count
    }
}
