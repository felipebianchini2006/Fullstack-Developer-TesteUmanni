require 'pundit/rspec'

RSpec.configure do |config|
  config.include Pundit::Matchers, type: :policy
end

# Custom matchers for Pundit policies
RSpec::Matchers.define :permit do |action|
  match do |policy|
    policy.public_send("#{action}?")
  end

  failure_message do |policy|
    "#{policy.class} does not permit #{action} on #{policy.record.inspect} for #{policy.user.inspect}"
  end
end

RSpec::Matchers.define :forbid do |action|
  match do |policy|
    !policy.public_send("#{action}?")
  end

  failure_message do |policy|
    "#{policy.class} permits #{action} on #{policy.record.inspect} for #{policy.user.inspect}"
  end
end
