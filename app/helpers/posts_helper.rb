# frozen_string_literal: true

module PostsHelper
  def display_post_truncated(post, length: 300)
    truncate(strip_tags(post.body), length: length, separator: ' ', omission: '... ') do
      link_to 'Read more', post_path(post)
    end
  end

  def post_stripped_tags(post, length: 300)
    truncate(strip_tags(post.body), length: length)
  end
end
