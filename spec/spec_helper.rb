require_relative '../lib/guard/xcoder'

RSpec.configure do |config|
  config.color_enabled = true
  config.run_all_when_everything_filtered = true
  
  config.before(:each) do
    ENV["GUARD_ENV"] = 'test'
  end
end
