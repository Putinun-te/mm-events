#!/bin/bash
# Run the backend test suite inside Docker (no local JDK or Maven needed).
#
# Uses the "backend-tests" service of docker-compose.yml, which runs the same
# commands as CI (./mvnw test, then ./mvnw verify -DskipUTs=true). Testcontainers
# starts MySQL through the host's Docker socket.
set -euo pipefail

if ! docker info > /dev/null 2>&1; then
    echo "Docker is not running. Please start Docker and try again." >&2
    exit 1
fi

cd "$(dirname "$0")/.."
docker compose --profile tests run --rm backend-tests

echo
echo "Reports: main_backend/target/surefire-reports, main_backend/target/failsafe-reports,"
echo "         main_backend/target/site/jacoco/index.html"
