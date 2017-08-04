require 'rubygems'
require 'plist'
require "sqlite3"


def create_meta_database(db)
  # Create a table
  authors_table = db.execute <<-SQL
  CREATE TABLE "authors" (
    "id" INTEGER PRIMARY KEY NOT NULL,
    "name" TEXT NOT NULL
  )
  SQL

  stories_table = db.execute <<-SQL
  CREATE TABLE "stories" (
    "id" INTEGER PRIMARY KEY NOT NULL,
    "title" TEXT NOT NULL,
    "auth_id" INTEGER NOT NULL,
    "free" INTEGER NOT NULL DEFAULT 0,
    "progress" REAL DEFAULT 0,
    "featured_date" TEXT,
    "word_count" INTEGER NOT NULL);
  SQL
  
  index = db.execute <<-SQL
    CREATE INDEX "auth" ON "stories" ("auth_id")
  SQL
  
end

def create_stories_database(db)
  # Create a table
  stories_table = db.execute <<-SQL
  CREATE TABLE "stories" (
    "id" INTEGER PRIMARY KEY NOT NULL,
    "auth_name" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "content" TEXT NOT NULL)
  SQL
end

    #"timestamp" REAL NOT NULL)

class String
  def count_words
    #split(/\S+/).size
    return split(/\W+/m).count{|wd| wd.length > 3}
  end
end

# Open a database
db_path = "../meta.sqlite"
db_stories_path = "../stories.sqlite"

File.delete(db_stories_path) if File.exist?(db_stories_path)
File.delete(db_path) if File.exist?(db_path)

db = SQLite3::Database.new db_path
db_stories = SQLite3::Database.new db_stories_path

create_meta_database(db)
create_stories_database(db_stories)


# dirs = Dir.glob("./AppContent_orig/*").select{|file| File.filetype(file) == "directory"} # ruby 1.x
dirs = Dir.glob("./AppContent_orig/*").select{|file| File.directory?(file)}   # ruby 2.x
# puts dirs
counter_authors = 0
counter_stories = 0

dirs.each do |dir|
  dir_base = File.basename(dir)
  sub_plists = Dir[File.join(dir, "*.plist")]

  if !sub_plists.empty?
    counter_authors += 1
    
    file_name = sub_plists.first
    
    # puts File.basename(sub_plists.first)
    
    b = Plist::parse_xml(file_name)
    author = b["title"]

    begin
      db.execute "insert into authors values ( ?, ? )", [counter_authors, author]
    rescue Exception => e 
      puts e
    end
    
    # puts author
    stories = b["sections"]
    if stories.count == 1 
      items = stories.first["items"]
    
      items.each do |item|
        counter_stories += 1
        title = item["title"]
        file = item["file"]
        contents_file_name = File.join(File.join("AppContent", dir_base), file)         
        content = File.open(contents_file_name, "rb").read
        content = content.strip
        # print contents_file_name
        
        begin
          db.execute "insert into stories values ( ?, ? , ?, ?, ?, ?, ?)", [counter_stories, title, counter_authors, 0, 0, nil, content.count_words]
          db_stories.execute "insert into stories values ( ?, ?, ?, ? )", [counter_stories, author, title, content]
          
        rescue Exception => e 
          puts e
        end
      end
    end
  end
end

# for stories in

# new_item = {:dir=>dir, :file=>File.basename(sub_plists.first), :starred=>false, :new=>false, :page_id=>counter.to_s}
# result_hash[:sections][0][:items]<<new_item
# counter+=1
# puts counter, counter_singles, counter_multis