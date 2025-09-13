#!/bin/bash

# Script to run Docker-based tests
echo "🐳 Starting Docker Integration Tests..."

# Ensure Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

echo "✅ Docker is running"

# Clean up any existing containers
echo "🧹 Cleaning up existing test containers..."
docker stop $(docker ps -a -q --filter "ancestor=mysql:8.0" --filter "name=testcontainers") 2>/dev/null || true
docker rm $(docker ps -a -q --filter "ancestor=mysql:8.0" --filter "name=testcontainers") 2>/dev/null || true

# Run Maven tests with Docker profile
echo "🚀 Running Docker integration tests..."
mvn test -Dspring.profiles.active=docker -Dtest="*Docker*Test"

echo "🏁 Docker tests completed!"
