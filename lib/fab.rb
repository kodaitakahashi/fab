#!/usr/local/env ruby
#coding:utf-8
require "apikey"
require "json"
require "open-uri"
require "uri"
require 'active_support/all'

module Fab

  class Output

    LINE_BREAK_TEMPLATE = "\n---------------------------"
    
    def echo_book(location , book)
      puts location
      situation_appraisal(book["result"]["books"]["book"]["system"]["libkeys"])
      puts LINE_BREAK_TEMPLATE
    end

    POSSIBLE_TEMPLATE = "貸出可能"
    IMPOSSIBLE_TEMPLATE = "貸出不可"
    NON_BOOK_TEMPLATE = "蔵書無し"
    private
    def situation_appraisal(situation)
      if situation.nil?
        puts NON_BOOK_TEMPLATE
      else
        puts situation["libkey"]
      end
    end
  end
  
  class Find < Output

    def book_set_param(isbn)
      @book_send_param = "http://api.calil.jp/check?"
      @book_send_param << "appkey=#{Fab::Apikey::APIKEY}"
      @book_send_param << "&isbn=#{isbn}"
      @book_send_param << "&format=xml"
    end

    SLEEP_TIME = 5
    def book_get_params()
      count = 0
      @libraries.each_value do | library |
        temp_send_param = @book_send_param+"&systemid=#{library["systemid"]}"
        encode_uri = URI.encode(temp_send_param)
        result = nil
        loop do
          get_xml = open(encode_uri).read
          convert_json = Hash.from_xml(get_xml).to_json
          result = JSON.load(convert_json)
          break if result["result"]["continue"].to_i == 0
          sleep(SLEEP_TIME.to_i)
        end
        echo_book(@libraries[count]["formal"] , result )
        count += 1
      end
    end
  end
  
  class Set < Find
    def initialize()
      @library_send_param = "http://api.calil.jp/library?appkey=#{Fab::Apikey::APIKEY}"
    end
    
    def library_set_param(pref,city)
      @library_send_param << "&pref=#{pref}"
      @library_send_param << "&city=#{city}"
    end

    def library_get_params()
      encode_uri = URI.encode(@library_send_param)
      get_xml = open(encode_uri).read
      convert_json = Hash.from_xml(get_xml).to_json
      result = JSON.load(convert_json)
      @libraries = Hash.new { | h , k | h[k] = {} }
      for i in 0..count_id(result)
        @libraries[i]["systemid"] =  result["Libraries"]["Library"][i]["systemid"]
        @libraries[i]["formal"] = result["Libraries"]["Library"][i]["formal"]
      end
    end
    
    private
    def count_id(target)
      id_count = target.to_s.scan(/sys[a-z]*d/).size - 1
      id_count
    end
  end
end
