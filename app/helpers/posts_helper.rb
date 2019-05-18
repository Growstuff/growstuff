module PostsHelper
  def display_post_truncated(post)
    length = 300
    return truncate(strip_tags(post.body), length: length, separator: ' ', omission: '... ') { link_to "Read more", post_path(post) }
  end

  def post_byline(post)
    byline = 'Posted by '

    if post.author
      byline += link_to post.author.login_name, member_path(post.author)
    else
      byline += 'Member Deleted'
    end

    if post.forum
      byline += ' in '
      byline += link_to post.forum, post.forum
    end

    byline += " on #{post.created_at}"

    byline += " and edited at #{post.updated_at}" if post.updated_at > post.created_at

    byline.html_safe
  end
end
