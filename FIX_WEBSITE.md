# Website Issues - Database Schema Mismatch

## Problem
Backend code expects different database schema than what exists:
- Backend expects: `cognito_sub`, `username`, `person_limit`, `ticket_price`, `organizer_id`
- Database has: Different column names from old schema

## Root Cause
The `init.sql` file creates an old schema that doesn't match the current backend code (Spring Boot entities).

## Solution Required
Either:
1. Update backend entities to match init.sql schema
2. Update init.sql to match backend entities
3. Let Spring Boot auto-create schema (set `spring.jpa.hibernate.ddl-auto=update`)

## Quick Fix
Set Spring Boot to auto-create schema:

```bash
# Add to backend environment:
-e SPRING_JPA_HIBERNATE_DDL_AUTO=update
```

Then restart backend and it will create correct schema automatically.

## Test After Fix
```bash
# Should work:
curl -X POST https://d3qkurc1gwuwno.cloudfront.net/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@test.com","password":"password123","confirmPassword":"password123","termsAccepted":true}'

# Then login and create events via website
```
