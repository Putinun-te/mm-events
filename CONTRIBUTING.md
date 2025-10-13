# Contributing to Concert Management System

First off, thank you for considering contributing to Concert Management System! It's people like you that make this project better.

## Table of Contents

- [Contributing to Concert Management System](#contributing-to-concert-management-system)
  - [Table of Contents](#table-of-contents)
  - [Code of Conduct](#code-of-conduct)
  - [How Can I Contribute?](#how-can-i-contribute)
    - [Reporting Bugs](#reporting-bugs)
    - [Suggesting Enhancements](#suggesting-enhancements)
    - [Pull Requests](#pull-requests)
  - [Development Setup](#development-setup)
    - [Prerequisites](#prerequisites)
    - [Initial Setup](#initial-setup)
    - [Running Tests](#running-tests)
  - [Pull Request Process](#pull-request-process)
  - [Coding Standards](#coding-standards)
    - [Frontend (Nuxt 4 / TypeScript / Vue 3)](#frontend-nuxt-4--typescript--vue-3)
    - [Backend (Spring Boot / Java)](#backend-spring-boot--java)
    - [Code Style](#code-style)
  - [Testing Guidelines](#testing-guidelines)
    - [Frontend Testing](#frontend-testing)
    - [Backend Testing](#backend-testing)
  - [Commit Message Guidelines](#commit-message-guidelines)
    - [Types](#types)
    - [Examples](#examples)
  - [Questions?](#questions)

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples** to demonstrate the steps
- **Describe the behavior you observed** and what you expected
- **Include screenshots** if possible
- **Include your environment details** (OS, browser, Node/Java versions)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear and descriptive title**
- **Provide a step-by-step description** of the suggested enhancement
- **Provide specific examples** to demonstrate the steps
- **Describe the current behavior** and explain the improvement
- **Explain why this enhancement would be useful**

### Pull Requests

- Fill in the required template
- Follow the coding standards
- Include appropriate test coverage
- Update documentation as needed
- Keep pull requests focused on a single feature/fix

## Development Setup

### Prerequisites

- **Node.js** 18+ and npm
- **Java** 17+ (JDK 21 recommended for tests)
- **Docker** and Docker Compose
- **Git**
- **Maven** 3.8+ (or use included Maven wrapper)

### Initial Setup

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/YOUR-USERNAME/develop.git
   cd develop
   ```

2. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your local configuration
   ```

3. **Install frontend dependencies**
   ```bash
   cd main_frontend/concert1
   npm install
   ```

4. **Install backend dependencies**
   ```bash
   cd main_backend
   ./mvnw install -DskipTests
   ```

5. **Start the development stack**
   ```bash
   # From project root
   docker-compose up -d
   ```

6. **Verify setup**
   - Backend: http://localhost:8080/api/auth/test
   - Frontend: http://localhost:3000

### Running Tests

**Frontend Tests:**
```bash
cd main_frontend/concert1
npm test                    # Unit tests
npm run test:e2e           # E2E tests
npm run test:coverage      # Coverage report
```

**Backend Tests:**
```bash
cd main_backend
./mvnw test                # All tests
./mvnw test jacoco:report  # With coverage
```

**Full Stack Tests:**
```bash
# From project root
docker-compose run --rm backend-tests
```

## Pull Request Process

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

2. **Make your changes**
   - Write meaningful commit messages
   - Add tests for new features
   - Update documentation

3. **Test your changes**
   ```bash
   # Run all tests
   npm test                    # Frontend
   ./mvnw test                 # Backend
   npm run test:e2e           # E2E tests
   ```

4. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

5. **Open a Pull Request**
   - Use a clear title and description
   - Link related issues
   - Request review from maintainers

6. **Code Review**
   - Address review feedback
   - Keep the PR updated with main branch
   - Ensure CI passes

7. **Merge Requirements**
   - ✅ All CI checks passing
   - ✅ Code review approval (1+)
   - ✅ No merge conflicts
   - ✅ Branch up to date with main
   - ✅ Coverage threshold maintained (80%+)

## Coding Standards

### Frontend (Nuxt 4 / TypeScript / Vue 3)

- **Use TypeScript** for type safety
- **Follow Vue 3 Composition API** patterns
- **Use Tailwind CSS** for styling
- **Component structure**:
  ```vue
  <script setup lang="ts">
  // Imports
  // Props & emits
  // Composables
  // Reactive state
  // Computed properties
  // Methods
  // Lifecycle hooks
  </script>

  <template>
    <!-- Template -->
  </template>

  <style scoped>
  /* Minimal CSS - prefer Tailwind */
  </style>
  ```

- **Naming conventions**:
  - Components: PascalCase (e.g., `UserProfile.vue`)
  - Composables: camelCase with `use` prefix (e.g., `useAuth.ts`)
  - Files: kebab-case or PascalCase

### Backend (Spring Boot / Java)

- **Follow Java conventions**: camelCase for methods, PascalCase for classes
- **Use Spring Boot best practices**
- **Package structure**:
  ```
  com.concert
  ├── config       # Configuration classes
  ├── controller   # REST controllers
  ├── dto          # Data Transfer Objects
  ├── model        # Entity classes
  ├── repository   # JPA repositories
  ├── security     # Security configurations
  └── service      # Business logic
  ```

- **REST API conventions**:
  - Use proper HTTP methods (GET, POST, PUT, DELETE)
  - Return appropriate status codes
  - Use DTOs for request/response
  - Validate all inputs with `@Valid`

### Code Style

- **Indentation**: 2 spaces (frontend), 4 spaces (backend)
- **Line length**: Max 120 characters
- **Imports**: Organize and remove unused imports
- **Comments**: Write clear, concise comments for complex logic
- **No commented-out code**: Remove or document why it's kept

## Testing Guidelines

### Frontend Testing

**Unit Tests (Vitest + Testing Library)**
- Test components in isolation
- Mock external dependencies
- Focus on user interactions
- Maintain 80%+ coverage

```typescript
import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import MyComponent from '@/components/MyComponent.vue'

describe('MyComponent', () => {
  it('renders properly', () => {
    const wrapper = mount(MyComponent, {
      props: { title: 'Test' }
    })
    expect(wrapper.text()).toContain('Test')
  })
})
```

**E2E Tests (Playwright)**
- Test complete user flows
- Cover critical paths (auth, CRUD operations)
- Use page object model
- Maintain stable selectors (`data-test-id`)

```typescript
import { test, expect } from '@playwright/test'

test('user can register', async ({ page }) => {
  await page.goto('/register')
  await page.fill('[data-test-id="username"]', 'testuser')
  await page.fill('[data-test-id="email"]', 'test@example.com')
  await page.fill('[data-test-id="password"]', 'password123')
  await page.click('[data-test-id="submit"]')
  await expect(page).toHaveURL(/.*dashboard/)
})
```

### Backend Testing

**Unit Tests (JUnit 5 + Mockito)**
- Test business logic in isolation
- Mock external dependencies
- Test edge cases and error handling
- Maintain 80%+ coverage

```java
@ExtendWith(MockitoExtension.class)
class AuthServiceTest {
    @Mock
    private UserRepository userRepository;
    
    @InjectMocks
    private AuthService authService;
    
    @Test
    void register_WithValidData_ShouldCreateUser() {
        // Arrange
        RegisterRequest request = new RegisterRequest();
        request.setUsername("testuser");
        
        // Act
        AuthResponse response = authService.register(request);
        
        // Assert
        assertNotNull(response.getToken());
    }
}
```

**Integration Tests (Spring Boot Test + Testcontainers)**
- Test full request/response cycle
- Use real database (via Testcontainers)
- Test authentication and authorization
- Verify error responses

```java
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AuthControllerTest {
    @Autowired
    private MockMvc mockMvc;
    
    @Test
    void register_ShouldReturn200() throws Exception {
        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"username\":\"test\"}"))
                .andExpect(status().isOk());
    }
}
```

## Commit Message Guidelines

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Changes that don't affect code meaning (formatting, etc.)
- **refactor**: Code change that neither fixes a bug nor adds a feature
- **perf**: Performance improvement
- **test**: Adding or updating tests
- **chore**: Changes to build process or auxiliary tools

### Examples

```
feat(auth): add password reset functionality

Implement password reset flow with email verification.
Users can now request password reset and receive email
with reset link valid for 1 hour.

Closes #123
```

```
fix(events): correct date validation logic

Events with start date in the past were not being rejected.
Added validation to ensure start date is in the future.

Fixes #456
```

```
test(auth): increase coverage for AuthController

Added tests for error paths:
- Missing required fields
- Invalid email format
- Duplicate username/email

Coverage: 63% -> 85%
```

## Questions?

Feel free to open an issue with the `question` label or reach out to the maintainers.

Thank you for contributing! 🎉
