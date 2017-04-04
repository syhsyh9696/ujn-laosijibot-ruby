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
