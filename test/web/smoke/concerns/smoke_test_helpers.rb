module SmokeTestHelpers
  extend ActiveSupport::Concern

  included do
    include Devise::Test::IntegrationHelpers
  end

  def assert_html_success
    assert_response :success
    assert_html_content_type
  end

  def assert_html_forbidden
    assert_response :forbidden
    assert_html_content_type
  end

  def assert_html_response(status)
    assert_response status
    assert_html_content_type
  end

  private

  def assert_html_content_type
    assert_match /text\/html/, response.content_type
  end
end
