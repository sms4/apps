# encoding: utf-8
class CommentsController < ApplicationController
  def index
    @app = App.find(params[:app_id])
    authorize! :show, App

    @comments = Kaminari::paginate_array(@app.comments.common.order('created_at DESC')).
      page(params[:page]).per(comments_per_page)

    respond_to do |format|
      format.js
    end
  end

  def show
    @comment = Comment.includes(:answers).find(params[:id])
    authorize! :show, @comment

    respond_to do |format|
      format.js
    end
  end

  def create
    @app = App.find(params[:app_id])
    @comment = Comment.new(params[:comment].
      merge(author: User.find(params[:comment][:author])))
    @comment.app = @app

    authorize! :create, @comment
    authorize! :manage, @comment.author

    if params[:comment_id]
      Comment.find(params[:comment_id]).answers << @comment
    else
      @app.comments << @comment
    end

    redirect_to app_path(@app)
  end

  def destroy
    @comment = Comment.find(params[:id])
    authorize! :destroy, @comment

    @comment.destroy
    redirect_to app_path(App.find(params[:app_id]))
  end

  private

  def comments_per_page
    ReduApps::Application.config.comments_per_page
  end
end
