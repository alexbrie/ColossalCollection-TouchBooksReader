#!/usr/bin/ruby
require File.dirname(__FILE__) +'/_deps/plist'

LINE_LENGTH = 30
if ARGV.count!=1
  puts "Meta Table of contents generator for TouchBooksReader books"
  puts "-"*LINE_LENGTH
  puts "(c) Alexandru Brie 2010"
  puts "Permission to use granted only for TouchBooksReader licensed apps"
  puts "-"*LINE_LENGTH
  puts "The script will parse all subfolders of current folder and add links to included plist files. If you want to reorder the results or group them in subsections, you'll need to edit the resulting plist using the plist editor"
  puts "-"*LINE_LENGTH
  puts "How to use: Type the command line: #{__FILE__} src_folder  > src_folder/Books.plist"
  exit
end

def String.natural_order(nocase=false)
  proc do |str|
    i = true
    str = str.upcase if nocase
    str.gsub(/\s+/, '').split(/(\d+)/).map {|x| (i = !i) ? x.to_i : x}
  end
end


#basedir = '../test_apps/DemoBook/AppContent/book1/'
#basedir = '../test_apps/DemoBookJpAdmob/AppContent/book1/'
basedir = ARGV[0]

Dir.chdir(basedir)

result_hash = {:is_books_index=>true, :sections=>[{:title=>"", :items=>[]}]}
counter = 0

dirs = Dir.glob("*").select{|file| File.ftype(file) == "directory"}
dirs.each do |dir|
  sub_plists = Dir[File.join(dir, "*.plist")]
  if !sub_plists.empty?
    new_item = {:dir=>dir, :file=>File.basename(sub_plists.first), :starred=>false, :new=>false, :page_id=>counter.to_s}
    result_hash[:sections][0][:items]<<new_item
    counter+=1
  end
end

puts Plist::Emit.dump(result_hash)