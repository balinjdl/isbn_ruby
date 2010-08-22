#!/usr/bin/ruby
#
# File to fetch cover graphics for a supplied list of ISBNs
#
# Pulls images from openlibrary, google books, and library thing
#
# Only library thing requires registration (see libthing_devkey link below).
#
# Requires Net::HTTP, JSON, and isbn_checker.rb, and config.private.rb
# Only isbn_checker.rb is provided with this file.
#
# A subdirectory for each service must exist inside $cover_dir 
#  -- i.e. $cover_dir/google, $cover_dir/openlib, and $cover_dir/libthing
#
# Author; John D. Lewis < balinjdl - at - gmail - dot - com >
#
# See LICENSE for full license
#

require 'net/http'
require 'json'

# Uncomment the next line to include a custom subdirectory
#   for the isbn_ruby code. Shouldn't be necessary.
#$: << File.join(File.dirname(__FILE__), "./isbn_ruby")

require 'isbn_checker.rb'

# config.private.rb contains the following definitions:
# $libthing_devkey [see http://www.librarything.com/services/keys.php for more info]
# $cover_dir [where the covers will be stored] (e.g. "/home/user/covers/")

require 'config.private.rb'

gif_1pixel_filesize = 43
$error_msg = ""

def fetch_covers(filename)
  i1 = Isbn_checker.new
  isbns_invalid = isbns_valid = isbns_checked = 0
  File.open(filename, "r") do |f|
    f.each { |isbn|
      isbn = isbn.chomp
	    
      if i1.verify_checkDigit(isbn, false) == false
        $log.puts("ISBN Check\tInvalid\t#{isbn}\tFixed=" + i1.fix_isbn(isbn))
        isbn = i1.fix_isbn(isbn)
	isbns_invalid +=1
      else
        $log.puts("ISBN Check\tValid\t#{isbn}")
	isbns_valid+=1
      end

      get_libthing_cover(isbn)
      get_openlib_cover(isbn)
      get_google_cover(isbn)
	
      put "."
           
      isbns_checked += 1

      $log.puts("Done\tSummary\t\t\##{isbns_checked} == #{isbns_invalid} invalid + #{isbns_valid} valid")
           
      sleep(1)
    }
  end
  puts "Done."
end

def get_libthing_cover(isbn)
  libthing_base = "covers.librarything.com"
  libthing_filename = "#{$cover_dir}/libthing/#{isbn}.cover.jpg"

  Net::HTTP.start(libthing_base) do |libthing|
    resp = libthing.get("/devkey/#{$libthing_devkey}/large/isbn/#{isbn}")
    open(libthing_filename, "wb") do |libthing_cover|
      libthing_cover.write(resp.body)
    end
    
    # Delete the file if it's a 1x1 pixel GIF (43 bytes in size)
    if File.size(libthing_filename) == 43
      File.delete(libthing_filename)
      $error_msg = "LibraryThing\tFailed\t#{isbn}\tNo cover image"
      $error_log.puts($error_msg)
    else
      $log.puts("Library Thing\tFetched #{isbn}")
    end
  end
end

def get_openlib_cover(isbn)
  # See http://openlibrary.org/dev/docs/api/covers for the spec
  openlib_base = "covers.openlibrary.org"
  openlibpart2 = "/b/ISBN/#{isbn}-L.jpg"

  response = Net::HTTP.get_response(URI.parse("http://#{openlib_base}/b/ISBN/#{isbn}-L.jpg"))
  case response
  when Net::HTTPSuccess then 
    $error_msg = "OpenLibrary\tFailed\t#{isbn}\tNo cover image"
    $error_log.puts($error_msg)
  when Net::HTTPRedirection then
    url = URI.parse(response['location'])
    Net::HTTP.start(url.host) do |openlib|
      resp = openlib.get(url.path)
      open("#{$cover_dir}/openlib/#{isbn}.jpg", "wb") do |openlib_cover|
	openlib_cover.write(resp.body)
      end
      $log.puts("Open Library\tFetched\t#{isbn}")
    end
  end
  
end

def get_google_cover(isbn)
  google_base = "books.google.com"

  #1. Get JSON code
  json_base = "/books?bibkeys=ISBN:#{isbn}&jscmd=viewapi"
  
  Net::HTTP.start(google_base) do |google|
    #2. Get real URL (from JSON response)
    
    #puts "fetching JSON from #{google_base}#{json_base}"
    resp,data = google.get(json_base)
    if data.length > 23
      #puts "data = #{data}"
      
      jdata = JSON.parse(data[19,data.length-20])
      groot = jdata["ISBN:#{isbn}"]
      
      if groot != nil then
	gurl = jdata["ISBN:#{isbn}"]['thumbnail_url']
	
	# If there's no thumbnail_url, gurl is empty/nil
	if gurl != nil then
	  
	  # Get a larger cover image
	  gurl["zoom=5"] = "zoom=1"
	  
	  urlg = URI.parse(gurl)
	  hostg = urlg.host
	  
	  #3. Get the real image (finally!)
	  Net::HTTP.start(hostg) do |google_cover_url|
	    #puts "mashup = " + urlg.path + "?" + urlg.query
	    resp_img, data_img = google_cover_url.get(urlg.path + "?" + urlg.query)
	    open("#{$cover_dir}/google/#{isbn}.jpg", "wb") do |google_cover_img|
	      google_cover_img.write(data_img)
	    end
	    $log.puts("Google\tFetched\t#{isbn}")
	  end
	else
	  $error_msg = "Google\tFailed\t#{isbn}\tNo record"
	  $error_log.puts($error_msg)
	end
      else
	  $error_msg = "Google\tFailed\t#{isbn}\tNo JSON data"
	  $error_log.puts($error_msg)
      end
    end
  end
end

puts 
puts "Configuration: "
puts "\tlibthing_devkey = #{$libthing_devkey}"
puts "\tcover_dir = #{$cover_dir}"

open("#{$cover_dir}/error.log", "a") do |$error_log|
  open("#{$cover_dir}/get_cover.log", "a") do |$log|
    fetch_covers("isbns-small.private.txt")
  end
end
