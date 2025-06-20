# VCR configuration for external API testing
require "vcr"
require "webmock/rspec"

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Filter out sensitive data
  config.filter_sensitive_data("<API_KEY>") { ENV["AI_API_KEY"] }
  config.filter_sensitive_data("<SECRET_KEY>") { ENV["SECRET_KEY_BASE"] }
  config.filter_sensitive_data("<OPENAI_API_KEY>") { ENV["OPENAI_API_KEY"] }

  # Allow real HTTP connections to localhost for development
  config.allow_http_connections_when_no_cassette = true

  # Record new interactions
  config.default_cassette_options = {
    record: :once,
    match_requests_on: [ :method, :uri, :body ]
  }
end
