# Contributing to Concert Platform

First off, thank you for considering contributing to Concert Platform! It's people like you that make Concert Platform such a great tool.

## Where do I go from here?

If you've noticed a bug or have a feature request, [make one](https://github.com/MorningMores/develop/issues/new)! It's generally best if you get confirmation of your bug or approval for your feature request this way before starting to code.

### Fork & create a branch

If this is something you think you can fix, then [fork Concert Platform](https://github.com/MorningMores/develop/fork) and create a branch with a descriptive name.

A good branch name would be (where issue #325 is the ticket you're working on):

```sh
git checkout -b 325-add-japanese-translations
```

### Get the test suite running

Make sure you're running the test suite locally. Get in touch if you have any questions.

### Implement your fix or feature

At this point, you're ready to make your changes! Feel free to ask for help; everyone is a beginner at first 😸

### Make a Pull Request

At this point, you should switch back to your main branch and make sure it's up to date with Concert Platform's main branch:

```sh
git remote add upstream git@github.com:MorningMores/develop.git
git checkout main
git pull upstream main
```

Then update your feature branch from your local copy of main, and push it!

```sh
git checkout 325-add-japanese-translations
git rebase main
git push --force-with-lease origin 325-add-japanese-translations
```

Finally, go to GitHub and [make a Pull Request](https://github.com/MorningMores/develop/compare)

### Keeping your Pull Request updated

If a maintainer asks you to "rebase" your PR, they're saying that a lot of code has changed, and that you need to update your branch so it's easier to merge.

To learn more about rebasing and merging, check out this guide on [syncing a fork](https://help.github.com/articles/syncing-a-fork).

## How to Contribute

We'd love to accept your patches and contributions to this project. There are just a few small guidelines you need to follow.

### Contributor License Agreement (CLA)

Contributions to this project must be accompanied by a Contributor License
Agreement. You (or your employer) retain the copyright to your contribution;
this simply gives us permission to use and redistribute your contributions as
part of the project. Head over to <https://cla.developers.google.com/> to see
your current agreements on file or to sign a new one.

You generally only need to submit a CLA once, so if you've already submitted one
(even if it was for a different project), you probably don't need to do it
again.

### Code reviews

All submissions, including submissions by project members, require review. We
use GitHub pull requests for this purpose. Consult
[GitHub Help](https://help.github.com/articles/about-pull-requests/) for more
information on using pull requests.

### Community Guidelines

This project follows
[Google's Open Source Community Guidelines](https://opensource.google/conduct/).

1. Run tests:
   ```bash
   ./mvnw test
   ```

### Frontend Development (Nuxt 4)

1. Navigate to frontend directory:
   ```bash
   cd frontend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Run development server:
   ```bash
   npm run dev
   ```

4. Run tests:
   ```bash
   npm test
   ```

## 🔄 Pull Request Process

1. **Update your fork** with the latest upstream changes:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Ensure all tests pass**:
   - Backend: `mvn test`
   - Frontend: `npm test`
   - E2E: `npm run test:e2e`

3. **Update documentation** if you're adding new features

4. **Create a Pull Request** with a clear title and description:
   - Link related issues
   - Describe what changes you made
   - Include screenshots for UI changes
   - List any breaking changes

5. **Wait for review**:
   - Address any feedback
   - Keep your PR up to date with main branch

## 📐 Coding Standards

### Backend (Java/Spring Boot)

- Follow [Google Java Style Guide](https://google.github.io/styleguide/javaguide.html)
- Use meaningful variable and method names
- Add JavaDoc comments for public methods
- Keep methods small and focused
- Use Spring Boot best practices

### Frontend (TypeScript/Vue)

- Follow [Vue.js Style Guide](https://vuejs.org/style-guide/)
- Use TypeScript for type safety
- Use Composition API over Options API
- Keep components small and reusable
- Use meaningful component names

### General Guidelines

- Write self-documenting code
- Add comments for complex logic
- Follow DRY (Don't Repeat Yourself) principle
- Use consistent naming conventions
- Keep files under 300 lines when possible

## 🧪 Testing Guidelines

### Required Tests

- **Unit Tests**: For all business logic
- **Integration Tests**: For API endpoints
- **E2E Tests**: For critical user flows

### Test Coverage Requirements

- Backend: Minimum 80% line coverage
- Frontend: Minimum 80% line coverage
- All new features must include tests

### Running Tests

```bash
# Backend tests with coverage
cd backend
mvn clean test jacoco:report

# Frontend tests with coverage
cd frontend
npm test -- --coverage

# E2E tests
npm run test:e2e
```

## 📝 Commit Message Guidelines

We follow [Conventional Commits](https://www.conventionalcommits.org/):

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Code style changes (formatting, etc.)
- **refactor**: Code refactoring
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **chore**: Maintenance tasks

### Examples

```
feat(auth): add JWT token refresh functionality

Implemented automatic token refresh when access token expires.
Tokens are refreshed 5 minutes before expiration.

Closes #123
```

```
fix(booking): resolve double booking issue

Fixed race condition in booking creation that allowed
double bookings for the same seat.

Fixes #456
```

## 🐛 Bug Reports

When filing a bug report, please include:

1. **Description**: Clear description of the issue
2. **Steps to Reproduce**: Detailed steps to reproduce the bug
3. **Expected Behavior**: What you expected to happen
4. **Actual Behavior**: What actually happened
5. **Environment**:
   - OS: (e.g., macOS 14.0)
   - Browser: (e.g., Chrome 120)
   - Backend Version: (e.g., Spring Boot 3.5.0)
   - Frontend Version: (e.g., Nuxt 4.x)
6. **Screenshots**: If applicable
7. **Logs**: Relevant error logs

## 💡 Feature Requests

When suggesting a feature:

1. **Use Case**: Describe the problem you're trying to solve
2. **Proposed Solution**: Your suggested approach
3. **Alternatives**: Other solutions you've considered
4. **Additional Context**: Any other relevant information

## 📞 Questions?

- Check the [documentation](docs/README.md)
- Open a [GitHub Discussion](https://github.com/MorningMores/develop/discussions)
- Join our community chat (if applicable)

## 📄 License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

Thank you for contributing! 🎉
