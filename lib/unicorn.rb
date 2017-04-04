# encoding:utf-8

module Unicorn
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

    module_function :btkiki_get
end
