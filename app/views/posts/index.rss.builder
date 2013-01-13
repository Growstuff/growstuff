xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "Growstuff - Recent posts from all members"
    xml.link posts_url

    for post in @recent_posts
      xml.item do
        xml.author post.member.login_name
        xml.title post.subject
        xml.description post.body
        xml.pubDate post.created_at.to_s(:rfc822)
        xml.link post_url(post)
        xml.guid post_url(post)
      end
    end
  end
end
