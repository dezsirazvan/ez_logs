source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.2"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"
# Tailwind CSS for styling [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"

# Authentication and Authorization
gem "devise", "~> 4.9"  # Authentication
gem "pundit", "~> 2.3"  # Authorization
gem "rotp", "~> 6.2"
gem "rqrcode", "~> 2.1"  # QR codes for MFA

# Background Job Processing
gem "sidekiq", "~> 7.2"  # Background job processing
gem "redis", "~> 5.0"    # Redis client

# API and JSON
gem "jsonapi-serializer", "~> 2.2"  # JSON:API serialization
gem "rack-attack", "~> 6.7"         # Rate limiting and security

# Monitoring and Observability
gem "sentry-ruby", "~> 5.17"        # Error tracking
gem "sentry-rails", "~> 5.17"       # Rails integration
gem "sentry-sidekiq", "~> 5.17"     # Sidekiq integration
gem "prometheus-client", "~> 4.0"   # Metrics collection

# AI Integration
gem "httparty", "~> 0.21"           # HTTP client for AI services
gem "ruby-openai", "~> 7.0"         # OpenAI API client

# Security and Validation
gem "strong_password", "~> 0.0.8"   # Password strength validation
gem "lockbox", "~> 1.4"             # Encrypted attributes
gem "blind_index", "~> 2.3"         # Searchable encrypted data

# Performance and Caching
# gem "redis-rails", "~> 5.0"         # Redis session store
gem "hiredis-client", "~> 0.12"     # Fast Redis client
gem "connection_pool", "~> 2.4"     # Connection pooling

# File Processing
gem "image_processing", "~> 1.2"    # Image processing
gem "aws-sdk-s3", "~> 1.0"          # S3 storage (optional)

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# OAuth
gem "omniauth", "~> 2.1"
gem "omniauth-google-oauth2", "~> 1.1"
gem "omniauth-github", "~> 2.0"

# API Authentication
gem "jwt", "~> 2.7"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # Testing framework
  gem "rspec-rails", "~> 7.0"
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.2"
  gem "capybara", "~> 3.40"
  gem "selenium-webdriver", "~> 4.10"
  gem "webdrivers", "~> 5.3"
  gem "database_cleaner-active_record", "~> 2.1"
  gem "vcr", "~> 6.2"
  gem "webmock", "~> 3.19"
  gem "shoulda-matchers", "~> 6.1"
  gem "timecop", "~> 0.9"
  gem "simplecov", "~> 0.22", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Development tools
  # gem "annotate", "~> 3.2"           # Model annotations
  # gem "bullet", "~> 7.1"             # N+1 query detection (incompatible with Rails 8, revisit)
  gem "letter_opener", "~> 1.8"      # Email preview
  gem "better_errors", "~> 2.10"     # Better error pages
  gem "binding_of_caller", "~> 1.0"  # Interactive debugging
  gem "pry-rails", "~> 0.3"          # Enhanced console
  gem "pry-byebug", "~> 3.10"        # Debugging in pry
  gem "pry-stack_explorer", "~> 0.6" # Stack exploration
end
