class Api::UsersController < ApplicationController
  before_action :authenticate_user!

  def search
    authorize User, :search?

    query = params[:q].to_s.strip
    if query.blank?
      render json: []
      return
    end

    search_term = "%#{query}%"
    users = User.where(disabled: [ nil, false ])
                .where('name ILIKE ? OR email ILIKE ?', search_term, search_term)
                .order(:name)
                .limit(10)

    render json: users.map { |u| { id: u.id, name: u.name, email: u.email } }
  end
end
