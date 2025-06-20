# EZLogs Rails Application - Architecture

## System Overview

The EZLogs Rails Application is a production-grade web dashboard for monitoring, managing, and analyzing events from the EZLogs ecosystem. It provides AI-powered event translation, intelligent grouping, and comprehensive analytics.

## Architecture Layers

### 1. Presentation Layer
- **Controllers**: Handle HTTP requests and responses
- **Views**: ERB templates with Tailwind CSS styling
- **Stimulus**: JavaScript controllers for interactive features
- **Hotwire**: Real-time updates and SPA-like experience

### 2. Business Logic Layer
- **Models**: ActiveRecord models with business logic
- **Services**: Complex business operations and external integrations
- **Jobs**: Background processing for AI operations and data processing
- **Policies**: Authorization logic with Pundit

### 3. Data Layer
- **PostgreSQL**: Primary database for all application data
- **Redis**: Caching, sessions, and background job queues
- **External APIs**: AI services (OpenAI, Anthropic) for event translation

## Core Components

### Authentication & Authorization
- **Devise**: User authentication and session management
- **Pundit**: Role-based authorization policies
- **User Sessions**: Secure session tracking and management
- **API Keys**: Secure API access for external integrations

### Event Processing
- **Event Model**: Core event storage and retrieval
- **Event Translation**: AI-powered event interpretation and caching
- **Event Groups**: Intelligent event clustering and classification
- **Event Patterns**: Pattern matching for event classification

### Analytics & Monitoring
- **Alerts**: Configurable alerting system with multiple channels
- **Audit Logs**: Comprehensive security audit trail
- **Teams**: Multi-tenant team management
- **API Keys**: Secure external API access

## Data Flow

### Event Ingestion
1. Events received via API endpoints
2. Events stored in PostgreSQL with metadata
3. Background jobs triggered for AI processing
4. Events classified and grouped automatically

### AI Processing Pipeline
1. Event data sent to AI services for translation
2. Results cached in EventTranslation model
3. Confidence scores and metadata stored
4. Cache expiration managed automatically

### User Interface
1. Real-time event updates via Hotwire
2. Interactive dashboards with Tailwind CSS
3. Responsive design for all devices
4. Progressive Web App capabilities

## Security Architecture

### Authentication
- Multi-factor authentication support
- Session management with expiration
- Secure password policies
- Account lockout protection

### Authorization
- Role-based access control (RBAC)
- Resource-level permissions
- API key scoping and restrictions
- Audit logging for all actions

### Data Protection
- PII detection and redaction
- Encrypted sensitive data storage
- Secure API communication
- Rate limiting and abuse protection

## Performance Considerations

### Database Optimization
- Proper indexing on frequently queried fields
- Query optimization and N+1 prevention
- Connection pooling configuration
- Read replicas for analytics queries

### Caching Strategy
- Redis for session storage
- Event translation result caching
- API response caching
- Asset caching and CDN integration

### Background Processing
- Sidekiq for async job processing
- Job prioritization and retry logic
- Dead job handling and monitoring
- Queue monitoring and alerting

## Scalability

### Horizontal Scaling
- Stateless application design
- Database connection pooling
- Redis cluster support
- Load balancer ready

### Vertical Scaling
- Optimized memory usage
- Efficient database queries
- Background job optimization
- Asset optimization

## Monitoring & Observability

### Application Monitoring
- Error tracking with Sentry
- Performance monitoring
- Custom metrics collection
- Health check endpoints

### Infrastructure Monitoring
- Database performance metrics
- Redis monitoring
- Background job monitoring
- System resource monitoring

## Deployment Architecture

### Containerization
- Docker support for consistent environments
- Multi-stage builds for optimization
- Health checks and graceful shutdown
- Environment-specific configurations

### Deployment Strategy
- Kamal for zero-downtime deployments
- Database migration safety
- Asset precompilation
- Environment variable management

## Integration Points

### External Services
- **AI Services**: OpenAI, Anthropic for event translation
- **Email Services**: SendGrid, Mailgun for notifications
- **Monitoring**: Sentry for error tracking
- **Analytics**: Custom analytics and reporting

### Internal Services
- **EZLogs Go Agent**: Event forwarding and buffering
- **EZLogs Ruby Agent**: Event collection from Rails apps
- **Background Jobs**: Sidekiq for async processing
- **Caching**: Redis for performance optimization

## Future Considerations

### Planned Enhancements
- GraphQL API for flexible data access
- Real-time collaboration features
- Advanced analytics and machine learning
- Mobile application support
- Multi-region deployment support 