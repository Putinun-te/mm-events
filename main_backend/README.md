# Concert Backend

A Spring Boot REST API for concert application authentication and user management.

## Features

- User registration and authentication
- JWT token-based security
- Password encryption with BCrypt
- MySQL database integration
- Comprehensive unit and integration tests
- CORS configuration for frontend integration

## Technologies Used

- **Spring Boot 3.2.0** - Main framework
- **Spring Security** - Authentication and authorization
- **Spring Data JPA** - Database operations
- **MySQL** - Production database
- **H2** - Test database
- **JWT** - Token-based authentication
- **JUnit 5** - Unit testing
- **Mockito** - Mocking framework
- **Maven** - Build tool

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/test` - Test endpoint

## Quick Start

### Prerequisites
- Java 17 or higher
- Maven 3.6+
- MySQL 8.0+

### Setup Database
```sql
CREATE DATABASE concert_db;
CREATE USER 'concert_user'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON concert_db.* TO 'concert_user'@'localhost';
FLUSH PRIVILEGES;
```

### Configuration
Update `src/main/resources/application.properties` with your database credentials:
```properties
spring.datasource.url=jdbc:mysql://localhost:3306/concert_db
spring.datasource.username=your_username
spring.datasource.password=your_password
```

### Running the Application
```bash
mvn spring-boot:run
```

The API will be available at `http://localhost:8080`

## Testing

### Run All Tests
```bash
mvn test
```

### Run Specific Test Categories
```bash
# Unit tests only
mvn test -Dtest="**/*Test"

# Integration tests only  
mvn test -Dtest="**/*IntegrationTest"

# Test with coverage (macOS, use JDK 21 for tests)
JAVA_HOME=$(/usr/libexec/java_home -v 21) mvn -DforkCount=1 -DreuseForks=false test jacoco:report

# Or run coverage in Docker (uses JDK 21 Maven image)
docker compose run --rm backend-tests
```

### Test Coverage
The project includes comprehensive test coverage:

- **Unit Tests**: Individual component testing
  - Model validation and behavior
  - Service business logic
  - Controller request/response handling
  - Repository data access operations

- **Integration Tests**: End-to-end API testing
  - Complete request-response flow
  - Database integration
  - Security configuration
  - Error handling

HTML coverage report: `main_backend/target/site/jacoco/index.html`

### Test Structure
```
src/test/java/
├── com/concert/
│   ├── model/           # Entity tests
│   ├── dto/            # DTO validation tests
│   ├── service/        # Business logic tests
│   ├── controller/     # Web layer tests
│   ├── repository/     # Data access tests
│   ├── integration/    # End-to-end tests
│   └── ConcertBackendTestSuite.java
```

## API Usage Examples

### Register User
```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com", 
    "password": "password123"
  }'
```

### Login User
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "usernameOrEmail": "testuser",
    "password": "password123"
  }'
```

## Development

### Project Structure
```
src/main/java/com/concert/
├── config/             # Configuration classes
├── controller/         # REST controllers
├── dto/               # Data Transfer Objects
├── model/             # JPA entities
├── repository/        # Data access layer
├── service/           # Business logic
└── ConcertBackendApplication.java
```

### Building for Production
```bash
mvn clean package
java -jar target/concert-backend-0.0.1-SNAPSHOT.jar
```

## Security

- Passwords are encrypted using BCrypt
- JWT tokens for stateless authentication
- CORS configured for frontend integration
- Input validation on all endpoints
- SQL injection protection via JPA

## License

This project is licensed under the MIT License.
