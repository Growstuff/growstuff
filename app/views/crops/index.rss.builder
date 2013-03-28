xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "#{Growstuff::Application.config.site_name} - Recently added crops"
    xml.link crops_url

    for crop in @new_crops
      xml.item do
        xml.title crop.system_name
        xml.pubDate crop.created_at.to_s(:rfc822)
        xml.link crop_url(crop)
        xml.guid crop_url(crop)
      end
    end
  end
end
