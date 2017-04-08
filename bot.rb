# encoding:utf-8

require 'telegram/bot'
require 'nokogiri'
require 'rest-client'
require_relative './lib/unicorn.rb'

def btkiki_get(str)
    baseurl = "www.btkiki.com/s/"
    url = baseurl + "#{str}.html"
    header = "magnet:?xt=urn:btih:"

    begin
        response = RestClient.get url
    rescue Exception => e
        return "答应我，只搜车牌好不好"
    end

    magnet = String.new
    doc = Nokogiri::HTML(response.body)
    details = doc.search('//div[@class="g"]/h2/a').each do |row|
        magnet << header + row['href'].split("/")[-1][0..-6] + "\n\n"
    end

    return magnet
end

def javlibrary_get(str)
    baseurl = "http://javlibrary.com/cn/vl_searchbyid.php?keyword="
    url = baseurl + str
    begin
        response = RestClient.get url
    rescue RestClient::ExceptionWithResponse => err
        response = err.response.follow_redirection
    end
    doc = Nokogiri::HTML(response.body)
    details, genres, video_genres, video_jacket_img = Array.new, Array.new, String.new, String.new

    doc.search('//div[@id="video_info"]/div[@class="item"]/table/tr/td[@class="text"]').map do |row|
        details << row.children.text
    end

    doc.search('//div[@id="video_genres"]/table/tr/td[@class="text"]/span[@class="genre"]/a').each do |row|
        video_genres << row.children.text << " "
    end

    doc.search('//img[@id="video_jacket_img"]').each do |row|
        video_jacket_img = row['src']
    end

    information = Hash.new
    information['video_info'] =  "ID: #{details[0]}\nDATE: #{details[1]}\nDIRECTOR: #{details[2]}\nMAKER: #{details[3]}\nLABEL: #{details[4]}\nCAST: #{details[-1]}\nGENRES: #{video_genres}"
    information['video_jacket_img'] = video_jacket_img

    return information
end

TOKEN = "343074557:AAHjjNpdWYmmhzm0j4egNeCfUebAPNkvU3k"

Telegram::Bot::Client.run(TOKEN) do |bot|
    handle_thread = Thread.new do
        bot.listen do |message|
            begin
                substr = message.text.split(" ")
                next if substr[0] == nil

                command = substr[0].upcase
                case command
                when '/START'
                    if message.from.first_name != nil
                        bot.api.send_message(chat_id: message.chat.id, text: "Hello,#{message.from.first_name}SiJi")
                    else
                        bot.api.send_message(chat_id: message.chat.id, text: "Hello,welcome to use @ujnlaosijibot")
                    end
                when '/STOP'
                    if message.from.first_name != nil
                        bot.api.send_message(chat_id: message.chat.id, text: "Bye,#{message.from.first_name}")
                    else
                        bot.api.send_message(chat_id: message.chat.id, text: "Bye,maybe see you next time")
                    end
                when '/GET'
                    bot.api.send_chat_action(chat_id: message.chat.id, action: "typing")

                    result = btkiki_get(substr[1])
                    bot.api.send_message(chat_id: message.chat.id, text: "#{result}")
                    bot.api.send_message(chat_id: message.chat.id, text: "你要的车牌太新啦，还没有收录") if result.size == 0
                when '/INFO'
                    next if substr[1] == nil
                    result = javlibrary_get(substr[1])
                    bot.api.send_chat_action(chat_id: message.chat.id, action: "upload_photo")
                    bot.api.send_photo(chat_id: message.chat.id, photo: "#{result['video_jacket_img']}", caption: "#{result['video_info']}")
                end
            rescue Exception => e
                io = File.open("./log/bot_err.log", "a+")
                io << e
                io.close
            end
        end
    end

    begin
        handle_thread.join
    rescue
        retry
    end
end
