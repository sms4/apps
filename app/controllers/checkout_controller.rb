# encoding: utf-8
class CheckoutController < ApplicationController
  respond_to :js

  rescue_from ActiveResource::UnauthorizedAccess, with: :unauthorized
  rescue_from ActiveResource::BadRequest, with: :bad_request
  rescue_from Patron::ConnectionFailed, with: :connection_failed
  rescue_from Patron::TimeoutError, with: :connection_failed

  def update
    raise ActiveRecord::RecordNotFound unless App.find(params[:app_id])
    authorize! :checkout, App

    @app_id = params[:app_id]
    @app = App.find_by_id(@app_id)
    case params[:step]
    when '1'
      step_1
    when '2'
      step_2
    when '3'
      step_3
    when '4'
      step_4
    else
      step_1
    end
  end

  protected

  def step_1
    get_params([:previous_step], params)
    @environments = Environment.with_admin_permission(current_user)
    @next_step = 2

    respond_to do |format|
      format.js
    end
  end

  def step_2
    get_params([:space_id, :previous_step], params)
    @space = Space.find_by_id(@space_id)
    @next_step = 3

    respond_to do |format|
      format.js
    end
  end

  def step_3
    get_params([:space_id, :previous_step, :create_subject], params)
    @space = Space.find_by_id(@space_id)
    @next_step = 4

    respond_to do |format|
      format.js
    end
  end

  def step_4
    get_params([:space_id, :create_subject, :lecture, :subject], params)
    @next_step = 4
    @space = Space.find_by_id(@space_id)
    @subject = @create_subject == 'true' ? create_subject_via_api(@space_id, @subject) : Subject.find(@subject)
    @lecture_href = create_lecture_via_api(@subject, @lecture)

    respond_to do |format|
      format.js
    end
  end

  def get_params(expected_params, params)
    expected_params.each do |p|
      self.instance_variable_set("@#{p}",
                                 params.fetch(p) { raise "Invalid State" })
    end
  end

  def create_subject_via_api(space_id, subject_name)
    space = Space.find(space_id)
    auth_subject = Subject.new
    auth_subject.space = space

    authorize! :create, auth_subject

    Subject.create_via_api(space_sid: space.core_id,
                           subject: subject_name, token: current_user.token)
  end

  def create_lecture_via_api(subject, lecture_name)
    auth_lecture = Lecture.new
    auth_lecture.subject = subject

    authorize! :create, auth_lecture

    Lecture.create_via_api(lecture: lecture_name, aid: @app.aid,
                           subject_suid: subject.core_id,
                           token: current_user.token)
  end

  private

  def unauthorized
    flash[:error] = "Você não está autorizado a adicionar o aplicativo a esta disciplina."

    respond_to do |format|
      format.js
    end
  end

  def bad_request
    flash[:error] = "Por favor, verifique os campos preenchidos."

    respond_to do |format|
      format.js
    end
  end

  def connection_failed
    flash[:error] = "Não foi possível adicionar à disciplina. Por favor, cheque sua conexão."

    respond_to do |format|
      format.js
    end
  end
end
