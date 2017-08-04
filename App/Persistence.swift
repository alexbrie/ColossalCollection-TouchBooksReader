//
//  Persistence.swift
//
//  Created by Alex on 08/12/2016.
//  Copyright © 2016 Alexandru Brie. All rights reserved.
//  Contact the author at alexbrie@gmail.com for licensing inquiries.

import Foundation

import SQLite

let DB_NAME = "meta.sqlite"
let DB_STORIES_NAME = "stories.sqlite"

let authors = Table("authors")
let stories = Table("stories")

let id = Expression<Int64>("id")
let name = Expression<String>("name")
let title = Expression<String>("title")
let auth_id = Expression<Int64>("auth_id")
let free = Expression<Bool>("free")
let content = Expression<SQLite.Blob>("content")
let word_count = Expression<Int64>("word_count")
let progress = Expression<Double>("progress")

//let last_opened = Expression<Double>("timestamp")


let FeaturedDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
}()


let featured_date = Expression<String?>("featured_date")

enum PersistenceError : Error {
    case invalidDbPath
}

enum StoryPersistedState {
    case any, opened, completed
}

let FORCE_RESET_DB = false
class Persistence: NSObject {
    var isBusy : Bool = false
    var db : Connection?
    var db_stories : Connection?
    
    // singleton
    static let shared = Persistence()
    
    func bundleDatabasePath() ->String? {
        let db_main_name = (DB_NAME as NSString).deletingPathExtension
        let db_path_ext = (DB_NAME as NSString).pathExtension
        
        return Bundle.main.path(forResource: db_main_name, ofType: db_path_ext)
    }
    
    func documentsDatabasePath() -> String {
        let userDatabaseFileName = DB_NAME
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        return ((paths.first ?? "") as NSString).appendingPathComponent(userDatabaseFileName)
    }
    
    override init() {
        super.init()
        db = nil    // close previous db if exists
        /*if let udb = try? openDatabase(forceReset: FORCE_RESET_DB) {
            db = udb
        }*/
        
        db_stories = nil
        if let udb = try? getMetaDatabase() {
            db = udb
        }
        if let udb = try? getStoriesDatabase() {
            db_stories = udb
        }
    }
    
    
    func createTableIfNotExistsAuthors() {
        guard let db = db else { return }
        try! db.run(authors.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(name)
        })
        try! db.run(authors.createIndex([id], unique: false, ifNotExists: true))
    }
    
    func createTableIfNotExistsStories() {
        guard let db = db else { return }
        try! db.run(stories.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(title)
            t.column(auth_id)
            t.column(content)
            //t.column(progress)
            t.column(free)
            t.column(word_count)
        })
        try! db.run(stories.createIndex([id], unique: false, ifNotExists: true))
    }
    
    
    //MARK - Database Methods

    func retrieveAuthors(limit : Int = 0, startAt: Int = 0) -> [Author] {
        var items = [Author]()
        guard let db = db else { return items }
        
        let query: QueryType
        
        if limit > 0  {
            query = authors.limit(limit, offset: startAt).order(name, id)
        }
        else {
            query = authors.order(name, id)
        }
        
        do {
            for row in try db.prepare(query) {
                if let im = authorFor(row: row) {
                    items.append(im)
                }
            }
        }
        catch {
        }
        return items
    }

    func authorFor(row : Row?) -> Author? {
        guard let row = row else { return nil }
        let item = Author()
        item.uid = Int(row[id])
        item.name = row[name]

        return item
    }
    
    func authorFor(author_id: Int) -> Author? {
        guard let db = db else { return nil }
        
        if let row_nil = try? db.pluck(authors.filter(id == Int64(author_id))) {
            if let row = row_nil {
                return authorFor(row: row)
            }
        }
        return nil
    }

    func storyContentsFor(story_id : Int) -> String? {
        guard let db = db_stories else { return nil }
        if let row_nil = try? db.pluck(stories.filter(id == Int64(story_id))) {
            if let row = row_nil {
                let blob = row[content]
                if let str = String(bytes: blob.bytes, encoding: String.Encoding.utf8) {
                    return str
                }
                else if let str = String(bytes: blob.bytes, encoding: String.Encoding.nonLossyASCII) {
                    return str
                }
                else if let str = String(bytes: blob.bytes, encoding: String.Encoding.isoLatin2) {
                    return str
                }
                else if let str = String(bytes: blob.bytes, encoding: String.Encoding.isoLatin1) {
                    return str
                }
                else {
                    return nil
                }
            }
        }
        
        return nil
    }
    
    func storyFor(row : Row?) -> Story? {
        guard let row = row else { return nil }
        let item = Story()
        item.uid = Int(row[id])
        item.title = row[title]
        item.author_id = Int(row[auth_id])
        item.wordCount = Int(row[word_count])
        item.progress = Float(row[progress])
        item.free = row[free]
        if let fd = row[featured_date] {
            item.featuredOn = fd
        }
        
        return item
    }
    
    func featuredStoryFor(dayString : String) -> Story? {
        guard let db = db else { return nil }
        
        if let row_nil = try? db.pluck(stories.filter(featured_date == dayString)) {
            if let row = row_nil {
                return storyFor(row: row)
            }
        }
        
        return nil

    }
    
    func lastFeaturedStoryBefore(dayString : String) -> Story? {
        guard let db = db else { return nil }
        
        if let row_nil = try? db.pluck(stories.filter(featured_date <= dayString).order([featured_date.desc])) {
            if let row = row_nil {
                return storyFor(row: row)
            }
        }
        
        return nil
        
    }
    
    func retrieveFeaturedStoriesBefore(dayString : String) -> [Story] {
        var items = [Story]()
        guard let db = db else { return items }
        
        do {
            for row in try db.prepare(stories.filter(featured_date <= dayString).order([featured_date.desc])) {
                if let im = storyFor(row: row) {
                    items.append(im)
                }
            }
        }
        catch {
        }
        return items
    }

    func setFree(story_id : Int) {
        guard let db = db else { return}
        let _ = try? db.run(stories.filter(id == Int64(story_id)).update(
            free <- true
        ))
    }

    func getFreeCount() -> Int {
        guard let db = db else { return 0}
        return try! db.scalar(stories.filter(free == true).count)
    }

    func updateFeatured(story_id : Int, dayString : String) {
        guard let db = db else { return}
        let _ = try? db.run(stories.filter(id == Int64(story_id)).update(
            featured_date <- dayString
        ))
    }
    
    func updateProgress(story_id : Int, new_progress : Float) {
        guard let db = db else { return}
        let _ = try? db.run(stories.filter(id == Int64(story_id)).update(
            progress <- Double(new_progress)
        ))
    }

    func authorsCount() -> Int {
        guard let db = db else { return 0 }
        return try! db.scalar(authors.count)
    }

    func storyFor(story_id : Int) -> Story? {
        guard let db = db else { return nil }
        
        if let row_nil = try? db.pluck(stories.filter(id == Int64(story_id))) {
            if let row = row_nil {
                return storyFor(row: row)
            }
        }
        
        return nil
    }

    func retrieveStories(author_id: Int? = nil, state: StoryPersistedState = .any) -> [Story] {
        var items = [Story]()
        guard let db = db else { return items }

        do {
            var query : QueryType
            if author_id != nil {
                switch state {
                case .opened:
                    query = stories.filter(auth_id == Int64(author_id!) && progress > 0 && progress < 100).order(id)
                case .completed:
                    query = stories.filter(auth_id == Int64(author_id!) && progress == 100).order(id)
                default:
                    query = stories.filter(auth_id == Int64(author_id!)).order(id)
                }
            }
            else {
                switch state {
                case .opened:
                    query = stories.filter(progress > 0 && progress < 100).order(title, id)
                case .completed:
                    query = stories.filter(progress == 100).order(title, id)
                default:
                    query = stories.order(title, id)
                }
            }
            for row in try db.prepare(query) {
                if let im = storyFor(row: row) {
                    items.append(im)
                }
            }
        }
        catch {
        }
        return items
    }
    
    func countStories(author_id: Int? = nil, state: StoryPersistedState = .any) -> Int {
        guard let db = db else { return 0 }
        
        var query : ScalarQuery<Int>
        if author_id != nil {
            switch state {
            case .opened:
                query = stories.filter(auth_id == Int64(author_id!) && progress > 0 && progress < 100).count
            case .completed:
                query = stories.filter(auth_id == Int64(author_id!) && progress == 100).count
            default:
                query = stories.filter(auth_id == Int64(author_id!)).count
            }
        }
        else {
            switch state {
            case .opened:
                query = stories.filter(progress > 0 && progress < 100).count
            case .completed:
                query = stories.filter(progress == 100).count
            default:
                query = stories.count
            }
        }
        let result = try! db.scalar(query)
        return result
    }

    //MARK - Database Methods
    
    let ALWAYS_OVERWRITE = false
    /*
    func openDatabase(forceReset : Bool) throws -> Connection {
        let ddp = bundleDatabasePath()!
        //documentsDatabasePath()
        DLog(ddp)
        if forceReset {
            try FileManager.default.removeItem(atPath: ddp)
        }
        if ALWAYS_OVERWRITE || !FileManager.default.fileExists(atPath: ddp) {
            // copy template db
            let bdpnil = bundleDatabasePath()
            if let bdp = bdpnil {
                try FileManager.default.copyItem(atPath: bdp, toPath: ddp)
            }
            else {
                //                throw PersistenceError.invalidDbPath
            }
        }
        // else create new
        let db = try Connection(ddp)
        
        //        createTableIfNotExistsAuthors()
        //        createTableIfNotExistsStories()
        
        return db
    }
    */
    
    func getMetaDatabase(copy_overwrite : Bool = false) throws -> Connection {
        let db_main_name = (DB_NAME as NSString).deletingPathExtension
        let db_path_ext = (DB_NAME as NSString).pathExtension
        let bdp = Bundle.main.path(forResource: db_main_name, ofType: db_path_ext)
        let ddp = ((NSSearchPathForDirectoriesInDomains(.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first ?? "") as NSString).appendingPathComponent(DB_NAME)

        //documentsDatabasePath()
        DLog(ddp)
        if copy_overwrite {
            try FileManager.default.removeItem(atPath: ddp)
        }
        if ALWAYS_OVERWRITE || !FileManager.default.fileExists(atPath: ddp) {
            // copy template db
            if let bdp = bdp {
                try FileManager.default.copyItem(atPath: bdp, toPath: ddp)
            }
            else {
                // throw PersistenceError.invalidDbPath
            }
        }
        // else create new

        let db = try Connection(ddp)
//        try db.key(cipher_key)
        return db
    }
    
    func getStoriesDatabase() throws -> Connection {
        let db_main_name = (DB_STORIES_NAME as NSString).deletingPathExtension
        let db_path_ext = (DB_STORIES_NAME as NSString).pathExtension
        let bdp = Bundle.main.path(forResource: db_main_name, ofType: db_path_ext)
        guard bdp != nil else {
            throw PersistenceError.invalidDbPath
         }
        DLog(bdp!)
        let db = try Connection(bdp!)
//        try db.key(cipher_key)
        return db
    }
    
    func closeDatabase() {
        db = nil
        db_stories = nil
    }

}
