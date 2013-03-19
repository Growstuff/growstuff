xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "#{Growstuff::Application.config.site_name} - #{@member.login_name}'s recent posts"
    xml.link member_url(@member)

    for post in @posts
      xml.item do
        xml.author @member.login_name
        xml.title post.subject
        xml.description post.body
        xml.pubDate post.created_at.to_s(:rfc822)
        xml.link post_url(post)
        xml.guid post_url(post)
      end
    end
  end
end
