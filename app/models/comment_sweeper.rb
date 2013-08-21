class CommentSweeper < ActionController::Caching::Sweeper
  observe Comment

  def after_create(comment)
    expire_fragment('recent_posts')
  end

  def after_update(comment)
  end

  def after_destroy(comment)
    expire_fragment('recent_posts')
  end

end
