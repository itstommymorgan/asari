require 'asari'
require 'rspec/its'
require 'simplecov'
SimpleCov.start

RSpec.configure do |config|
  config.mock_with :rspec do |c|
    c.syntax = [:should, :expect]
  end

  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
end
