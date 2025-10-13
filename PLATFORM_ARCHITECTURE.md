# 🏗️ Concert Platform Architecture - Complete Guide

## Overview
This platform uses a **hybrid storage approach**: Events stored in **JSON files** and Users/Bookings stored in **MySQL database**. This creates a flexible, scalable event management system.

---

## 🗂️ Data Architecture

### Storage Strategy

| Data Type | Storage | Location | Why? |
|-----------|---------|----------|------|
| **Events** | JSON File | `main_frontend/concert1/data/events.json` | Fast reads, easy to manage, user-created content |
| **Users** | MySQL | `concert_db.users` table | Secure, relational, authentication |
| **Bookings** | MySQL | `concert_db.bookings` table | Transactional, links users to events |

---

## 📊 Database Schema

### MySQL Tables

#### 1. Users Table
```sql
CREATE TABLE users (
    user_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) UNIQUE,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    profile_photo VARCHAR(255),
    company VARCHAR(150),
    website VARCHAR(150),
    phone VARCHAR(20),
    address VARCHAR(255),
    city VARCHAR(100),
    country VARCHAR(100),
    pincode VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

#### 2. Bookings Table (Hybrid Approach)
```sql
CREATE TABLE bookings (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    event_id VARCHAR(255) NOT NULL,        -- References JSON event ID
    event_title VARCHAR(500),               -- Denormalized from JSON
    event_location VARCHAR(500),            -- Denormalized from JSON
    event_start_date DATETIME,              -- Denormalized from JSON
    quantity INT NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'PENDING',
    booking_date DATETIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);
```

**Key Design Decision**: 
- `event_id` is **VARCHAR** (not foreign key) because events are in JSON
- Event details are **denormalized** (copied) into bookings for historical preservation
- No dependency on events table in MySQL

---

## 📁 Events JSON Structure

### File Location
`main_frontend/concert1/data/events.json`

### Event Schema
```json
{
  "id": 1760350889162,                    // Timestamp-based unique ID
  "title": "Spring Music Festival",
  "description": "Annual festival...",
  "personLimit": 1000,
  "startDate": "2025-10-13T17:21:00",
  "endDate": "2025-10-17T23:21:00",
  "ticketPrice": 100.00,
  "location": "Central Park",
  "address": "123 Main St",
  "city": "New York",
  "country": "USA",
  "category": "Music",
  "userId": 22,                            // Creator's user ID from MySQL
  "userName": "John Doe",                  // Creator's name from MySQL
  "createdAt": "2025-10-13T10:21:29.162Z",
  "participants": [                        // Optional: track who joined
    {
      "userId": 23,
      "userName": "Jane Smith",
      "joinedAt": "2025-10-13T10:43:46.265Z"
    }
  ],
  "participantsCount": 1
}
```

---

## 🔄 System Workflows

### 1. User Registration & Login

```
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │ POST /api/auth/register
       │ { username, email, password, name }
       ▼
┌──────────────────┐
│  Nuxt Server     │
│  (Port 3000)     │
└──────┬───────────┘
       │ POST http://backend:8080/api/auth/register
       ▼
┌──────────────────┐
│  Spring Boot     │
│  (Port 8080)     │
└──────┬───────────┘
       │ INSERT INTO users
       ▼
┌──────────────────┐
│  MySQL Database  │
│  (Port 3306)     │
└──────────────────┘
```

**Result**: User stored in MySQL, JWT token returned

---

### 2. Event Creation

```
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │ POST /api/events/json
       │ { title, description, startDate, ... }
       │ Headers: Authorization: Bearer <JWT>
       ▼
┌──────────────────────────┐
│  Nuxt Server             │
│  server/api/events/json  │
└──────┬───────────────────┘
       │ 1. Validate JWT → get userId from MySQL
       │ 2. Generate event ID (timestamp)
       │ 3. Add userId, userName to event
       │ 4. Save to events.json
       ▼
┌──────────────────────────┐
│  events.json             │
│  {                       │
│    id: timestamp,        │
│    ...eventData,         │
│    userId: 22,          │
│    userName: "John"      │
│  }                       │
└──────────────────────────┘
```

**Key Points**:
- Event ID = Current timestamp (unique)
- User info comes from MySQL via JWT validation
- No MySQL storage for events

---

### 3. Booking Flow (Hybrid Approach)

```
┌─────────────┐
│   Browser   │
│  Event Page │
└──────┬──────┘
       │ 1. Fetch event from JSON
       │ GET /api/events/json/1760350889162
       ▼
┌──────────────────────────┐
│  Display Event Details   │
│  - Title, Description    │
│  - Location, Dates       │
│  - Ticket Price          │
│  - Book Tickets Button   │
└──────┬───────────────────┘
       │ 2. User clicks "Book Tickets"
       │ POST /api/bookings
       │ {
       │   eventId: "1760350889162",
       │   quantity: 2,
       │   eventTitle: "Spring Music Festival",
       │   eventLocation: "Central Park",
       │   eventStartDate: "2025-10-13T17:21:00",
       │   ticketPrice: 100.00
       │ }
       ▼
┌──────────────────────────┐
│  Nuxt Server → Backend   │
│  POST /api/bookings      │
└──────┬───────────────────┘
       │ 3. Validate JWT
       │ 4. Calculate total: quantity × ticketPrice
       │ 5. Create booking in MySQL
       ▼
┌──────────────────────────┐
│  MySQL: bookings table   │
│  INSERT INTO bookings    │
│  (user_id, event_id,     │
│   event_title,           │
│   event_location,        │
│   quantity, total_price) │
└──────────────────────────┘
```

**Why This Works**:
- Event details are **copied** to booking (denormalization)
- If event is deleted from JSON, booking still has all info
- `event_id` is just a reference string, not a foreign key

---

### 4. View My Bookings

```
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │ GET /api/bookings/me
       │ Headers: Authorization: Bearer <JWT>
       ▼
┌──────────────────────────┐
│  Backend                 │
│  1. Decode JWT → userId  │
│  2. Query MySQL          │
│     SELECT * FROM bookings
│     WHERE user_id = ?    │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│  Return Bookings         │
│  [                       │
│    {                     │
│      id: 1,              │
│      eventId: "17603...", │
│      eventTitle: "...",  │
│      eventLocation: "...",│
│      quantity: 2,        │
│      totalPrice: 200     │
│    }                     │
│  ]                       │
└──────────────────────────┘
```

**No JOIN needed**: All event data is in the booking row!

---

## 🛠️ API Endpoints

### Authentication (MySQL)
| Method | Endpoint | Body | Response |
|--------|----------|------|----------|
| POST | `/api/auth/register` | `{username, email, password, name}` | `{token, user}` |
| POST | `/api/auth/login` | `{username, password}` | `{token, user}` |
| GET | `/api/auth/me` | Headers: `Authorization: Bearer <token>` | `{user}` |

### Events (JSON File)
| Method | Endpoint | Body | Response |
|--------|----------|------|----------|
| GET | `/api/events/json` | - | `[events]` |
| GET | `/api/events/json/:id` | - | `{event}` |
| POST | `/api/events/json` | `{title, description, startDate, ...}` | `{event}` |
| PUT | `/api/events/json/:id` | `{title, description, ...}` | `{event}` |
| DELETE | `/api/events/json/:id` | - | `{success: true}` |

### Bookings (MySQL with Event Data)
| Method | Endpoint | Body | Response |
|--------|----------|------|----------|
| POST | `/api/bookings` | `{eventId, quantity, eventTitle, eventLocation, eventStartDate, ticketPrice}` | `{booking}` |
| GET | `/api/bookings/me` | - | `[bookings]` |
| GET | `/api/bookings/:id` | - | `{booking}` |
| DELETE | `/api/bookings/:id` | - | `204 No Content` |

---

## 🎯 Key Features

### ✅ What Works

1. **User Management**
   - ✅ Register new users
   - ✅ Login with JWT authentication
   - ✅ Update profile
   - ✅ Secure password hashing (BCrypt)

2. **Event Management**
   - ✅ Browse all events
   - ✅ View event details
   - ✅ Create new events (authenticated users)
   - ✅ Edit own events
   - ✅ Delete own events
   - ✅ Filter by category, date, search

3. **Booking System**
   - ✅ Book tickets for events
   - ✅ Select quantity
   - ✅ Automatic price calculation
   - ✅ View booking history
   - ✅ Booking status tracking
   - ✅ Event details preserved in bookings

4. **Account Features**
   - ✅ My Events (created events)
   - ✅ My Bookings (purchased tickets)
   - ✅ Profile management
   - ✅ Session persistence

---

## 🔐 Security Model

### Authentication Flow
1. User logs in → Backend validates credentials
2. Backend generates JWT token with user info
3. Token stored in browser (localStorage/sessionStorage)
4. All API requests include token in Authorization header
5. Backend validates token on each request

### Data Protection
- **Passwords**: BCrypt hashed in MySQL
- **JWTs**: Signed tokens, expire after session
- **API Routes**: Protected with JWT middleware
- **Event Ownership**: Only creators can edit/delete events
- **Booking Ownership**: Users can only see their own bookings

---

## 📂 File Structure

```
develop/
├── docker-compose.yml                    # All services
├── database-setup.sql                    # MySQL schema
├── main_backend/                         # Spring Boot API
│   ├── src/main/java/com/concert/
│   │   ├── controller/
│   │   │   ├── AuthController.java       # Login, Register
│   │   │   └── BookingController.java    # Booking CRUD
│   │   ├── model/
│   │   │   ├── User.java                 # User entity (MySQL)
│   │   │   └── Booking.java              # Booking entity (MySQL)
│   │   ├── repository/
│   │   │   ├── UserRepository.java
│   │   │   └── BookingRepository.java
│   │   ├── service/
│   │   │   ├── JwtService.java
│   │   │   ├── UserService.java
│   │   │   └── BookingService.java
│   │   └── security/
│   │       └── JwtAuthenticationFilter.java
│   └── pom.xml
└── main_frontend/concert1/               # Nuxt 4 App
    ├── app/
    │   ├── pages/
    │   │   ├── index.vue                 # Home
    │   │   ├── ProductPage.vue           # Browse Events
    │   │   ├── ProductPageDetail/[id].vue # Event Detail + Book
    │   │   ├── MyEventsPage.vue          # My Created Events
    │   │   ├── MyBookingsPage.vue        # My Bookings
    │   │   ├── LoginPage.vue
    │   │   ├── RegisterPage.vue
    │   │   └── AccountPage.vue           # Profile
    │   └── components/
    │       ├── Login.vue
    │       ├── Register.vue
    │       └── ProductCard.vue           # Event Card
    ├── server/api/
    │   ├── auth/                         # Proxy to backend auth
    │   ├── bookings/                     # Proxy to backend bookings
    │   └── events/json/                  # JSON file management
    │       ├── index.get.ts              # List all events
    │       ├── index.post.ts             # Create event
    │       ├── [id].get.ts               # Get one event
    │       ├── [id].put.ts               # Update event
    │       └── [id].delete.ts            # Delete event
    └── data/
        └── events.json                   # Events storage

```

---

## 🚀 How to Use

### Start the Platform
```bash
docker compose up -d
```

### Access Points
- **Frontend**: http://localhost:3000/concert/
- **Backend API**: http://localhost:8080
- **MySQL**: localhost:3306

### Test the System

#### 1. Register a User
```bash
# Browser: Go to http://localhost:3000/concert/RegisterPage
# Or API:
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123",
    "name": "Test User"
  }'
```

#### 2. Login
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "password123"
  }'
# Returns: { "token": "eyJhbGc...", "user": {...} }
```

#### 3. Create an Event
```bash
# Browser: Login → Click "Create Event" → Fill form
# The event will be saved to data/events.json
```

#### 4. Book Tickets
```bash
# Browser: Browse events → Click event → "Book Tickets"
# Booking will be saved to MySQL with event details copied
```

#### 5. View Bookings
```bash
# Browser: My Bookings page
# Shows all bookings from MySQL with embedded event info
```

---

## 🎨 User Journey

### New User Flow
```
1. Register → Create Account (MySQL)
2. Login → Get JWT Token
3. Browse Events → Read events.json
4. Click Event → View Details
5. Book Tickets → Create Booking (MySQL + event data)
6. View "My Bookings" → See booking with event details
```

### Event Creator Flow
```
1. Login → Authenticate
2. Create Event → Save to events.json (with userId)
3. View "My Events" → Filter events.json by userId
4. Edit Event → Update events.json
5. Delete Event → Remove from events.json
```

---

## 💡 Design Benefits

### Why JSON for Events?
✅ **Fast Development**: No schema migrations  
✅ **Flexible Schema**: Easy to add fields  
✅ **User-Generated Content**: Perfect for dynamic data  
✅ **Easy Backup**: Single file  
✅ **Version Control**: Track changes in git  

### Why MySQL for Users/Bookings?
✅ **Security**: Hashed passwords, transactions  
✅ **Relational Data**: User ↔ Bookings relationship  
✅ **ACID Compliance**: Booking integrity  
✅ **Query Performance**: Index on user_id  
✅ **Scalability**: Can shard by user_id  

### Why Denormalize Event Data in Bookings?
✅ **Historical Preservation**: Event details frozen at booking time  
✅ **No Broken References**: Event can be deleted without affecting bookings  
✅ **Fast Queries**: No JOINs needed  
✅ **Independence**: Bookings work even if events.json is corrupted  

---

## 📈 Scaling Considerations

### Current Limits
- **Events**: JSON file, suitable for ~10,000 events
- **Users**: MySQL, millions of users
- **Bookings**: MySQL, millions of bookings

### Future Improvements
1. **Move Events to Database**: When events > 10,000
2. **Add Caching**: Redis for frequently accessed events
3. **CDN for Images**: Event banners/photos
4. **Search Engine**: Elasticsearch for advanced event search
5. **Message Queue**: RabbitMQ for booking confirmations

---

## ✨ Summary

This platform successfully implements a **hybrid storage architecture**:

| Component | Storage | Why |
|-----------|---------|-----|
| **Users** | MySQL | Secure, relational, scalable |
| **Events** | JSON | Fast, flexible, user-generated |
| **Bookings** | MySQL + Denormalized Event Data | Transactional + Historical preservation |

**Result**: A working event booking platform that's easy to develop, maintain, and scale! 🎉
