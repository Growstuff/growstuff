class PostSweeper < Sweeper
  observe Post

  def after_create(post)
    expire_fragment('recent_posts')
  end

  def after_update(post)
    expire_fragment('recent_posts')
  end

  def after_destroy(post)
    expire_fragment('recent_posts')
  end

end
