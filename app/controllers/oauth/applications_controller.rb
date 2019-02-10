class Oauth::ApplicationsController < ApplicationController
  before_action :require_logged_in_user
  before_action :set_application, only: [:show, :edit, :update, :destroy]

  def index
    @applications = @user.oauth_applications
  end

  # only needed if each application must have some owner
  def create
    @application = Doorkeeper::Application.new(application_params)
    if Doorkeeper.configuration.confirm_application_owner?
      @application.owner = @user
    end
    if @application.save
      flash[:notice] = I18n.t(:notice,
                              :scope => [:doorkeeper, :flash, :applications, :create])
      redirect_to oauth_application_url(@application)
    else
      render :new
    end
  end

  # other functions copied from Doorkeeper::ApplicationsController

  def show; end

  def new
    @application = Doorkeeper::Application.new
  end

  def edit; end

  def update
    if @application.update(application_params)
      flash[:notice] = I18n.t(:notice,
                              scope: [:doorkeeper, :flash, :applications, :update])
      redirect_to oauth_application_url(@application)
    else
      render :edit
    end
  end

  def destroy
    if @application.destroy
      flash[:notice] = I18n.t(:notice, scope: [:doorkeeper, :flash,
        :applications, :destroy,])
    end
    redirect_to oauth_applications_url
  end

private

  def set_application
    @application = @user.oauth_applications.find(params[:id])
  end

  def application_params
    params.require(:doorkeeper_application).permit(
      :name, :redirect_uri, :scopes)
  end
end
