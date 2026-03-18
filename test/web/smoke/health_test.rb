require 'test_helper'
require_relative 'concerns/smoke_test_helpers'

class HealthSmokeTest < ActionDispatch::IntegrationTest
  include SmokeTestHelpers
  test 'health check loads without errors' do
    get health_path
    assert_response :success
  end

  test 'rails health check loads without errors' do
    get rails_health_check_path
    assert_response :success
  end
end
