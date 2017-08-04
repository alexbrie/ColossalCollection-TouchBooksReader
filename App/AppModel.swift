//
//  AppModel.swift
//
//  Created by Alex on 27/12/2016.
//  Copyright © 2016 Alexandru Brie. All rights reserved.
//  Contact the author at alexbrie@gmail.com for licensing inquiries.

import UIKit
import SVProgressHUD

class Author : NSObject {
    var uid : Int!
    var name : String!
}


struct ListDetails {
    var name : String
    var detailsURLPath : String?
    var imgURLPath : String?
    var description : String?
}

class Server: NSObject{
}

let FREE_STORIES_MAX = 25

class Story : NSObject {
    var uid : Int!
    var title : String!
    var author_id : Int!
    private var _author : Author? = nil
    var author : Author? {
        guard _author == nil else { return _author }
        return Persistence.shared.authorFor(author_id: author_id)
    }
    var wordCount : Int = 0
    var progress : Float = 0
    var featuredOn : String?
    var free : Bool = false
    
    func updateProgress(_ prog : Float) {
        self.progress = prog
        Persistence.shared.updateProgress(story_id: uid, new_progress: prog)
        
        // mark this as the most recent book opened
        AppModel.shared.lastStoryId = uid
    }

    func fetchFormattedContents(completion : @escaping (String?)->Void) {
        DispatchQueue.global().async {
            let str = Persistence.shared.storyContentsFor(story_id: self.uid)
            completion(str)
        }
    }
    
    let canOpen : Bool = true
}


class AppModel : NSObject {
    // singleton
    static let shared = AppModel()

    var featuredMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    var unlockedStoriesCount : Int = 0
    var lastStoryId : Int? {
        didSet {
            UserDefaults.standard.set(lastStoryId!, forKey: "lastStory")
            UserDefaults.standard.synchronize()
        }
    }
    
    
    var isPremium : Bool {
        get{
            #if DEBUG_SET_PRO_MODE
                return true
            #endif
            return UserDefaults.standard.bool(forKey: "proVersion")
        }
        set(nPremium) {
            UserDefaults.standard.set(nPremium, forKey: "proVersion")
            UserDefaults.standard.synchronize()
            NotificationCenter.default.post(name: Notification.Name(rawValue: "NOTIF_PURCHASED"), object: nil)
        }
    }

    
    var tableOfContents : [(author:String, stories:[Story])]?

    func getFilePath(fileName: String) -> String? {
        return (NSSearchPathForDirectoriesInDomains(.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first as? NSString)?.appendingPathComponent(fileName)
    }

    override init() {
        super.init()

        let lsr = UserDefaults.standard.integer(forKey: "lastStory")
        if lsr > 0 {
            lastStoryId = lsr
        }
        
        if !isPremium {
            unlockedStoriesCount = Persistence.shared.getFreeCount()
        }
    }

    func fetchTableOfContents(completion: (([(author:String, stories:[Story])])->Void)? = nil) {
        DispatchQueue.global().async {
            let authors = Persistence.shared.retrieveAuthors()
            let mappedTC = authors.map { auth in
                return (author:auth.name!, stories:Persistence.shared.retrieveStories(author_id: auth.uid))
            }
            completion?(mappedTC)
        }
    }

    func authorsListGroupedByInitialAscending() -> [(sectionName: String, authors:[Author])]{
        var authorsList: [(sectionName: String, authors:[Author])] = []

        let authors = Persistence.shared.retrieveAuthors()
        var authorsHash = [String: [Author!]]()
        authors.forEach({ a in
            let firstLetterIndex = a.name.index(a.name.startIndex, offsetBy: 1)
            let initial = a.name.substring(to: firstLetterIndex)
            if authorsHash[initial] == nil {
                authorsHash[initial] = []
            }
            authorsHash[initial]?.append(a)
        })
        authorsList = []
        authorsHash.forEach() { i, arr in
            authorsList.append( (sectionName: i, authors: arr.sorted() { $0.name < $1.name }))
        }
        authorsList.sort(){ $0.sectionName < $1.sectionName}
        return authorsList
    }

    func detailsFor(author : Author) -> ListDetails {
        return ListDetails(name: author.name, detailsURLPath: nil, imgURLPath: nil, description: nil)
    }
}
