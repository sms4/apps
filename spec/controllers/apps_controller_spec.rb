# encoding: utf-8
require 'spec_helper'

describe AppsController do

  describe "GET index" do

    context "when assigning variables" do
      before do
        get :index , locale: 'pt-BR'
      end

      it "assigns @apps variable" do
        assigns(:apps).should == App.all
      end

      it "assigns @categories variable" do
        assigns(:categories).should == Category.all
      end
    end

    context "when filtering app by category" do
      before(:each) do
        @categories = (0..3).collect {|i| Category.create(name: "Cat #{i}")}
        @apps = 10.times.collect do |i|
          app = FactoryGirl.create(:app)
          app.categories << @categories.sample(rand(4))
          app
        end
      end

      xit "should return correct number of apps" do
        get :index , filter: [@categories.first.name], locale: 'pt-BR'
        correct_number = @apps.select {|a| a.categories.include?(@categories.first) }.length
        assigns(:apps).length.should == correct_number
      end

      xit "should return corret type of apps" do
        get :index, filter: [@categories.first.name], locale: 'pt-BR'
        assigns(:apps).all? {|a| a.categories.include?(@categories.first)}.should == true
      end
    end

    context "when searching" do

      it "should call search method" do
        search_method = App.method(:search)
        App.should_receive(:search).once do
          search_method.call
        end

        get :index, search: "isto é uma query", locale: 'pt-BR'
      end
    end
  end

  describe "GET show" do
    before do
       @app = FactoryGirl.create(:complete_app_with_comments)
    end

    context "with valid params" do
      before do
        @params = { id: @app.id, locale: 'pt-BR' }
      end

      it "increments app views counter" do
        visualizations = @app.views
        get :show, @params
        App.find(@app.id).views.should == visualizations + 1
      end

      it "assigns the proper app" do
        get :show, @params
        assigns(:app).should == App.find(@params[:id])
      end

      it "assigns app reputation for rating" do
        get :show, @params
        assigns(:app_rating).should == @app.reputation_for(:rating)
      end

      it "assigns app evaluations" do
        get :show, @params
        assigns(:evaluations).should == @app.evaluators_for(:rating).count
      end

      it "assigns common comments" do
        get :show, @params
        assigns(:common_comments).should == @app.comments.common
      end

      it "assigns specialized comments" do
        get :show, @params
        assigns(:specialized_comments).should == @app.comments.specialized
      end

      context "when user is logged in" do
        before do
          @user = FactoryGirl.create(:user)
          controller.stub(current_user: @user)
        end

        it "assigns a bool which indicates wheter the user has rated" do
          get :show, @params
          assigns(:evaluated).should_not be_nil
        end

        context "and has rated the app" do
          before do
            another_user = FactoryGirl.create(:user)
            @user_rating = 5
            @app.add_evaluation(:rating, 1, another_user)
            @app.add_evaluation(:rating, @user_rating, @user)
            get :show, @params
          end

          it "assigns evaluated true" do
            assigns(:evaluated).should be_true
          end

          it "assigns evaluation value" do
            assigns(:user_rating).should == @user_rating
          end
        end

        context "and has'nt rated the app" do
          it "assigns evaluated false" do
            assigns(:evaluated).should be_false
          end

          it "does not assign evaluation value" do
            assigns(:user_rating).should be_nil
          end
        end # context "and has'nt rated the app"
      end # context "when user is logged in"
    end # context "with valid params"
  end # describe "GET show"

  describe "POST rate" do
    before do
      @app = FactoryGirl.create(:app)
      @user = FactoryGirl.create(:user)
      request.env["HTTP_REFERER"] = app_path(@app)
      controller.stub(current_user: @user)
    end

    context "with valid params" do
      before do
        @params = { id: @app, rating: 5, locale: 'pt-BR' }
      end

      it "should respond with 200 status code" do
        xhr :post, :rate, @params
        expect(response.code).to eq("200")
      end

      context "when assigning variables" do
        before { post :rate, @params }

        it "assigns app variable" do
          assigns(:app).should == @app
        end

        it "assigns user rating variable" do
          assigns(:user_rating).should == 5
        end

        it "assigns app rating variable" do
          assigns(:app_rating).should == @app.reputation_for(:rating)
        end

        it "assigns evaluated variable" do
          assigns(:evaluated).should == true
        end

        it "assigns evaluations variable" do
          assigns(:evaluations).should == @app.evaluators_for(:rating).count
        end
      end

      context "when user hasn't rated before" do
        it "should create a new reputation value" do
          expect {
            post :rate, @params
          }.to change(ReputationSystem::Reputation, :count).by(1)
        end
      end

      context "when user has rated before" do
        before do
          @app.add_evaluation(:rating, @params[:rating]-1, @user)
        end

        it "should not create a new reputation value" do
          expect {
            post :rate, @params
          }.to change(ReputationSystem::Reputation, :count).by(0)
        end

        it "should update reputation value" do
          post :rate, @params
          @app.reputation_for(:rating, nil, @user).should == @params[:rating]
        end
      end # context "when user has rated before"
    end # context "with valid params"

    context "with invalid rating values" do
      [-50, -5, -1, 0, 6, 7, 10, 50].each do |invalid_value|
        it_should_behave_like "a hater of rating cheaters", invalid_value
      end
    end # context "with invalid rating values"
  end # describe "POST rate"
end
