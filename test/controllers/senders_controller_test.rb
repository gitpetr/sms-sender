require 'test_helper'

class SendersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get senders_index_url
    assert_response :success
  end

end
