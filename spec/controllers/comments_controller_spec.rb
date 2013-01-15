# encoding: utf-8
require 'spec_helper'

describe CommentsController do
  describe "GET index" do
    before do
      @app = FactoryGirl.create(:app)
      @comment = FactoryGirl.create(:common_comment)
      @app.comments << @comment
    end

    it "should assign comment" do
      get :index, { app_id: @app, comment_id: @comment, locale: 'pt-BR' }
      assigns(:comment).should == @comment
    end
  end

  describe "POST create" do
    before do
      @app = FactoryGirl.create(:app)
      @user = FactoryGirl.create(:member)
      controller.stub(current_user: @user)
    end

    context "when creating a comment" do
      before do
        request.env["HTTP_REFERER"] = app_path @app
        @params = { app_id: @app, comment: {
            author: @user.id, body: "Olá! Parabéns pelo REA." },
            locale: 'pt-BR'
          }
      end

      context "with valid params" do
        it 'should create a new comment' do
          expect {
            post :create, @params
          }.to change(Comment, :count).by(1)
        end

        it 'should create a new common comment' do # common is the default type
          expect {
            post :create, @params
          }.to change(Comment.common, :count).by(1)
        end

        it 'should associate new comment with proper app' do
          expect {
            post :create, @params
          }.to change(@app.comments, :count).by(1)
        end

        it 'should associate new comment with proper user' do
          expect {
            post :create, @params
          }.to change(@user.comments, :count).by(1)
        end

        it 'should assign app' do
          post :create, @params
          assigns(:app).should == @app
        end

        it 'should assign comment' do
          post :create, @params
          assigns(:comment).should_not be_nil
        end

        it 'should assign comment with proper author' do
          post :create, @params
          assigns(:comment).author.should == @user
        end

        it 'should assign comment with proper body' do
          post :create, @params
          assigns(:comment).body.should == @params[:comment][:body]
        end

        context "which is common" do
          before do
            @params[:comment] = @params[:comment].merge(type: :common)
          end

          it 'should create a new common comment' do
            expect {
              post :create, @params
            }.to change(Comment.common, :count).by(1)
          end

          it 'should not create a new specialized comment' do
            expect {
              post :create, @params
            }.to_not change(Comment.specialized, :count).by(1)
          end
        end # "which is common"

        context "which is specialized" do
          before do
            @user = FactoryGirl.create(:specialist)
            @params[:comment] = @params[:comment].merge(type: :specialized)
          end

          it 'should create a new specialized comment' do
            expect {
              post :create, @params
            }.to change(Comment.specialized, :count).by(1)
          end

          it 'should not create a new common comment' do
            expect {
              post :create, @params
            }.to_not change(Comment.common, :count).by(1)
          end
        end # context "which is specialized"

        context "which is an answer" do
          before do
            @comment = FactoryGirl.create(:common_comment, app: @app)
            @params = @params.merge(comment_id: @comment)
          end

          it 'should create a new answer for proper comment' do
            expect {
              post :create, @params
            }.to change(@comment.answers, :count).by(1)
          end
        end # context "which is an answer"
      end # context "with valid params"
    end # context "when creating a comment"
  end

  describe "DELETE destroy" do

    context "when deleting a comment" do

      context "with valid params" do
        before do
          @app = FactoryGirl.create(:app)
          @user = FactoryGirl.create(:specialist)
          controller.stub(current_user: @user)
          @comment = FactoryGirl.create(:specialized_comment, author: @user,
                                        app: @app)
          @params = { app_id: @app.id, id: @comment.id, locale: 'pt-BR'}
        end

        it 'should destroy one comment' do
          expect {
            post :destroy, @params
          }.to change(Comment, :count).by(-1)
        end

        it 'should destroy one comment from proper app' do
          expect {
            post :destroy, @params
          }.to change(@app.comments, :count).by(-1)
        end

        it 'should destroy one comment from proper user' do
          expect {
            post :destroy, @params
          }.to change(@user.comments, :count).by(-1)
        end

        context "which is an answer" do
          before do
            @answer = FactoryGirl.create(:comment, app: @app,
                                         author: @user)
            @comment.answers << @answer
            @comment.save
          end

          it 'should destroy answer for proper comment' do
            expect {
              post :destroy, @params.merge(comment_id: @comment.id,
                                           id: @answer.id)
            }.to change(@comment.answers, :count).by(-1)
          end
        end # context "which is an answer"
      end # context "with valid params"
    end # context "when deleting a comment"
  end
end
