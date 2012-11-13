xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "Growstuff - #{@member.username}'s recent updates"
    xml.link member_url(@member)

    for update in @updates
      xml.item do
        xml.author member.username
        xml.title update.subject
        xml.description update.body
        xml.pubDate update.created_at.to_s(:rfc822)
        xml.link update_url(update)
        xml.guid update_url(update)
      end
    end
  end
end
