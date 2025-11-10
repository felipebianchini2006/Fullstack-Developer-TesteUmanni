RSpec.configure do |config|
  # Configure Action Cable for testing
  config.include ActionCable::TestHelper

  # Setup for Action Cable broadcasting tests
  config.before(:each, type: :request) do
    # Stub ActionCable.server.broadcast to avoid real broadcasting during tests
  end

  config.after(:each, type: :request) do
    # Cleanup any active connections
  end
end
