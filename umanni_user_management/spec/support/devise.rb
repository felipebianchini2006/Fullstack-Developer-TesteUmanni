RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::ControllerHelpers, type: :controller

  # Helper to sign in a user in request specs
  config.before(:each, type: :request) do
    @request.env['devise.mapping'] = Devise.mappings[:user]
  end
end
