# encoding: utf-8

class AppsController < ApplicationController
  helper :formatting

  def index
    if params[:filter] || params[:search]
      @apps = search(params[:filter]).results
      @categories = Category.filter if params[:filter] && !params[:search]
      assign_searching_variables unless !params[:search]
      @apps = Kaminari.paginate_array(@apps).page(params[:page])
    else
      @apps = App.includes(:comments, :categories).
        page(params[:page])
      @categories = Category.filter
    end
    @favorite_apps_count = current_user.apps.count if current_user
    @filter = params.fetch(:filter, [])
    @search = params[:search]

    respond_to do |format|
      format.js {}
      format.html
    end
  end

  def show
    @app = App.find(params[:id])
    @app.update_attribute(:views, @app.views + 1) unless params[:page]
    @app_categories = Category.get_names_by_kind @app
    @comments = Kaminari::paginate_array(@app.comments.common.order('created_at DESC')).
      page(params[:page]).per(10)
    @user = current_user
    @favorite = UserAppAssociation.find_by_user_id_and_app_id(@user,
                                                              @app)
    @evaluations = @app.evaluators_for(:rating).count
    if @user
      @evaluated = @app.has_evaluation?(:rating, @user)
      @user_rating = @app.reputation_for(:rating, nil, @user) if @evaluated
    end

    respond_to do |format|
      format.js
      format.html  # show.html.erb
      format.json  { render :json => @app }
    end
  end

  def preview
    @app = App.find(params[:id])
  end

  def rate
    rating = Integer(params[:rating])
    unless App.is_valid_rating_value? rating
      redirect_to :back, notice: "Valor de classificação inválido." and return
    end
    @app = App.find(params[:id])
    @app.add_or_update_evaluation(:rating, rating, current_user)
    redirect_to :back, notice: "Você classificou o recurso com #{rating}."
  end

  private

  def search(filters = nil)
    App.search(include: [:comments, :categories]) do
      fulltext params[:search] do
        boost_fields :name => 2.0 # Prioridade para itens com o termo no nome
        query_phrase_slop 3 # 3 palavras podem aparecer entre os termos da busca
        phrase_fields :description => 2.0 # Prioriza se aparecer a frase na desc
        phrase_fields :synopsis => 2.0 # Prioriza se aparecer a frase na sinopse
      end
      with(:category_ids, filters) if filters
    end
  end

  def assign_searching_variables
    @results_counter = @apps.total_entries  # Total de hits

    # Conta quantidade de aplicativos por filtro
    @categories = Category.filters_on @apps
    @filters_counter = Category.count_filters_on @categories
    @categories = @categories.uniq # Remove categorias duplicadas
  end
end
