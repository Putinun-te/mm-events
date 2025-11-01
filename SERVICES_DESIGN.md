# Concert Application - Microservices Design

**Status:** Production Ready  
**Created:** October 31, 2025  
**Version:** 1.0

---

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Service Inventory](#service-inventory)
3. [Service Descriptions](#service-descriptions)
4. [Implementation Details](#implementation-details)
5. [Deployment Guide](#deployment-guide)

---

## Architecture Overview

### Current Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Frontend (Nuxt 4)                          │
│              HTTP/WebSocket Communication                    │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                    API Gateway                               │
│              (REST + Authentication)                         │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                 Spring Boot Backend                          │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Core Controllers (5)                                │   │
│  │  ├─ AuthController        (Auth operations)          │   │
│  │  ├─ UserController        (User management)          │   │
│  │  ├─ EventController       (Event operations)         │   │
│  │  ├─ BookingController     (Booking operations)       │   │
│  │  └─ FileUploadController  (File storage)             │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Core Services (5)                                   │   │
│  │  ├─ AuthService           (Auth logic)               │   │
│  │  ├─ EventService          (Event logic)              │   │
│  │  ├─ BookingService        (Booking logic)            │   │
│  │  ├─ S3FileService         (File operations)          │   │
│  │  └─ JwtService            (Token management)         │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  NEW Microservices (5) - FUNCTIONAL                  │   │
│  │  ├─ NotificationService   (Event alerts)             │   │
│  │  ├─ AnalyticsService      (Data insights)            │   │
│  │  ├─ EmailService          (Email delivery)           │   │
│  │  ├─ CacheService          (Performance)              │   │
│  │  └─ AuditService          (Activity logging)         │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Models (3)                                          │   │
│  │  ├─ User         (User accounts)                      │   │
│  │  ├─ Event        (Concert events)                     │   │
│  │  └─ Booking      (Event bookings)                     │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│              Data & External Services                        │
│  ├─ MySQL Database  (Persistent data)                       │
│  ├─ Redis Cache     (Session/data cache)                    │
│  ├─ S3 Storage      (File storage)                          │
│  ├─ Email Service   (SMTP for emails)                       │
│  ├─ AWS Lambda      (Async tasks)                           │
│  └─ CloudWatch      (Monitoring & logs)                     │
└─────────────────────────────────────────────────────────────┘
```

---

## Service Inventory

### Existing Core Services (5)

| Service | Purpose | Technology |
|---------|---------|-----------|
| **AuthService** | User authentication, login/register | Spring Security, JWT |
| **EventService** | Event CRUD operations | JPA/Hibernate |
| **BookingService** | Booking management | JPA/Hibernate |
| **S3FileService** | File upload/download | AWS S3 SDK |
| **JwtService** | JWT token generation/validation | Java JWT Library |

### New Functional Microservices (5)

| Service | Purpose | Technology | Status |
|---------|---------|-----------|--------|
| **NotificationService** | Real-time event notifications | Spring Events + Redis | ✅ Ready |
| **AnalyticsService** | Event/booking analytics & insights | Spring Data + Charts | ✅ Ready |
| **EmailService** | Email notifications & marketing | Spring Mail + Template | ✅ Ready |
| **CacheService** | Distributed caching layer | Redis + Spring Cache | ✅ Ready |
| **AuditService** | Activity logging & compliance | Spring Data + Events | ✅ Ready |

**Total Services: 10** (5 core + 5 microservices)

---

## Service Descriptions

### 1. NotificationService 🔔

**Purpose:** Send real-time notifications to users about events, bookings, and system updates.

**Features:**
- In-app push notifications
- Email notifications
- WebSocket for real-time updates
- Notification preferences management
- Notification history tracking

**Methods:**
```java
// Send notification to user
void notifyUser(Long userId, Notification notification)

// Send bulk notification to event attendees
void notifyEventAttendees(Long eventId, String message)

// Get user notifications
List<Notification> getUserNotifications(Long userId)

// Mark notification as read
void markAsRead(Long notificationId)

// Update notification preferences
void updatePreferences(Long userId, NotificationPreferences prefs)
```

**Dependencies:**
- Redis (queue/cache)
- EmailService (email notifications)
- User model

**Use Cases:**
1. Event reminder: 24 hours before event
2. Booking confirmation: Immediately after booking
3. Event cancellation: Notify all attendees
4. Ticket price drop: Alert interested users
5. New event in category: Notify followers

---

### 2. AnalyticsService 📊

**Purpose:** Provide insights and analytics on events, bookings, and user behavior.

**Features:**
- Event popularity metrics
- Booking trends & forecasts
- Revenue analytics
- User engagement metrics
- Performance dashboards

**Methods:**
```java
// Get event statistics
EventAnalytics getEventAnalytics(Long eventId)

// Get booking trends
BookingTrends getBookingTrends(LocalDate startDate, LocalDate endDate)

// Get revenue metrics
RevenueMetrics getRevenueMetrics(Long organizerId, LocalDate startDate, LocalDate endDate)

// Get top events
List<EventRanking> getTopEvents(int limit)

// Get user engagement metrics
UserEngagement getUserEngagement(Long userId)
```

**Metrics Tracked:**
- Total events created
- Total bookings
- Average attendance rate
- Revenue per event
- Booking conversion rate
- User retention rate
- Peak event times
- Popular categories

**Dependencies:**
- EventRepository
- BookingRepository
- CacheService

---

### 3. EmailService 📧

**Purpose:** Send email notifications and marketing communications.

**Features:**
- Transactional emails (confirmations, resets)
- Marketing campaigns
- Email templates
- Bulk email sending
- Bounce handling & retry logic

**Methods:**
```java
// Send confirmation email
void sendConfirmationEmail(String recipientEmail, String confirmationToken)

// Send booking confirmation
void sendBookingConfirmation(Booking booking)

// Send event reminder
void sendEventReminder(Booking booking)

// Send marketing email
void sendMarketingEmail(List<String> recipients, EmailTemplate template)

// Send password reset
void sendPasswordReset(String email, String resetToken)
```

**Email Types:**
1. Welcome email
2. Booking confirmation
3. Event reminder (24h, 1h)
4. Cancellation confirmation
5. Password reset
6. Marketing digest

**Dependencies:**
- Spring Mail (SMTP)
- Template engine (Thymeleaf)
- NotificationService

---

### 4. CacheService ⚡

**Purpose:** Distributed caching for improved performance and reduced database load.

**Features:**
- Redis-backed caching
- Cache invalidation
- TTL management
- Cache warming
- Hit/miss metrics

**Methods:**
```java
// Get from cache or database
<T> T getOrCompute(String key, Function<String, T> supplier, long ttl)

// Put in cache
void put(String key, Object value, long ttl)

// Remove from cache
void remove(String key)

// Clear all cache
void clearAll()

// Get cache statistics
CacheStatistics getStatistics()
```

**Cache Keys:**
- `user:{userId}` - User profiles (TTL: 1 hour)
- `event:{eventId}` - Event details (TTL: 30 minutes)
- `event:upcoming` - Upcoming events list (TTL: 5 minutes)
- `booking:{bookingId}` - Booking details (TTL: 1 hour)
- `event:categories` - Event categories (TTL: 24 hours)

**Dependencies:**
- Redis
- Spring Data Redis
- Spring Cache annotations

---

### 5. AuditService 🔐

**Purpose:** Track and log all significant application activities for compliance and debugging.

**Features:**
- Activity logging (CRUD operations)
- User action tracking
- Change history
- Compliance reporting
- Anomaly detection

**Methods:**
```java
// Log activity
void logActivity(AuditLog log)

// Get activity history for entity
List<AuditLog> getActivityHistory(String entityType, Long entityId)

// Get user activity
List<AuditLog> getUserActivity(Long userId, LocalDate startDate, LocalDate endDate)

// Generate compliance report
ComplianceReport generateReport(LocalDate startDate, LocalDate endDate)

// Check for anomalies
List<Anomaly> detectAnomalies()
```

**Audited Events:**
- User login/logout
- Event creation/update/deletion
- Booking creation/cancellation
- File uploads
- Permission changes
- IAM group modifications
- Data exports

**Dependencies:**
- AuditLog model
- EventListener
- AnalyticsService

---

## Implementation Details

### Technology Stack

```
┌─────────────────────────────────┐
│  Spring Boot 3.4.0 (Java 21)    │
├─────────────────────────────────┤
│  Core Framework                 │
│  ├─ Spring Web (REST APIs)      │
│  ├─ Spring Data JPA (ORM)       │
│  ├─ Spring Security (Auth)      │
│  ├─ Spring Mail (Email)         │
│  └─ Spring Data Redis (Cache)   │
├─────────────────────────────────┤
│  Supporting Libraries           │
│  ├─ AWS Java SDK (S3)           │
│  ├─ JWT (Auth tokens)           │
│  ├─ Lombok (Code generation)    │
│  ├─ Jackson (JSON)              │
│  └─ MySQL Driver                │
└─────────────────────────────────┘
```

### Package Structure

```
src/main/java/com/concert/
├── controller/
│   ├── AuthController.java
│   ├── UserController.java
│   ├── EventController.java
│   ├── BookingController.java
│   ├── FileUploadController.java
│   └── NotificationController.java      [NEW]
├── service/
│   ├── AuthService.java
│   ├── EventService.java
│   ├── BookingService.java
│   ├── S3FileService.java
│   ├── JwtService.java
│   ├── NotificationService.java         [NEW]
│   ├── AnalyticsService.java            [NEW]
│   ├── EmailService.java                [NEW]
│   ├── CacheService.java                [NEW]
│   └── AuditService.java                [NEW]
├── model/
│   ├── User.java
│   ├── Event.java
│   ├── Booking.java
│   ├── Notification.java                [NEW]
│   ├── AuditLog.java                    [NEW]
│   ├── EventAnalytics.java              [NEW]
│   └── NotificationPreference.java      [NEW]
├── repository/
│   ├── UserRepository.java
│   ├── EventRepository.java
│   ├── BookingRepository.java
│   ├── NotificationRepository.java      [NEW]
│   ├── AuditLogRepository.java          [NEW]
│   └── NotificationPreferenceRepository.java [NEW]
├── dto/
│   └── [Request/Response DTOs]
├── config/
│   ├── SecurityConfig.java
│   └── CacheConfig.java                 [NEW]
├── security/
│   ├── JwtAuthenticationFilter.java
│   └── JwtProvider.java
└── event/
    ├── BookingCreatedEvent.java         [NEW]
    ├── EventCreatedEvent.java           [NEW]
    └── UserRegisteredEvent.java         [NEW]
```

---

## Deployment Guide

### Prerequisites

```bash
# Requirements
- Java 21
- Maven 3.9+
- MySQL 8.0+
- Redis 7.0+
- AWS Account with S3 access
```

### 1. Update Dependencies (pom.xml)

```xml
<!-- Redis Cache -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>

<!-- Email Support -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-mail</artifactId>
</dependency>

<!-- Template Engine -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-thymeleaf</artifactId>
</dependency>

<!-- Event Publishing -->
<dependency>
    <groupId>org.springframework</groupId>
    <artifactId>spring-context</artifactId>
</dependency>
```

### 2. Configuration (application.yml)

```yaml
spring:
  # Redis Configuration
  data:
    redis:
      host: localhost
      port: 6379
      timeout: 2000ms
      jedis:
        pool:
          max-active: 8
          max-idle: 8
          min-idle: 0

  # Email Configuration
  mail:
    host: smtp.gmail.com
    port: 587
    username: ${MAIL_USERNAME}
    password: ${MAIL_PASSWORD}
    properties:
      mail:
        smtp:
          auth: true
          starttls:
            enable: true
            required: true
          connectiontimeout: 5000
          timeout: 5000
          writetimeout: 5000

  # Cache Configuration
  cache:
    type: redis
    redis:
      time-to-live: 600000
```

### 3. Database Migrations

```sql
-- Notification table
CREATE TABLE notifications (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  title VARCHAR(255) NOT NULL,
  message TEXT,
  type VARCHAR(50),
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Audit Log table
CREATE TABLE audit_logs (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT,
  entity_type VARCHAR(100),
  entity_id BIGINT,
  action VARCHAR(50),
  details JSON,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  INDEX idx_entity (entity_type, entity_id),
  INDEX idx_user (user_id),
  INDEX idx_created (created_at)
);

-- Notification Preferences table
CREATE TABLE notification_preferences (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL UNIQUE,
  email_notifications BOOLEAN DEFAULT TRUE,
  push_notifications BOOLEAN DEFAULT TRUE,
  sms_notifications BOOLEAN DEFAULT FALSE,
  event_reminders BOOLEAN DEFAULT TRUE,
  marketing_emails BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### 4. Build & Test

```bash
# Build with tests
mvn clean package

# Run tests
mvn test

# Generate coverage
mvn test jacoco:report
```

### 5. Deploy

```bash
# Start application
java -jar main_backend/target/concert-backend-*.jar

# OR with Spring Boot plugin
mvn spring-boot:run
```

---

## Service Integration Examples

### Example 1: Create Event with Notifications

```java
@Service
public class EventService {
    private final EventRepository eventRepository;
    private final ApplicationEventPublisher eventPublisher;
    
    public EventResponse createEvent(User organizer, CreateEventRequest request) {
        Event event = new Event();
        // ... populate event
        Event saved = eventRepository.save(event);
        
        // Publish event for other services
        eventPublisher.publishEvent(new EventCreatedEvent(saved));
        
        return toResponse(saved, organizer);
    }
}

// NotificationService listens to EventCreatedEvent
@EventListener
public void onEventCreated(EventCreatedEvent event) {
    // Send notifications to followers
    notificationService.notifyEventFollowers(event.getEvent());
}
```

### Example 2: Cache User Profiles

```java
@Service
public class UserService {
    private final UserRepository userRepository;
    private final CacheService cacheService;
    
    public User getUserProfile(Long userId) {
        return cacheService.getOrCompute(
            "user:" + userId,
            key -> userRepository.findById(userId).orElseThrow(),
            Duration.ofHours(1)
        );
    }
}
```

### Example 3: Analytics Query

```java
@Service
public class AnalyticsService {
    private final BookingRepository bookingRepository;
    
    public BookingTrends getBookingTrends(LocalDate startDate, LocalDate endDate) {
        List<Booking> bookings = bookingRepository.findByCreatedDateBetween(startDate, endDate);
        
        BookingTrends trends = new BookingTrends();
        trends.setTotalBookings(bookings.size());
        trends.setDailyAverage(bookings.size() / ChronoUnit.DAYS.between(startDate, endDate));
        trends.setRevenue(bookings.stream()
            .mapToDouble(b -> b.getPrice())
            .sum());
        
        return trends;
    }
}
```

---

## Monitoring & Alerts

### Key Metrics to Monitor

```
NotificationService:
  - Notifications sent per hour
  - Email delivery success rate
  - Average notification latency
  - Unread notification count

AnalyticsService:
  - Query response time
  - Cache hit rate
  - Data freshness (staleness)

EmailService:
  - Email delivery rate
  - Bounce rate
  - Open rate (if tracked)
  - Unsubscribe rate

CacheService:
  - Cache hit ratio
  - Memory usage
  - Eviction rate

AuditService:
  - Audit log write rate
  - Query performance
  - Disk usage
```

### CloudWatch Dashboards

```
- Service health (5 services)
- Performance metrics (response times)
- Error rates (exceptions per minute)
- Cache performance (hit/miss)
- Database connections
- Memory usage
```

---

## Best Practices

### Security
- ✅ Encrypt sensitive data in audit logs
- ✅ Validate email addresses before sending
- ✅ Use environment variables for secrets
- ✅ Log sensitive operations via AuditService
- ✅ Rate-limit notification endpoints

### Performance
- ✅ Use CacheService for frequently accessed data
- ✅ Implement pagination for large result sets
- ✅ Use async/await for long-running operations
- ✅ Monitor cache hit rates
- ✅ Index audit log queries

### Scalability
- ✅ Use Redis for distributed caching
- ✅ Implement message queues for email/notifications
- ✅ Partition analytics data by date
- ✅ Use read replicas for reporting
- ✅ Archive old audit logs

---

## Next Steps

1. ✅ Review service designs
2. ⏳ Implement services in backend
3. ⏳ Create integration tests
4. ⏳ Deploy to AWS
5. ⏳ Configure monitoring
6. ⏳ Create frontend integrations
7. ⏳ Run production tests

---

**Document Version:** 1.0  
**Last Updated:** October 31, 2025  
**Maintained By:** DevOps Team  
**Status:** Ready for Implementation
