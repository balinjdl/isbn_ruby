#!/usr/bin/ruby

class Isbn_checker
  def verify_checkDigit(isbn_in, printValids)
    if isbn_in.length == 13
      return verify_checkDigit13(isbn_in.upcase, printValids)
    elsif isbn_in.length == 10
      return verify_checkDigit10(isbn_in.upcase, printValids)
    else
      return nil
    end
  end

  def verify_checkDigit10(isbn_in, printValids)
    retVal = false
    if (isbn_in.length == 10) 
      chkDgtX = calc_checkDigit10(isbn_in[0,isbn_in.length-1])
      #puts "chkDgtX = #{chkDgtX}; isbn_in = #{isbn_in}; isbn(substr) = #{isbn_in[0,isbn_in.length-1]}"
      if isbn_in == isbn_in[0,isbn_in.length-1].to_s + chkDgtX.to_s.upcase
	retVal=true
	if printValids
	  puts "valid check digit found in isbn #{isbn_in}!"
	end
      else
	puts "INVALID check digit in isbn #{isbn_in}!"
      end
    else
      puts "invalid isbn_in length (#{isbn_in.length})"
    end
    retVal
  end
  
  def verify_checkDigit13(isbn_in, printValids)
    retVal = false
    if (isbn_in.length == 13) 
      chkDgt = calc_checkDigit13(isbn_in[0,isbn_in.length-1])
      #puts "chkDgt = #{chkDgt}; isbn_in = #{isbn_in}; isbn(substr) = #{isbn_in[0,isbn_in.length-1]}"
      if isbn_in == isbn_in[0,isbn_in.length-1].to_s + chkDgt.to_s
	retVal=true
	if printValids
	  puts "valid check digit found in isbn #{isbn_in}!"
	end
      else
	puts "INVALID check digit in isbn #{isbn_in}!"
      end
    else
      puts "invalid isbn_in length (#{isbn_in.length})"
    end
    retVal
  end

  def calc_checkDigit(isbn_in)
    if isbn_in.length == 13
      return calc_checkDigit13(isbn_in)
    elsif isbn_in.length == 10
      return calc_checkDigit10(isbn_in)
    else
      return nil
    end
  end
  
  def calc_checkDigit10(isbn_in)
    charPos = 0
    csumTotal = 0
    iarr = isbn_in.split(//)
    for i2 in iarr
      charPos += 1
      csumTotal = csumTotal + (charPos * i2.to_i)
      #puts "csumTotal (running) = #{csumTotal}"
    end
    #puts "csumTotal = #{csumTotal}"
    checkDigit = csumTotal % 11
    if (checkDigit == 10)
      checkDigit = "X"
    end
    #puts "for partial isbn #{isbn_in} the checkDigit = #{checkDigit}; complete isbn = #{isbn_in}#{checkDigit}"
    checkDigit
  end
  
  def calc_checkDigit13(isbn_in)
    charPos = 0
    csumTotal = 0
    iarr = isbn_in.split(//)
    for i1 in iarr
      cP2 = charPos/2.to_f
      #puts "#{cP2}; #{cP2.round}; #{cP2.floor}"
      
      if (cP2.round == cP2.floor)
	csumTotal = csumTotal + i1.to_i
	#puts "csumTotal_a = #{csumTotal} + #{i1.to_i}"
      else
	csumTotal = csumTotal + (3*i1.to_i)
	#puts "csumTotal_b = #{csumTotal} + #{3*i1.to_i}"
      end      
      charPos += 1
    end
      #puts "csumTotal = #{csumTotal}"
      if (csumTotal == (csumTotal/10.to_i)*10)
	checkDigit = "0"
      else
	checkDigit = 10-(csumTotal - (csumTotal/10.to_i)*10)
      end
      
      #puts "checkDigit = 10-(#{csumTotal} - #{(csumTotal/10.to_i)*10})"
      if (checkDigit == 10)
	checkDigit = "X"
      end
      #puts "for partial isbn #{isbn_in} the checkDigit = #{checkDigit}; complete isbn = #{isbn_in}#{checkDigit}"
      checkDigit
  end
  
  def fix_isbn(isbn)  
    return isbn[0,isbn.length-1] + calc_checkDigit(isbn).to_s
  end
  
  def check_isbnFile(filename)
    isbns_checked = isbns_valid = isbns_invalid = 0
    
    File.open(filename, "r") do |f|
      f.each { |isbn|
        isbn = isbn.chomp
	if verify_checkDigit(isbn, false) == false
	  puts "#{isbn} is invalid; proper ISBN should be " + fix_isbn(isbn)
          isbns_invalid +=1
        else
	  isbns_valid+=1
        end
        isbns_checked += 1
      }
    end
    puts "checked #{isbns_checked} isbns; #{isbns_invalid} invalid (#{(isbns_invalid/isbns_checked)*100.round}%) & #{isbns_valid} valid (#{(isbns_valid/isbns_checked)*100.round}%)"
  end
  
  def initialize()
  end
  
  def new
  end
end

i1 = Isbn_checker.new
#puts i1.calc_checkDigit("978159995168")
#i1.verify_checkDigit("9781599951683")
#i1.verify_checkDigit("9780802825285")

#i1.check_isbnFile("~/isbn-list.txt")
