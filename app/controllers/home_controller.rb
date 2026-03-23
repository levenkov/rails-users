class HomeController < ApplicationController
  before_action :authenticate_user!

  def show
    redirect_to notes_path
  end
end
