xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "Growstuff - Recent plantings from all members"
    xml.link plantings_url

    for planting in @recent_plantings
      xml.item do
        xml.author planting.owner.login_name
        xml.title planting.crop.system_name
        xml.pubDate planting.created_at.to_s(:rfc822)
        xml.description planting.description
        xml.link planting_url(planting)
        xml.guid planting_url(planting)
      end
    end
  end
end
