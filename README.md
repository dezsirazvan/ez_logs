# EZLogs Rails Application

A production-grade web dashboard for monitoring, managing, and analyzing events from the EZLogs ecosystem. Built with Rails 8, featuring AI-powered event translation, intelligent grouping, and real-time analytics.

## 🎯 Purpose

This application serves as the central dashboard for the EZLogs event monitoring system, providing:

- **Real-time Event Monitoring**: Live view of events from Rails applications via the Go Agent
- **AI-Powered Insights**: GPT integration for intelligent event translation and grouping
- **User Management**: Multi-factor authentication and role-based access control
- **Analytics & Reporting**: Comprehensive dashboards and custom reports
- **Alerting System**: Configurable alerts and notifications
- **API Access**: RESTful API for integrations and automation

## 🏗️ Architecture

```
Rails Apps (Ruby Agent) → Go Agent → EZLogs Rails App → AI Services
                                    ↓
                              Database + Redis
```

## 🚀 Quick Start

### Prerequisites

- Ruby 3.3+
- PostgreSQL 14+
- Redis 6+
- Node.js 18+ (for asset compilation)

### Installation

1. **Clone and setup**
   ```bash
   git clone <repository-url>
   cd ez_logs
   bundle install
   ```

2. **Database setup**
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

3. **Environment configuration**
   ```bash
   cp config/application.yml.example config/application.yml
   # Edit config/application.yml with your settings
   ```

4. **Start the application**
   ```bash
   bin/dev
   ```

5. **Access the application**
   - Open http://localhost:3000
   - Login with default admin credentials (see seeds)

## 🔧 Development

### Development Workflow

1. **Start with tests** - Follow TDD approach
   ```bash
   bundle exec rspec
   ```

2. **Code quality checks**
   ```bash
   bundle exec rubocop
   bundle exec brakeman
   ```

3. **Database changes**
   ```bash
   rails generate migration AddNewFeature
   rails db:migrate
   rails db:rollback  # Test rollback
   ```

### Key Commands

```bash
# Run tests
bundle exec rspec

# Start development server
bin/dev

# Console access
bin/rails console

# Database reset
rails db:reset

# Check security
bundle exec brakeman

# Code formatting
bundle exec rubocop -a
```

### Task Management

This project uses AI-assisted development with structured tasks:

```bash
# View current tasks
ls ai_tasks/active/

# Mark task as complete
bin/terminate_task <task-number>
```

## 🏛️ Project Structure

```
app/
├── controllers/          # RESTful controllers
├── models/              # ActiveRecord models
├── views/               # ERB templates
├── javascript/          # Stimulus controllers
├── services/            # Business logic
└── jobs/                # Background jobs

config/
├── routes.rb            # Route definitions
├── application.rb       # App configuration
└── environments/        # Environment configs
└── ...                 # Additional features
```

## 🔒 Security

- **Authentication**: Devise with MFA support
- **Authorization**: Pundit with role-based access
- **Input Validation**: Strong parameters and model validations
- **AI Privacy**: Never send PII to external AI services
- **Audit Logging**: Comprehensive action tracking

## 📊 Performance

- **Target**: Sub-2s page loads
- **Real-time**: <500ms WebSocket updates
- **Caching**: Redis for sessions and fragments
- **Background Jobs**: Sidekiq for heavy processing
- **Database**: Optimized queries with proper indexes

## 🧪 Testing

- **Framework**: RSpec for all testing
- **Coverage**: >90% test coverage target
- **Types**: Unit, integration, and system tests
- **Data**: FactoryBot for test data
- **External APIs**: VCR for API mocking

## 🚀 Deployment

### Production Setup

1. **Environment variables**
   ```bash
   # Required for production
   DATABASE_URL=postgresql://...
   REDIS_URL=redis://...
   SECRET_KEY_BASE=...
   AI_API_KEY=...
   ```

2. **Deploy with Kamal**
   ```bash
   kamal deploy
   ```

### Monitoring

- **Application**: New Relic or similar
- **Errors**: Sentry integration
- **Logs**: Structured logging with correlation IDs
- **Health**: `/health` endpoint for monitoring

## 🤝 Contributing

1. Follow the established coding standards
2. Write tests for all new features
3. Update documentation as needed
4. Use the task-based development workflow
5. Ensure security and performance requirements are met

## 📚 Documentation

- [Configuration Guide](docs/configuration.md)
- [API Documentation](docs/api.md)
- [Security Guidelines](docs/security.md)
- [Performance Tuning](docs/performance.md)
- [Testing Guide](docs/testing.md)

## 🆘 Support

- **Issues**: Create GitHub issues for bugs
- **Security**: Report security issues privately
- **Questions**: Check documentation or create discussions

## 📄 License

[License information here]

---

**Built with ❤️ for the EZLogs ecosystem**
