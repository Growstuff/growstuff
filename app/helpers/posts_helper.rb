module PostsHelper
  def display_post_truncated(post)
    length = 300
    truncate(post.body, length: length, separator: ' ', omission: '... ') { link_to "Read more", post_path(post) }
  end
end
