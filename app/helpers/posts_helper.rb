# frozen_string_literal: true

module PostsHelper
  def post_stripped_tags(post, length: 300)
    truncate(strip_tags(markdownify(post.body)), length:)
  end
end
