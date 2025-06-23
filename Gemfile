source "https://rubygems.org"

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.4.2"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.2"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder", "~> 2.11"

# Tailwind CSS for styling [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"

# Import maps for JavaScript [https://github.com/rails/importmap-rails]
gem "importmap-rails"

# Use Redis adapter to run Action Cable in production
gem "redis", "~> 5.0"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# and associated library.
#
# Uncomment the following line if you're running Rails
# on a native Windows system:
# gem "tzinfo", ">= 1", "< 3"

gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Authentication
gem "devise", "~> 4.9"
gem "rotp", "~> 6.2" # For TOTP-based 2FA

# Authorization
gem "pundit", "~> 2.3"

# Background Jobs
gem "sidekiq", "~> 7.2"

# API
gem "rack-cors", "~> 2.0"

# Monitoring and Logging
gem "lograge", "~> 0.12"
gem "sentry-ruby", "~> 5.17"
gem "sentry-rails", "~> 5.17"

# Security
gem "brakeman", "~> 6.1", require: false
gem "bundler-audit", "~> 0.9", require: false

# Development and Testing
group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  gem "rspec-rails", "~> 6.1"
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.2"
  gem "shoulda-matchers", "~> 5.3"
  gem "simplecov", "~> 0.22", require: false
  gem "vcr", "~> 6.2"
  gem "webmock", "~> 3.19"
  gem "timecop", "~> 0.9"
  gem "database_cleaner-active_record", "~> 2.1"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Better error pages
  gem "better_errors", "~> 2.10"
  gem "binding_of_caller", "~> 1.0"

  # Code quality
  gem "rubocop", "~> 1.56", require: false
  gem "rubocop-rails", "~> 2.20", require: false
  gem "rubocop-rspec", "~> 2.24", require: false

  # Performance monitoring
  gem "rack-mini-profiler", "~> 4.0"
  gem "memory_profiler", "~> 1.0"

  # Development utilities
  gem "pry-rails", "~> 0.3"
  gem "pry-byebug", "~> 3.10"
  gem "awesome_print", "~> 1.9"
end

group :test do
  gem "capybara", "~> 3.40"
  gem "selenium-webdriver", "~> 4.10"
  gem "webdrivers", "~> 5.3"
  gem "rspec-sidekiq", "~> 4.1"
  gem "rails-controller-testing", "~> 1.0"
end

# Performance monitoring libraries
gem "skylight", "~> 5.3"

# Pagination
gem "kaminari", "~> 1.2"

# Search
gem "ransack", "~> 4.1"

# Charts and graphs
gem "chartkick", "~> 5.0"
gem "groupdate", "~> 6.5"

# Rate limiting
gem "rack-attack", "~> 6.6"

# Health checks
gem "health_check", "~> 3.1"

# Feature flags
gem "flipper", "~> 0.25"
gem "flipper-ui", "~> 0.25"

# Background job monitoring
gem "sidekiq-failures", "~> 1.0"


# Testing utilities
gem "database_cleaner", "~> 2.0"
gem "email_spec", "~> 2.2"
gem "launchy", "~> 2.5"

# CSV support for exports
gem "csv", "~> 3.2"
