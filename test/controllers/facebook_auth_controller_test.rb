require "test_helper"

class FacebookAuthControllerTest < ActionDispatch::IntegrationTest
  test "should get authorize" do
    get facebook_auth_authorize_url
    assert_response :success
  end

  test "should get callback" do
    get facebook_auth_callback_url
    assert_response :success
  end
end
