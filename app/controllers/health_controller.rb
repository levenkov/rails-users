class HealthController < ApplicationController
  skip_before_action :authenticate_user!, if: :devise_controller?, raise: false

  def show
    render json: { status: 'ok', time: Time.current }
  end
end
