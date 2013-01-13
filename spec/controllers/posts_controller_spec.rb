require 'spec_helper'

describe PostsController do

  login_member

  # This should return the minimal set of attributes required to create a valid
  # Post. As you add validations to Post, be sure to
  # update the return value of this method accordingly.
  def valid_attributes
    { :author_id => 1, :subject => "blah", :body => "blah blah" }
  end

  # The parameters required to be passed to a Web request.
  def valid_web_attributes
    { :subject => "blah", :body => "blah blah" }
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # PostsController. Be sure to keep this updated too.
  def valid_session
    { }
  end

  describe "GET index" do
    it "assigns all posts as @posts" do
      post = Post.create! valid_attributes
      get :index, {}
      assigns(:posts).should eq([post])
    end
  end

  describe "GET RSS feed" do
    it "returns an RSS feed" do
      get :index, :format => "rss"
      response.should be_success
      response.should render_template("posts/index")
      response.content_type.should eq("application/rss+xml")
    end
  end

  describe "GET show" do
    it "assigns the requested post as @post" do
      post = Post.create! valid_attributes
      get :show, {:id => post.slug}
      assigns(:post).should eq(post)
    end
  end

  describe "GET new" do
    it "assigns a new post as @post" do
      get :new, {}
      assigns(:post).should be_a_new(Post)
    end
  end

  describe "GET edit" do
    it "assigns the requested post as @post" do
      post = Post.create! valid_attributes
      get :edit, {:id => post.slug}
      assigns(:post).should eq(post)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Post" do
        expect {
          post :create, {:post => valid_web_attributes}
        }.to change(Post, :count).by(1)
      end

      it "assigns a newly created post as @post" do
        post :create, {:post => valid_web_attributes}
        assigns(:post).should be_a(Post)
        assigns(:post).should be_persisted
      end

      it "redirects to the created post" do
        post :create, {:post => valid_web_attributes}
        response.should redirect_to(Post.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved post as @post" do
        # Trigger the behavior that occurs when invalid params are submitted
        Post.any_instance.stub(:save).and_return(false)
        post :create, {:post => {}}
        assigns(:post).should be_a_new(Post)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        Post.any_instance.stub(:save).and_return(false)
        post :create, {:post => {}}
        response.should render_template("new")
      end
    end
  end

  describe "PUT post" do
    describe "with valid params" do
      it "updates the requested post" do
        post = Post.create! valid_attributes
        # Assuming there are no other posts in the database, this
        # specifies that the Post created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        Post.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, {:id => post.slug, :post => {'these' => 'params'}}
      end

      it "assigns the requested post as @post" do
        post = Post.create! valid_attributes
        put :update, {:id => post.slug, :post => valid_attributes}
        assigns(:post).should eq(post)
      end

      it "redirects to the post" do
        post = Post.create! valid_attributes
        put :update, {:id => post.slug, :post => valid_attributes}
        response.should redirect_to(post)
      end
    end

    describe "with invalid params" do
      it "assigns the post as @post" do
        post = Post.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Post.any_instance.stub(:save).and_return(false)
        put :update, {:id => post.slug, :post => {}}
        assigns(:post).should eq(post)
      end

      it "re-renders the 'edit' template" do
        post = Post.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Post.any_instance.stub(:save).and_return(false)
        put :update, {:id => post.slug, :post => {}}
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested post" do
      post = Post.create! valid_attributes
      expect {
        delete :destroy, {:id => post.slug}
      }.to change(Post, :count).by(-1)
    end

    it "redirects to the posts list" do
      post = Post.create! valid_attributes
      delete :destroy, {:id => post.slug}
      response.should redirect_to(posts_url)
    end
  end

end
