xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "Growstuff Member Updates"
    xml.description "Recent updates from Growstuff members"
    xml.link updates_url

    for update in @recent_updates
      xml.item do
        xml.author update.user.username
        xml.title update.subject
        xml.description update.body
        xml.pubDate update.created_at.to_s(:rfc822)
        xml.link update_url(update)
        xml.guid update_url(update)
      end
    end
  end
end
