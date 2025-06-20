# EZLogs Rails Application - Setup Guide

## Prerequisites

- Ruby 3.4.2 or higher
- PostgreSQL 14 or higher
- Redis 6 or higher
- Node.js 18 or higher
- Docker (optional, for containerized deployment)

## Quick Start

### 1. Clone and Setup

```bash
git clone <repository-url>
cd ez_logs
bundle install
```

### 2. Database Setup

```bash
# Create and setup database
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:seed
```

### 3. Environment Configuration

Copy the example configuration and update with your values:

```bash
cp config/application.yml.example config/application.yml
```

Update the following key settings in `config/application.yml`:

- Database connection details
- Redis configuration
- AI service API keys (OpenAI, Anthropic)
- Security settings
- Email configuration

### 4. Start the Application

```bash
# Development mode with all services
bin/dev

# Or start individual services
bundle exec rails server
bundle exec sidekiq
bundle exec rails tailwindcss:watch
```

## Development Environment

### Required Services

1. **PostgreSQL**: Main application database
2. **Redis**: Background jobs, caching, and sessions
3. **Sidekiq**: Background job processing
4. **Tailwind CSS**: Asset compilation

### Configuration Files

- `config/application.yml`: Environment-specific settings
- `config/database.yml`: Database configuration
- `config/redis.yml`: Redis configuration
- `config/sidekiq.yml`: Background job configuration

### Development Tools

- **RSpec**: Testing framework
- **FactoryBot**: Test data factories
- **SimpleCov**: Code coverage
- **VCR**: External API testing
- **Devise**: Authentication
- **Pundit**: Authorization

## Production Deployment

### Using Kamal (Recommended)

```bash
# Deploy to production
kamal deploy

# Rollback if needed
kamal rollback
```

### Manual Deployment

1. Set production environment variables
2. Run database migrations
3. Precompile assets
4. Start application servers

## Troubleshooting

### Common Issues

1. **Database Connection**: Ensure PostgreSQL is running and accessible
2. **Redis Connection**: Verify Redis server is running
3. **Asset Compilation**: Run `bundle exec rails assets:precompile`
4. **Background Jobs**: Check Sidekiq logs for job failures

### Logs

- Application logs: `log/development.log`
- Sidekiq logs: `log/sidekiq.log`
- Test logs: `log/test.log`

## Next Steps

After setup, proceed to:

1. [Authentication Setup](AUTHENTICATION.md)
2. [API Documentation](API.md)
3. [Security Guidelines](SECURITY.md)
4. [Performance Tuning](PERFORMANCE.md) 