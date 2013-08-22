class ForumSweeper < ActionController::Caching::Sweeper
  observe Forum

  def after_create(forum)
    expire_fragment('homepage_forums')
  end

  def after_update(forum)
    expire_fragment('homepage_forums')
  end

  def after_destroy(forum)
    expire_fragment('homepage_forums')
  end

end
