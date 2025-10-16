#!/bin/bash

# Concert Backend Test Runner
# This script runs various test scenarios for the Spring Boot backend

echo "🎯 Concert Backend Test Runner"
echo "==============================="

# Function to check if Maven is installed
check_maven() {
    if ! command -v mvn &> /dev/null; then
        echo "❌ Maven is not installed. Please install Maven to run tests."
        exit 1
    fi
    echo "✅ Maven found: $(mvn --version | head -n 1)"
}

# Function to run all tests
run_all_tests() {
    echo "🧪 Running all tests..."
    mvn clean test
    
    if [ $? -eq 0 ]; then
        echo "✅ All tests passed!"
    else
        echo "❌ Some tests failed!"
        return 1
    fi
}

# Function to run unit tests only
run_unit_tests() {
    echo "🔬 Running unit tests..."
    mvn test -Dtest="**/model/**/*Test,**/dto/**/*Test,**/service/**/*Test,**/controller/**/*Test,**/repository/**/*Test"
}

# Function to run integration tests only
run_integration_tests() {
    echo "🔗 Running integration tests..."
    mvn test -Dtest="**/integration/**/*Test"
}

# Function to run tests with coverage
run_tests_with_coverage() {
    echo "📊 Running tests with coverage report..."
    mvn clean test jacoco:report
    
    if [ -f "target/site/jacoco/index.html" ]; then
        echo "✅ Coverage report generated at: target/site/jacoco/index.html"
    fi
}

# Function to run specific test class
run_specific_test() {
    if [ -z "$1" ]; then
        echo "❌ Please provide a test class name"
        echo "Usage: ./run-tests.sh specific AuthServiceTest"
        return 1
    fi
    
    echo "🎯 Running specific test: $1"
    mvn test -Dtest="**/*$1"
}

# Function to clean and compile
clean_and_compile() {
    echo "🧹 Cleaning and compiling project..."
    mvn clean compile test-compile
}

# Function to display help
show_help() {
    echo "Usage: ./run-tests.sh [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  all         Run all tests (default)"
    echo "  unit        Run unit tests only"
    echo "  integration Run integration tests only"
    echo "  coverage    Run tests with coverage report"
    echo "  specific    Run specific test class (requires class name)"
    echo "  clean       Clean and compile project"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./run-tests.sh all"
    echo "  ./run-tests.sh unit"
    echo "  ./run-tests.sh specific AuthServiceTest"
}

# Main script logic
main() {
    check_maven
    
    case "${1:-all}" in
        "all")
            run_all_tests
            ;;
        "unit")
            run_unit_tests
            ;;
        "integration")
            run_integration_tests
            ;;
        "coverage")
            run_tests_with_coverage
            ;;
        "specific")
            run_specific_test "$2"
            ;;
        "clean")
            clean_and_compile
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            echo "❌ Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
