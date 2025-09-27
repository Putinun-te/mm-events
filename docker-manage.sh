#!/bin/bash

# Docker management script for Spring Boot application

set -e

case "$1" in
    "build")
        echo "Building Spring Boot application with Docker..."
        docker-compose build --no-cache
        ;;
    "up")
        echo "Starting application with Docker Compose..."
        docker-compose up -d
        echo "Application starting... Check logs with: docker-compose logs -f"
        ;;
    "down")
        echo "Stopping application..."
        docker-compose down
        ;;
    "restart")
        echo "Restarting application..."
        docker-compose down
        docker-compose up -d
        ;;
    "logs")
        echo "Showing application logs..."
        docker-compose logs -f backend
        ;;
    "logs-all")
        echo "Showing all service logs..."
        docker-compose logs -f
        ;;
    "status")
        echo "Service status:"
        docker-compose ps
        ;;
    "clean")
        echo "Cleaning up Docker resources..."
        docker-compose down -v
        docker system prune -f
        ;;
    "rebuild")
        echo "Rebuilding and restarting..."
        docker-compose down
        docker-compose build --no-cache
        docker-compose up -d
        ;;
    "health")
        echo "Checking application health..."
        curl -f http://localhost:8080/actuator/health || echo "Application not healthy"
        ;;
    *)
        echo "Usage: $0 {build|up|down|restart|logs|logs-all|status|clean|rebuild|health}"
        echo ""
        echo "Commands:"
        echo "  build     - Build the Docker images"
        echo "  up        - Start all services"
        echo "  down      - Stop all services"
        echo "  restart   - Restart all services"
        echo "  logs      - Show backend logs"
        echo "  logs-all  - Show all service logs"
        echo "  status    - Show service status"
        echo "  clean     - Clean up Docker resources"
        echo "  rebuild   - Rebuild and restart everything"
        echo "  health    - Check application health"
        exit 1
        ;;
esac
